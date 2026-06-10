import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/daily_timesheet.dart';
import '../../../core/constants/app_strings.dart';

class PdfExportService {
  // Font Unicode condiviso: i font core PDF (Helvetica) non coprono accenti
  // italiani (à/è/ì/ò/ù), simboli (€) o emoji — risultavano caratteri mancanti
  // o "tofu" nel PDF generato. Noto Sans copre il set Latin Extended.
  static pw.ThemeData? _theme;
  static pw.MemoryImage? _logo;

  static Future<pw.ThemeData> _loadTheme() async {
    final cached = _theme;
    if (cached != null) return cached;
    final theme = pw.ThemeData.withFont(
      base: await PdfGoogleFonts.notoSansRegular(),
      bold: await PdfGoogleFonts.notoSansBold(),
      italic: await PdfGoogleFonts.notoSansItalic(),
      boldItalic: await PdfGoogleFonts.notoSansBoldItalic(),
    );
    _theme = theme;
    return theme;
  }

  static Future<pw.MemoryImage?> _loadLogo() async {
    final cached = _logo;
    if (cached != null) return cached;
    try {
      final data = await rootBundle.load('assets/images/app_icon.png');
      final logo = pw.MemoryImage(data.buffer.asUint8List());
      _logo = logo;
      return logo;
    } catch (_) {
      return null;
    }
  }

  // Indicatore booleano disegnato a forma — evita di affidarsi alla copertura
  // glifo del font per simboli come '✓' (U+2713), che Noto Sans può non
  // renderizzare in modo coerente su tutte le piattaforme di stampa.
  static pw.Widget _checkMark({required bool active}) => pw.Container(
    width: 9,
    height: 9,
    decoration: pw.BoxDecoration(
      shape: pw.BoxShape.circle,
      color: active ? PdfColors.green700 : PdfColors.grey300,
    ),
  );

  // Generates and shares/prints a monthly timesheet PDF.
  static Future<void> exportMonth({
    required int year,
    required int month,
    required List<DailyTimesheet> entries,
    required String userName,
    required String administration,
    int mealThresholdMins = 380,
  }) async {
    final doc = pw.Document(theme: await _loadTheme());
    final logo = await _loadLogo();
    final monthName = AppStrings.months[month - 1];
    final title = AppStrings.pdfTitle(monthName, year);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logo != null) ...[
                  pw.ClipRRect(
                    horizontalRadius: 6,
                    verticalRadius: 6,
                    child: pw.Image(logo, width: 28, height: 28),
                  ),
                  pw.SizedBox(width: 8),
                ],
                pw.Text(
                  AppStrings.appName,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              administration,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.Text(
              userName,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.Divider(color: PdfColors.blue200, thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (ctx) => [
          _buildSummary(entries, month, year, mealThresholdMins),
          pw.SizedBox(height: 16),
          _buildTable(entries, month, year, mealThresholdMins),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'timesheet_${year}_${month.toString().padLeft(2, '0')}.pdf',
    );
  }

  static pw.Widget _buildSummary(
    List<DailyTimesheet> entries,
    int month,
    int year,
    int mealThresholdMins,
  ) {
    final totalNet = entries.fold<int>(0, (s, e) => s + e.netWorkedMins);
    final totalOT = entries.fold<int>(
      0,
      (s, e) => s + (e.extraMins > 0 ? e.extraMins : 0),
    );
    final totalMeal = entries
        .where((e) => e.netWorkedMins >= mealThresholdMins)
        .length;
    final presence = entries
        .where((e) => !e.isLeave && !e.isHoliday && e.netWorkedMins > 0)
        .length;

    return pw.Row(
      children: [
        _summaryChip(AppStrings.pdfSummaryPresenze, '$presence'),
        pw.SizedBox(width: 12),
        _summaryChip(AppStrings.pdfSummaryOreLavorate, _fmtMins(totalNet)),
        pw.SizedBox(width: 12),
        _summaryChip(AppStrings.pdfSummaryStraordinario, _fmtMins(totalOT)),
        pw.SizedBox(width: 12),
        _summaryChip(AppStrings.pdfSummaryBuoniPasto, '$totalMeal'),
      ],
    );
  }

  static pw.Widget _summaryChip(String label, String value) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: pw.BoxDecoration(
      color: PdfColors.blue50,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
      ],
    ),
  );

