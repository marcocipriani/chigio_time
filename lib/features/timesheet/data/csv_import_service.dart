import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../domain/daily_timesheet.dart';
import '../domain/day_segment.dart';
import '../domain/absence_consumption.dart';
import '../domain/absence_kind.dart';
import '../../../core/utils/date_utils.dart';

// CSV a segmenti (ADR-0018), colonne separate da `;`:
//   data;segmento;da;a;minuti;causale;periodo_da;periodo_a;nota
//
// Piu' righe per giornata. Segmenti orari: work, leave, lunch, pause,
// banca_ore. Righe di giornata intera: ferie, smart_working, permesso,
// permesso_gg. `minuti` porta la durata quando da/a mancano, in H:MM o in
// minuti interi. `periodo_da`/`periodo_a` valgono solo sulle righe di
// giornata intera con unita' `period` (assenza multi-giorno). La nota e' di
// giornata: vale la prima non vuota.

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

  /// Causale come scritta nel file, anche se non riconosciuta: una causale
  /// ignota su un segmento `leave` deve scartare la giornata come una
  /// riconosciuta ma non ammessa, altrimenti un errore di battitura basta ad
  /// aggirare la restrizione e a far coprire l'orario dovuto.
  final String? kind;
  final String? periodFrom;
  final String? periodTo;
  final String note;

  const _Row(
    this.line,
    this.segment,
    this.from,
    this.to,
    this.mins,
    this.kind,
    this.periodFrom,
    this.periodTo,
    this.note,
  );

  /// Causale da scrivere sul documento: solo se e' della tassonomia.
  String? get validKind => AbsenceKind.labels.containsKey(kind) ? kind : null;
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
    return _parse(
      utf8.decode(bytes, allowMalformed: true),
      standardDailyMins: standardDailyMins,
    );
  }

  static CsvImportResult parse(String text, {int standardDailyMins = 456}) =>
      _parse(text, standardDailyMins: standardDailyMins);

  static CsvImportResult _parse(String text, {required int standardDailyMins}) {
    final errors = <String>[];
    final rowsByDate = <String, List<_Row>>{};
    final order = <String>[];

    final lines = text.split('\n').map((l) => l.trim()).toList();
    for (final (i, line) in lines.indexed) {
      if (line.isEmpty) continue;
      if (i == 0 && line.toLowerCase().startsWith('data;')) continue;

      final parts = line.split(_sep);
      if (parts.length != 9) {
        errors.add(
          'Riga ${i + 1}: formato non valido '
          '(richieste 9 colonne, trovate ${parts.length})',
        );
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
      if (from != null) {
        final f = _parseTime(dateId, from);
        final t = _parseTime(dateId, to!);
        if (f == null || t == null) {
          errors.add('Riga ${i + 1}: orario non valido ("$from" / "$to")');
          continue;
        }
        // Un intervallo rovesciato o nullo passava, e la giornata finiva
        // salvata come segnaposto 09:00-09:00 con netto 0 sopra quella buona
        // (l'import scrive con fullOverwrite). Stessa regola dell'editor.
        if (!t.isAfter(f)) {
          errors.add('Riga ${i + 1}: intervallo rovesciato ("$from" / "$to")');
          continue;
        }
      }

      final kindRaw = at(5);
      final kind = kindRaw.isEmpty ? null : kindRaw;
      if (kind != null && !AbsenceKind.labels.containsKey(kind)) {
        errors.add('Riga ${i + 1}: causale non riconosciuta ("$kindRaw")');
      }

      final periodFrom = at(6).isEmpty ? null : at(6);
      final periodTo = at(7).isEmpty ? null : at(7);
      if ((periodFrom == null) != (periodTo == null) ||
          (periodFrom != null &&
              (!_validDateId(periodFrom) || !_validDateId(periodTo!)))) {
        errors.add('Riga ${i + 1}: periodo non valido');
        continue;
      }

      rowsByDate
          .putIfAbsent(dateId, () {
            order.add(dateId);
            return <_Row>[];
          })
          .add(
            _Row(
              i + 1,
              segment,
              from,
              to,
              _parseMins(at(4)),
              kind,
              periodFrom,
              periodTo,
              at(8),
            ),
          );
    }

    final entries = <DailyTimesheet>[];
    for (final dateId in order) {
      final entry = _buildDay(
        dateId,
        rowsByDate[dateId]!,
        errors,
        standardDailyMins: standardDailyMins,
      );
      if (entry != null) entries.add(entry);
    }
    return CsvImportResult(entries: entries, errors: errors);
  }

  static DailyTimesheet? _buildDay(
    String dateId,
    List<_Row> rows,
    List<String> errors, {
    required int standardDailyMins,
  }) {
    final note = rows
        .map((r) => r.note)
        .firstWhere((n) => n.isNotEmpty, orElse: () => '');

    final dayRow = rows.where((r) => _fullDay.contains(r.segment)).toList();
    if (dayRow.isNotEmpty) {
      if (rows.length > dayRow.length) {
        errors.add(
          'Riga ${dayRow.first.line}: $dateId mescola giornata intera e segmenti orari',
        );
        return null;
      }
      return _fullDayEntry(dateId, dayRow.first, note);
    }

    final segments = <DaySegment>[];
    for (final r in rows) {
      // Un segmento e' una frazione di giornata: ammette le stesse causali
      // dell'editor, quelle a plafond orario, piu' la maschera
      // `sensitive_leave` che l'export scrive sulle giornate riservate. Un
      // `leave;strike` coprirebbe l'orario dovuto, l'opposto della griglia di
      // ADR-0018, quindi la giornata intera viene scartata invece di
      // importarla sbagliata. Una causale ignota fa lo stesso: segnalarla e
      // lasciar passare la giornata rendeva la restrizione aggirabile con un
      // errore di battitura.
      if (r.segment == DaySegment.leave &&
          r.kind != null &&
          !AbsencePlafonds.isImportableLeaveKind(r.kind)) {
        errors.add(
          'Riga ${r.line}: $dateId — causale non ammessa su un permesso '
          'orario ("${r.kind}")',
        );
        return null;
      }
      segments.add(
        DaySegment(
          type: r.segment,
          start: r.from == null ? null : _parseTime(dateId, r.from!),
          end: r.to == null ? null : _parseTime(dateId, r.to!),
          mins: r.from == null ? r.mins : 0,
          absenceKind: r.validKind,
        ),
      );
    }
    segments.sort((a, b) {
      if (a.start == null) return 1;
      if (b.start == null) return -1;
      return a.start!.compareTo(b.start!);
    });

    // ADR-0018: la stessa regola vale per l'import e per la timeline, quindi
    // vive nel domain e qui si aggiunge solo il contesto della riga.
    final invalid = DaySegment.validationError(segments);
    if (invalid != null) {
      errors.add('Riga ${rows.first.line}: $dateId — $invalid');
      return null;
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
      // La maschera sulla causale di un segmento dichiara la giornata
      // riservata, come su una riga di giornata intera: senza, un reimport
      // riesporrebbe in viste social una giornata che l'utente ha nascosto.
      sensitive: segments.any(
        (s) => s.absenceKind == AbsenceKind.sensitiveLeave,
      ),
      segments: segments,
    ).recomputedFromSegments(stdMins: standardDailyMins);
  }

  static DailyTimesheet _fullDayEntry(String dateId, _Row row, String note) {
    final isHoliday = row.segment == 'ferie';
    final isRemote = row.segment == 'smart_working';
    // Le due colonne del periodo, valorizzate, dichiarano l'unita': l'assenza
    // multi-giorno non ha ne' minuti ne' giornate, solo le due date.
    final isPeriod = !isRemote && row.periodFrom != null;
    final daily = !isPeriod && (row.segment == 'permesso_gg' || isHoliday);
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
      absenceKind: row.validKind,
      absenceUnit: isRemote
          ? null
          : (isPeriod
                ? AbsenceUnit.period
                : (daily ? AbsenceUnit.daily : AbsenceUnit.hourly)),
      absenceMins: daily || isPeriod ? 0 : row.mins,
      absenceDays: daily ? 1 : 0,
      periodStart: isPeriod ? row.periodFrom : null,
      periodEnd: isPeriod ? row.periodTo : null,
      quotaYear: isRemote ? null : int.tryParse(dateId.split('-').first),
      // Due flag che il formato non trasporta ma che la causale implica: la
      // stessa regola dell'editor manuale per il comporto, e la causale
      // mascherata che l'export scrive al posto di quella vera.
      countsAsSicknessPeriod:
          row.validKind == AbsenceKind.sickness ||
          row.validKind == AbsenceKind.workInjury,
      sensitive: row.validKind == AbsenceKind.sensitiveLeave,
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
