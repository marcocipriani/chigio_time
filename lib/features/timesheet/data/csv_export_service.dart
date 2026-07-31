import 'dart:convert' show utf8;
import 'dart:io';
import 'dart:typed_data' show Uint8List;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'csv_download_stub.dart' if (dart.library.html) 'csv_download_web.dart';
import '../domain/daily_timesheet.dart';
import '../domain/absence_kind.dart';
import '../../../core/logging/app_logger.dart';

// Exported CSV formats:
//
// Simple (re-importable, formato a segmenti — ADR-0018, stesse colonne lette
// da CsvImportService.parse):
//   data;segmento;da;a;minuti;causale;periodo_da;periodo_a;nota
//   Una riga per segmento orario (work/leave/lunch/pause/banca_ore) o una
//   riga sola per le giornate intere (ferie/smart_working/permesso/
//   permesso_gg). `periodo_da`/`periodo_a` solo sulle giornate con unita'
//   `period`. La nota e' di giornata: vale la prima non vuota fra le
//   righe del giorno.
//
// Detailed (full data for analysis):
//   data;tipo;entrata;uscita;pausa_std_min;pausa_permesso_min;pausa_pranzo_min;
//   netto_min;netto_hhmm;extra_min;extra_hhmm;sbo_min;sli_min;buono_pasto;nota

class CsvExportService {
  static const _sep = ';';

  // ── Public API ──────────────────────────────────────────────────────────

  /// Exports two files: re-importable simple CSV + full detailed CSV.
  static Future<void> exportBoth({
    required List<DailyTimesheet> entries,
    required String fileNameBase,
    int mealThresholdMins = 380,
  }) async {
    if (entries.isEmpty) return;
    final sorted = [...entries]..sort((a, b) => a.dateId.compareTo(b.dateId));
    await _shareFiles([
      (_buildSimple(sorted), '${fileNameBase}_semplice.csv'),
      (
        _buildDetailed(sorted, mealThresholdMins),
        '${fileNameBase}_completo.csv',
      ),
    ]);
  }

  static const _header = 'data;segmento;da;a;minuti;causale;'
      'periodo_da;periodo_a;nota';

  static const _template =
      '$_header\n'
      '2026-01-02;work;09:00;13:00;;;;;Giornata con permesso\n'
      '2026-01-02;leave;13:00;14:00;;specialist_visit;;;\n'
      '2026-01-02;work;14:00;17:36;;;;;\n'
      '2026-01-03;smart_working;;;;;;;\n'
      '2026-01-06;ferie;;;;;;;\n'
      '2026-01-07;permesso_gg;;;;personal_family_hourly;;;\n'
      '2026-03-02;permesso_gg;;;;sickness;2026-03-02;2026-03-11;Malattia\n';

  /// Downloads/saves the template CSV that users fill in for import.
  static Future<void> downloadTemplate() async {
    final bytes = Uint8List.fromList(utf8.encode(_template));
    const fileName = 'chigio_template_import.csv';
    // file_picker non implementa saveFile() su web — lì il download forza
    // direttamente il browser (vedi csv_download_web.dart), bypassando lo
    // share sheet che su alcuni browser/OS non offre "Salva file".
    if (kIsWeb) {
      triggerBrowserDownload(bytes, fileName, 'text/csv');
      return;
    }
    await FilePicker.saveFile(
      dialogTitle: 'Salva template CSV',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['csv'],
      bytes: bytes,
    );
  }

  // ── CSV builders ────────────────────────────────────────────────────────
  //
  // Entry-point pubblici per i test: `exportBoth` passa dallo share sheet e
  // dal filesystem, quindi il formato si verifica sui builder (stessa scelta
  // fatta da `CsvImportService.parse`). Gli entry-point NON riordinano: è
  // `exportBoth` a ordinare per `dateId`.

  @visibleForTesting
  static String get templateCsv => _template;

  @visibleForTesting
  static String buildSimpleCsv(List<DailyTimesheet> entries) =>
      _buildSimple(entries);

  @visibleForTesting
  static String buildDetailedCsv(
    List<DailyTimesheet> entries, {
    int mealThresholdMins = 380,
  }) => _buildDetailed(entries, mealThresholdMins);

  /// Una riga del formato semplice. Le colonne assenti restano vuote: e'
  /// l'unico punto che conosce l'ordine e il numero delle colonne.
  static String _row(
    String dateId,
    String segment, {
    String from = '',
    String to = '',
    String mins = '',
    String kind = '',
    String periodFrom = '',
    String periodTo = '',
    String note = '',
  }) => [
    dateId,
    segment,
    from,
    to,
    mins,
    kind,
    periodFrom,
    periodTo,
    note,
  ].join(_sep);

