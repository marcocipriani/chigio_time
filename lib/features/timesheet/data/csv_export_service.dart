import 'dart:convert' show utf8;
import 'dart:io';
import 'dart:typed_data' show Uint8List;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'csv_download_stub.dart' if (dart.library.html) 'csv_download_web.dart';
import '../domain/daily_timesheet.dart';
import '../domain/absence_kind.dart';

// Exported CSV formats:
//
// Simple (re-importable, same columns as import template):
//   data;tipo;entrata;uscita;nota;assenza_tipo;assenza_min;assenza_giorni;periodo_da;periodo_a
//   (le ultime 5 colonne sono valorizzate solo per workType == permesso/ferie con causale)
//
// Detailed (full data for analysis):
//   data;tipo;entrata;uscita;pausa_std_min;pausa_art9_min;pausa_pranzo_min;
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

  /// Downloads/saves the template CSV that users fill in for import.
  static Future<void> downloadTemplate() async {
    const content =
        'data;tipo;entrata;uscita;nota;assenza_tipo;assenza_min;assenza_giorni;periodo_da;periodo_a\n'
        '2026-01-02;presenza;09:00;17:36;Meeting di team;;;;;\n'
        '2026-01-03;smart_working;;;;;;;;\n'
        '2026-01-06;ferie;;;;;;;;\n'
        '2026-01-07;permesso;09:00;12:00;Visita medica;specialist_visit;180;;;\n';
    final bytes = Uint8List.fromList(utf8.encode(content));
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

  static String _buildSimple(List<DailyTimesheet> entries) {
    final buf = StringBuffer(
      'data;tipo;entrata;uscita;nota;'
      'assenza_tipo;assenza_min;assenza_giorni;periodo_da;periodo_a\n',
    );
    for (final e in entries) {
      final tipo = _tipoLabel(e.workType);
      final hasTime =
          e.workType == WorkType.presence || e.workType == WorkType.remote;
      final entrata = hasTime
          ? '${_p2(e.startTime.hour)}:${_p2(e.startTime.minute)}'
          : '';
      final uscita = hasTime
          ? '${_p2(e.endTime.hour)}:${_p2(e.endTime.minute)}'
          : '';
      buf.writeln(
        '${e.dateId}$_sep$tipo$_sep$entrata$_sep$uscita$_sep'
        '${e.sensitive ? "" : _sanitize(e.note)}$_sep'
        '${e.sensitive ? AbsenceKind.sensitiveLeave : (e.absenceKind ?? "")}$_sep'
        '${e.absenceMins > 0 ? e.absenceMins : ""}$_sep'
        '${e.absenceDays > 0 ? e.absenceDays : ""}$_sep'
        '${e.sensitive ? "" : (e.periodStart ?? "")}$_sep'
        '${e.sensitive ? "" : (e.periodEnd ?? "")}',
      );
    }
    return buf.toString();
  }

  static String _buildDetailed(
    List<DailyTimesheet> entries,
    int mealThresholdMins,
  ) {
    final buf = StringBuffer(
      'data;tipo;entrata;uscita;'
      'pausa_std_min;pausa_art9_min;pausa_pranzo_min;'
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
    } catch (e) {
      debugPrint('[csv_export] share failed: $e');
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