  static pw.Widget _buildTable(
    List<DailyTimesheet> entries,
    int month,
    int year,
    int mealThresholdMins,
  ) {
    const headers = [
      AppStrings.pdfColGiorno,
      AppStrings.pdfColTipo,
      AppStrings.pdfColEntrata,
      AppStrings.pdfColUscita,
      AppStrings.pdfColNetto,
      AppStrings.pdfColOt,
      AppStrings.pdfColBuono,
      AppStrings.pdfColNota,
    ];
    final sortedEntries = [...entries]
      ..sort((a, b) => a.dateId.compareTo(b.dateId));

    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
        bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      ),
      columnWidths: {
        0: const pw.FixedColumnWidth(55),
        1: const pw.FixedColumnWidth(60),
        2: const pw.FixedColumnWidth(45),
        3: const pw.FixedColumnWidth(45),
        4: const pw.FixedColumnWidth(40),
        5: const pw.FixedColumnWidth(35),
        6: const pw.FixedColumnWidth(40),
        7: const pw.FlexColumnWidth(),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue800),
          children: headers
              .map(
                (h) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 5,
                  ),
                  child: pw.Text(
                    h,
                    maxLines: 1,
                    softWrap: false,
                    overflow: pw.TextOverflow.clip,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        // Data rows — un bordo superiore più marcato segna l'inizio di una
        // nuova settimana (lunedì), separando visivamente i blocchi.
        ...sortedEntries.indexed.map((indexed) {
          final (i, e) = indexed;
          final date = DateTime.tryParse(e.dateId) ?? DateTime(year, month, 1);
          final day = date.day;
          final dayName = AppStrings.weekdaysShort[date.weekday - 1];
          final isWeekend = date.weekday >= 6;
          final bg = isWeekend ? PdfColors.grey100 : PdfColors.white;
          final hasMeal = e.netWorkedMins >= mealThresholdMins;
          final typeLabel = e.isRemote
              ? AppStrings.pdfTypeRemote
              : e.isLeave
              ? AppStrings.pdfTypeLeave
              : e.isHoliday
              ? AppStrings.pdfTypeHoliday
              : AppStrings.pdfTypePresence;
          final isWeekStart = i > 0 && date.weekday == DateTime.monday;

          final cells = [
            _cell('$day $dayName'),
            _cell(typeLabel),
            _cell(e.isHoliday || (e.isLeave && e.startTime.hour == 0 && e.startTime.minute == 0) ? '—' : _fmtTime(e.startTime)),
            _cell(e.isHoliday || (e.isLeave && e.endTime.hour == 0 && e.endTime.minute == 0) ? '—' : _fmtTime(e.endTime)),
            _cell(_fmtMins(e.netWorkedMins)),
            _cell(e.extraMins > 0 ? '+${_fmtMins(e.extraMins)}' : '—'),
            _mealCell(hasMeal),
            _cell(e.sensitive ? '—' : (e.note ?? ''), maxLines: 1),
          ];

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: isWeekStart
                ? cells
                      .map(
                        (c) => pw.Container(
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              top: pw.BorderSide(
                                color: PdfColors.blue200,
                                width: 1.2,
                              ),
                            ),
                          ),
                          child: c,
                        ),
                      )
                      .toList()
                : cells,
          );
        }),
      ],
    );
  }

  static pw.Widget _cell(String text, {PdfColor? color, int maxLines = 2}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: pw.Text(
          text,
          maxLines: maxLines,
          overflow: pw.TextOverflow.clip,
          style: pw.TextStyle(fontSize: 8, color: color ?? PdfColors.grey800),
        ),
      );

  static pw.Widget _mealCell(bool active) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    child: pw.Align(
      alignment: pw.Alignment.centerLeft,
      child: _checkMark(active: active),
    ),
  );

  static String _fmtMins(int mins) {
    if (mins <= 0) return '—';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}m';
  }

  static String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