  static String _buildSimple(List<DailyTimesheet> entries) {
    final buf = StringBuffer('$_header\n');
    for (final e in entries) {
      final note = e.sensitive ? '' : _sanitize(e.note);
      final kind = e.sensitive
          ? AbsenceKind.sensitiveLeave
          : (e.absenceKind ?? '');

      if (e.workType == WorkType.remote) {
        buf.writeln(_row(e.dateId, 'smart_working', note: note));
        continue;
      }
      if (e.workType == WorkType.holiday) {
        buf.writeln(_row(e.dateId, 'ferie', kind: kind, note: note));
        continue;
      }
      if (e.workType == WorkType.leave) {
        // L'assenza multi-giorno viaggia sulle due colonne del periodo, e
        // usa la riga di giornata convenzionale come le altre `_gg`: senza,
        // il reimport azzerava unita', minuti, giornate e date.
        final period = e.absenceUnit == AbsenceUnit.period;
        final daily = e.absenceUnit == AbsenceUnit.daily;
        buf.writeln(
          _row(
            e.dateId,
            daily || period ? 'permesso_gg' : 'permesso',
            mins: daily || period || e.absenceMins == 0
                ? ''
                : '${e.absenceMins}',
            kind: kind,
            periodFrom: period ? (e.periodStart ?? '') : '',
            periodTo: period ? (e.periodEnd ?? '') : '',
            note: note,
          ),
        );
        continue;
      }

      // Presenza: una riga per segmento, la nota sulla prima. Un documento
      // arrivato con segments vuota (cache offline pre-migrazione, vedi
      // TimesheetRepository._fromRow, che non deriva i segmenti come fa
      // fromMap) non deve sparire dall'export: fallback a una riga work
      // sola da startTime/endTime, come nel formato precedente.
      if (e.segments.isEmpty) {
        buf.writeln(
          _row(
            e.dateId,
            'work',
            from: '${_p2(e.startTime.hour)}:${_p2(e.startTime.minute)}',
            to: '${_p2(e.endTime.hour)}:${_p2(e.endTime.minute)}',
            note: note,
          ),
        );
        continue;
      }

      var first = true;
      for (final s in e.segments) {
        buf.writeln(
          _row(
            e.dateId,
            s.type,
            from: s.start == null
                ? ''
                : '${_p2(s.start!.hour)}:${_p2(s.start!.minute)}',
            to: s.end == null
                ? ''
                : '${_p2(s.end!.hour)}:${_p2(s.end!.minute)}',
            mins: s.start == null && s.mins > 0 ? '${s.mins}' : '',
            kind: s.absenceKind == null
                ? ''
                : (e.sensitive ? AbsenceKind.sensitiveLeave : s.absenceKind!),
            note: first ? note : '',
          ),
        );
        first = false;
      }
    }
    return buf.toString();
  }

  static String _buildDetailed(
    List<DailyTimesheet> entries,
    int mealThresholdMins,
  ) {
    final buf = StringBuffer(
      'data;tipo;entrata;uscita;'
      'pausa_std_min;pausa_permesso_min;pausa_pranzo_min;'
      'netto_min;netto_hhmm;extra_min;extra_hhmm;'
      'sbo_min;sli_min;buono_pasto;'
      'assenza_tipo;assenza_min;assenza_giorni;periodo_da;periodo_a;riservata;nota\n',
    );
    for (final e in entries) {
      final extraPos = e.extraMins > 0 ? e.extraMins : 0;
      buf.writeln(
        '${e.dateId}$_sep'
        '${_tipoLabel(e.workType)}$_sep'
        '${_p2(e.startTime.hour)}:${_p2(e.startTime.minute)}$_sep'
        '${_p2(e.endTime.hour)}:${_p2(e.endTime.minute)}$_sep'
        '${e.standardPauseMins}$_sep'
        '${e.leavePauseMins}$_sep'
        '${e.lunchPauseMins}$_sep'
        '${e.netWorkedMins}$_sep'
        '${_fmtHHMM(e.netWorkedMins)}$_sep'
        '$extraPos$_sep'
        '${extraPos > 0 ? _fmtHHMM(extraPos) : ""}$_sep'
        '${e.sboMins}$_sep'
        '${e.sliMins}$_sep'
        '${e.netWorkedMins >= mealThresholdMins ? 1 : 0}$_sep'
        '${e.sensitive ? AbsenceKind.sensitiveLeave : (e.absenceKind ?? "")}$_sep'
        '${e.absenceMins > 0 ? e.absenceMins : ""}$_sep'
        '${e.absenceDays > 0 ? e.absenceDays : ""}$_sep'
        '${e.sensitive ? "" : (e.periodStart ?? "")}$_sep'
        '${e.sensitive ? "" : (e.periodEnd ?? "")}$_sep'
        '${e.sensitive ? 1 : 0}$_sep'
        '${e.sensitive ? "" : _sanitize(e.note)}',
      );
    }
    return buf.toString();
  }

  // ── Share / download ────────────────────────────────────────────────────

  static Future<void> _shareFiles(
    List<(String content, String name)> files,
  ) async {
    final xFiles = <XFile>[];

    if (kIsWeb) {
      // On web, build XFile from bytes (no filesystem access).
      for (final (content, name) in files) {
        xFiles.add(
          XFile.fromData(
            Uint8List.fromList(utf8.encode(content)),
            name: name,
            mimeType: 'text/csv',
          ),
        );
      }
    } else {
      final tmp = await getTemporaryDirectory();
      for (final (content, name) in files) {
        final file = File('${tmp.path}/$name');
        await file.writeAsString(content, flush: true);
        xFiles.add(XFile(file.path, mimeType: 'text/csv', name: name));
      }
    }

    try {
      await SharePlus.instance.share(
        ShareParams(files: xFiles, subject: 'Chigio Time — Export CSV'),
      );
    } catch (e, st) {
      AppLog.error('csv_export', 'share failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  static String _tipoLabel(String? wt) => switch (wt) {
    WorkType.remote => 'smart_working',
    WorkType.leave => 'permesso',
    WorkType.holiday => 'ferie',
    _ => 'presenza',
  };

  static String _sanitize(String? s) => (s ?? '')
      .replaceAll(_sep, ',')
      .replaceAll('\n', ' ')
      .replaceAll('\r', '');

  static String _p2(int n) => n.toString().padLeft(2, '0');

  static String _fmtHHMM(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    return '${_p2(h)}:${_p2(m)}';
  }
}
