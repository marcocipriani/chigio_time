import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../domain/daily_timesheet.dart';
import '../domain/absence_kind.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';

// CSV template columns (semicolon-separated):
// data;tipo;entrata;uscita;nota;assenza_tipo;assenza_min;assenza_giorni;periodo_da;periodo_a
// 2026-05-15;presenza;09:00;17:36;Meeting con team;;;;;
// 2026-05-16;smart_working;;;;;;;;
// 2026-05-17;ferie;;;;;;;;
// 2026-05-18;permesso;09:00;12:00;Visita medica;specialist_visit;180;;;
//
// Le colonne assenza_* sono opzionali e valide solo per tipo permesso/ferie:
// assenza_tipo deve essere uno dei valori AbsenceKind (es. specialist_visit, sickness, ...).

class CsvImportResult {
  final List<DailyTimesheet> entries;
  final List<String> errors;

  const CsvImportResult({required this.entries, required this.errors});

  bool get hasErrors => errors.isNotEmpty;
}

class CsvImportService {
  static const _sep = ';';

  static Future<CsvImportResult?> pickAndParse({
    int standardDailyMins = 456,
  }) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
    );
    if (result == null || result.files.isEmpty) return null;

    // file_picker 12: readAsBytes() sostituisce withData/bytes.
    final bytes = await result.files.first.readAsBytes();

    final text = utf8.decode(bytes, allowMalformed: true);
    return _parse(text, standardDailyMins: standardDailyMins);
  }

  /// Public entry point for the parser — usato dai test (lo `_parse` privato
  /// non è accessibile fuori dalla libreria; `pickAndParse` richiede il picker).
  static CsvImportResult parse(String text, {int standardDailyMins = 456}) =>
      _parse(text, standardDailyMins: standardDailyMins);

  static CsvImportResult _parse(String text, {required int standardDailyMins}) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final entries = <DailyTimesheet>[];
    final errors = <String>[];

    for (final (i, line) in lines.indexed) {
      // Skip header
      if (i == 0 && line.toLowerCase().startsWith('data')) continue;

      final parts = line.split(_sep);
      if (parts.length < 2) {
        errors.add('Riga ${i + 1}: formato non valido ("$line")');
        continue;
      }

      final dateId = parts[0].trim();
      final rawType = parts[1].trim().toLowerCase();

      if (!_validDateId(dateId)) {
        errors.add('Riga ${i + 1}: data non valida ("$dateId")');
        continue;
      }

      final workType = _parseType(rawType);
      if (workType == null) {
        errors.add('Riga ${i + 1}: tipo non riconosciuto ("$rawType")');
        continue;
      }

      final note = parts.length > 4 ? parts[4].trim() : null;

      if (workType == WorkType.leave || workType == WorkType.holiday) {
        final absenceKindRaw = parts.length > 5 ? parts[5].trim() : '';
        final absenceKind =
            absenceKindRaw.isNotEmpty &&
                AbsenceKind.labels.containsKey(absenceKindRaw)
            ? absenceKindRaw
            : null;
        if (absenceKindRaw.isNotEmpty && absenceKind == null) {
          errors.add(
            'Riga ${i + 1}: causale assenza non riconosciuta ("$absenceKindRaw")',
          );
        }
        final absenceMins = parts.length > 6
            ? int.tryParse(parts[6].trim()) ?? 0
            : 0;
        final absenceDays = parts.length > 7
            ? double.tryParse(parts[7].trim()) ?? 0
            : 0.0;
        final periodStart = parts.length > 8 ? parts[8].trim() : '';
        final periodEnd = parts.length > 9 ? parts[9].trim() : '';

        entries.add(
          DailyTimesheet(
            dateId: dateId,
            startTime: _dateOnly(dateId, 9, 0),
            endTime: _dateOnly(dateId, 9, 0),
            standardPauseMins: 0,
            lunchPauseMins: 0,
            netWorkedMins: 0,
            extraMins: 0,
            workType: workType,
            note: note,
            absenceKind: absenceKind,
            absenceUnit: absenceKind == null
                ? null
                : (periodStart.isNotEmpty
                      ? AbsenceUnit.period
                      : (absenceDays > 0
                            ? AbsenceUnit.daily
                            : (absenceMins > 0 ? AbsenceUnit.hourly : null))),
            absenceMins: absenceMins,
            absenceDays: absenceDays,
            periodStart: periodStart.isNotEmpty ? periodStart : null,
            periodEnd: periodEnd.isNotEmpty ? periodEnd : null,
            quotaYear: absenceKind != null
                ? int.tryParse(dateId.split('-').first)
                : null,
          ),
        );
        continue;
      }

      if (workType == WorkType.remote) {
        // Remote/smart-working: orario dichiarato, non un timbro reale —
        // nessuna pausa pranzo si applica in nessun caso.
        final start = _dateOnly(dateId, 9, 0);
        final end = start.add(Duration(minutes: standardDailyMins));
        entries.add(
          DailyTimesheet(
            dateId: dateId,
            startTime: start,
            endTime: end,
            standardPauseMins: 0,
            lunchPauseMins: 0,
            netWorkedMins: standardDailyMins,
            extraMins: 0,
            workType: WorkType.remote,
            note: note,
          ),
        );
        continue;
      }

      // Presence: entrata + uscita required
      if (parts.length < 4) {
        errors.add('Riga ${i + 1}: orari entrata/uscita mancanti');
        continue;
      }

      final startTime = _parseTime(dateId, parts[2].trim());
      final endTime = _parseTime(dateId, parts[3].trim());
      if (startTime == null || endTime == null) {
        errors.add(
          'Riga ${i + 1}: orario non valido ("${parts[2]}" / "${parts[3]}")',
        );
        continue;
      }

      if (!endTime.isAfter(startTime)) {
        errors.add('Riga ${i + 1}: uscita deve essere dopo entrata');
        continue;
      }

      final elapsed = endTime.difference(startTime).inMinutes;
      // Nota esplicita vince sempre; altrimenti regola CCNL 3-zone in base
      // alle ore effettive (niente piu' default fisso 30/60min).
      final lunchMins =
          _parsePauseMins(note) ?? AppConstants.forcedLunchMins(elapsed);
      final sliMins = _parsePortaleMins(note, [
        'Maggior Presenza',
        'Indennità Art.9',
      ]);
      final sboMins = _parsePortaleMins(note, ['Banca Ore']);
      final netMins = (elapsed - lunchMins).clamp(0, 9999);
      final stdMins = standardDailyMins;
      // If portale sli+sbo data present, trust those; otherwise compute from timestamps
      final extraMins = (sliMins + sboMins > 0)
          ? sliMins + sboMins
          : (netMins - stdMins).clamp(0, 9999).toInt();
      final cleanNote = _cleanNote(note);

      entries.add(
        DailyTimesheet(
          dateId: dateId,
          startTime: startTime,
          endTime: endTime,
          standardPauseMins: 0,
          lunchPauseMins: lunchMins,
          netWorkedMins: netMins,
          extraMins: extraMins,
          sliMins: sliMins,
          sboMins: sboMins,
          workType: WorkType.presence,
          note: cleanNote,
        ),
      );
    }

    return CsvImportResult(entries: entries, errors: errors);
  }

  /// Parses "Pausa Pranzo dalle HH:MM alle HH:MM" → duration in minutes.
  static int? _parsePauseMins(String? note) {
    if (note == null) return null;
    final re = RegExp(
      r'Pausa \w+ dalle (\d{1,2}):(\d{2}) alle (\d{1,2}):(\d{2})',
    );
    final m = re.firstMatch(note);
    if (m == null) return null;
    final startM = int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
    final endM = int.parse(m.group(3)!) * 60 + int.parse(m.group(4)!);
    final diff = endM - startM;
    return diff > 0 ? diff : null;
  }

  /// Parses `H:MM <keyword>` from portale note text → minutes.
  /// Tries all [keywords] and returns the first match.
  static int _parsePortaleMins(String? note, List<String> keywords) {
    if (note == null) return 0;
    for (final kw in keywords) {
      final re = RegExp(r'(\d{1,2}):(\d{2})' + RegExp.escape(kw));
      final m = re.firstMatch(note);
      if (m != null) {
        return int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
      }
    }
    return 0;
  }

  /// Strips portale counter tokens (H:MM Keyword[...]) from the note,
  /// keeping only human-readable event descriptions.
  static String? _cleanNote(String? note) {
    if (note == null || note.isEmpty) return null;
    // Remove portale counters like "1:00Buono Pasto7:36ORE SMARTWORKING[...]"
    var cleaned = note
        .replaceAll(
          RegExp(r'\d{1,2}:\d{2}[A-ZÀÈÉÌÒÙ][^\|\n\[]*(?:\[\.\.\.\])?'),
          '',
        )
        .replaceAll(RegExp(r'\s*\|\s*Timbrature:.*'), '')
        .replaceAll('|', ' | ')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .replaceAll(RegExp(r'^\s*\|\s*|\s*\|\s*$'), '')
        .trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  static bool _validDateId(String s) {
    if (s.length != 10) return false;
    final d = DateTime.tryParse(s);
    // Dart normalizza le date impossibili (2026-02-31 → 2026-03-03): valida
    // solo se il round-trip restituisce la stessa stringa.
    return d != null && dateIdOf(d) == s;
  }

  static String? _parseType(String raw) => switch (raw) {
    'presenza' || 'presence' || 'p' => WorkType.presence,
    'smart_working' || 'sw' || 'remote' || 'remoto' => WorkType.remote,
    'ferie' || 'holiday' || 'f' => WorkType.holiday,
    'permesso' || 'leave' || 'l' => WorkType.leave,
    _ => null,
  };

  static DateTime _dateOnly(String dateId, int h, int m) {
    final p = dateId.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]), h, m);
  }

  static DateTime? _parseTime(String dateId, String time) {
    if (time.isEmpty) return null;
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    final dp = dateId.split('-');
    return DateTime(int.parse(dp[0]), int.parse(dp[1]), int.parse(dp[2]), h, m);
  }
}
