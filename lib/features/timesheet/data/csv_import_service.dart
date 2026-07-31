import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../domain/daily_timesheet.dart';
import '../domain/day_segment.dart';
import '../domain/absence_kind.dart';
import '../../../core/utils/date_utils.dart';

// CSV a segmenti (ADR-0018), colonne separate da `;`:
//   data;segmento;da;a;minuti;causale;nota
//
// Piu' righe per giornata. Segmenti orari: work, leave, lunch, pause,
// banca_ore. Righe di giornata intera: ferie, smart_working, permesso,
// permesso_gg. `minuti` porta la durata quando da/a mancano, in H:MM o in
// minuti interi. La nota e' di giornata: vale la prima non vuota.

class CsvImportResult {
  final List<DailyTimesheet> entries;
  final List<String> errors;

  const CsvImportResult({required this.entries, required this.errors});

  bool get hasErrors => errors.isNotEmpty;
}

/// Riga grezza del CSV, gia' validata nei tipi ma non ancora nel giorno.
class _Row {
  final int line;
  final String segment;
  final String? from;
  final String? to;
  final int mins;
  final String? kind;
  final String note;

  const _Row(this.line, this.segment, this.from, this.to, this.mins, this.kind,
      this.note);
}

class CsvImportService {
  static const _sep = ';';

  static const _hourly = {
    DaySegment.work,
    DaySegment.leave,
    DaySegment.lunch,
    DaySegment.pause,
    DaySegment.bancaOre,
  };
  static const _fullDay = {'ferie', 'smart_working', 'permesso', 'permesso_gg'};

  static Future<CsvImportResult?> pickAndParse({
    int standardDailyMins = 456,
  }) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
    );
    if (result == null || result.files.isEmpty) return null;
    final bytes = await result.files.first.readAsBytes();
    return _parse(utf8.decode(bytes, allowMalformed: true),
        standardDailyMins: standardDailyMins);
  }

  static CsvImportResult parse(String text, {int standardDailyMins = 456}) =>
      _parse(text, standardDailyMins: standardDailyMins);

  static CsvImportResult _parse(String text,
      {required int standardDailyMins}) {
    final errors = <String>[];
    final rowsByDate = <String, List<_Row>>{};
    final order = <String>[];

    final lines = text.split('\n').map((l) => l.trim()).toList();
    for (final (i, line) in lines.indexed) {
      if (line.isEmpty) continue;
      if (i == 0 && line.toLowerCase().startsWith('data;')) continue;

      final parts = line.split(_sep);
      if (parts.length < 2) {
        errors.add('Riga ${i + 1}: formato non valido ("$line")');
        continue;
      }
      String at(int n) => parts.length > n ? parts[n].trim() : '';

      final dateId = parts[0].trim();
      if (!_validDateId(dateId)) {
        errors.add('Riga ${i + 1}: data non valida ("$dateId")');
        continue;
      }

      final segment = at(1).toLowerCase();
      if (!_hourly.contains(segment) && !_fullDay.contains(segment)) {
        errors.add('Riga ${i + 1}: segmento non riconosciuto ("$segment")');
        continue;
      }

      final from = at(2).isEmpty ? null : at(2);
      final to = at(3).isEmpty ? null : at(3);
      if ((from == null) != (to == null)) {
        errors.add('Riga ${i + 1}: intervallo incompleto');
        continue;
      }
      if (from != null &&
          (_parseTime(dateId, from) == null || _parseTime(dateId, to!) == null)) {
        errors.add('Riga ${i + 1}: orario non valido ("$from" / "$to")');
        continue;
      }

      final kindRaw = at(5);
      String? kind;
      if (kindRaw.isNotEmpty) {
        if (AbsenceKind.labels.containsKey(kindRaw)) {
          kind = kindRaw;
        } else {
          errors.add('Riga ${i + 1}: causale non riconosciuta ("$kindRaw")');
        }
      }

      rowsByDate.putIfAbsent(dateId, () {
        order.add(dateId);
        return <_Row>[];
      }).add(_Row(i + 1, segment, from, to, _parseMins(at(4)), kind, at(6)));
    }

    final entries = <DailyTimesheet>[];
    for (final dateId in order) {
      final entry = _buildDay(dateId, rowsByDate[dateId]!, errors,
          standardDailyMins: standardDailyMins);
      if (entry != null) entries.add(entry);
    }
    return CsvImportResult(entries: entries, errors: errors);
  }

  static DailyTimesheet? _buildDay(String dateId, List<_Row> rows,
      List<String> errors, {required int standardDailyMins}) {
    final note = rows.map((r) => r.note).firstWhere((n) => n.isNotEmpty,
        orElse: () => '');

    final dayRow = rows.where((r) => _fullDay.contains(r.segment)).toList();
    if (dayRow.isNotEmpty) {
      if (rows.length > dayRow.length) {
        errors.add(
            'Riga ${dayRow.first.line}: $dateId mescola giornata intera e segmenti orari');
        return null;
      }
      return _fullDayEntry(dateId, dayRow.first, note);
    }

    final segments = <DaySegment>[];
    for (final r in rows) {
      segments.add(DaySegment(
        type: r.segment,
        start: r.from == null ? null : _parseTime(dateId, r.from!),
        end: r.to == null ? null : _parseTime(dateId, r.to!),
        mins: r.from == null ? r.mins : 0,
        absenceKind: r.kind,
      ));
    }
    segments.sort((a, b) {
      if (a.start == null) return 1;
      if (b.start == null) return -1;
      return a.start!.compareTo(b.start!);
    });

    if (!segments.any((s) => s.type == DaySegment.work)) {
      errors.add('Riga ${rows.first.line}: $dateId non ha segmenti di lavoro');
      return null;
    }

    // Un segmento (es. leave) puo' cadere interamente dentro lo span di un
    // altro (es. work): e' un'interruzione, non un conflitto. E' un errore
    // solo l'overlap "a cavallo", dove ne' l'uno ne' l'altro contiene il
    // secondo: il dato e' ambiguo su chi copra il tempo in comune.
    final positioned = segments.where((s) => s.start != null).toList();
    for (var i = 0; i < positioned.length; i++) {
      for (var j = i + 1; j < positioned.length; j++) {
        final a = positioned[i], b = positioned[j];
        final overlaps =
            a.start!.isBefore(b.end!) && b.start!.isBefore(a.end!);
        if (!overlaps) continue;
        final aContainsB =
            !a.start!.isAfter(b.start!) && !a.end!.isBefore(b.end!);
        final bContainsA =
            !b.start!.isAfter(a.start!) && !b.end!.isBefore(a.end!);
        if (!aContainsB && !bContainsA) {
          errors.add('Riga ${rows.first.line}: $dateId ha segmenti sovrapposti');
          return null;
        }
      }
    }

    return DailyTimesheet(
      dateId: dateId,
      startTime: _dateOnly(dateId, 9, 0),
      endTime: _dateOnly(dateId, 9, 0),
      standardPauseMins: 0,
      lunchPauseMins: 0,
      netWorkedMins: 0,
      extraMins: 0,
      workType: WorkType.presence,
      note: note.isEmpty ? null : note,
      segments: segments,
    ).recomputedFromSegments(stdMins: standardDailyMins);
  }

  static DailyTimesheet _fullDayEntry(String dateId, _Row row, String note) {
    final isHoliday = row.segment == 'ferie';
    final isRemote = row.segment == 'smart_working';
    final daily = row.segment == 'permesso_gg' || isHoliday;
    final workType = isRemote
        ? WorkType.remote
        : (isHoliday ? WorkType.holiday : WorkType.leave);

    return DailyTimesheet(
      dateId: dateId,
      startTime: _dateOnly(dateId, 9, 0),
      endTime: _dateOnly(dateId, 9, 0),
      standardPauseMins: 0,
      lunchPauseMins: 0,
      netWorkedMins: 0,
      extraMins: 0,
      workType: workType,
      note: note.isEmpty ? null : note,
      absenceKind: row.kind,
      absenceUnit: isRemote
          ? null
          : (daily ? AbsenceUnit.daily : AbsenceUnit.hourly),
      absenceMins: daily ? 0 : row.mins,
      absenceDays: daily ? 1 : 0,
      quotaYear: isRemote ? null : int.tryParse(dateId.split('-').first),
    );
  }

  /// Accetta "H:MM" oppure un numero di minuti. 0 se vuoto o illeggibile.
  static int _parseMins(String raw) {
    if (raw.isEmpty) return 0;
    if (!raw.contains(':')) return int.tryParse(raw) ?? 0;
    final parts = raw.split(':');
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return 0;
    return h * 60 + m;
  }

  static bool _validDateId(String s) {
    if (s.length != 10) return false;
    final d = DateTime.tryParse(s);
    return d != null && dateIdOf(d) == s;
  }

  static DateTime _dateOnly(String dateId, int h, int m) {
    final p = dateId.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]), h, m);
  }

  static DateTime? _parseTime(String dateId, String time) {
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h > 23 || m > 59) return null;
    final dp = dateId.split('-');
    return DateTime(int.parse(dp[0]), int.parse(dp[1]), int.parse(dp[2]), h, m);
  }
}
