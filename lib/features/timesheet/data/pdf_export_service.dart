import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/daily_timesheet.dart';
import '../../../core/constants/app_strings.dart';

class PdfExportService {
  // Generates and shares/prints a monthly timesheet PDF.
  static Future<void> exportMonth({
    required int year,
    required int month,
    required List<DailyTimesheet> entries,
    required String userName,
    required String administration,
    int mealThresholdMins = 380,
  }) async {
    final doc = pw.Document();
    final monthName = AppStrings.months[month - 1];
    final title = 'Timesheet $monthName $year';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              AppStrings.appName,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
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
        _summaryChip('Giorni presenza', '$presence'),
        pw.SizedBox(width: 12),
        _summaryChip('Ore lavorate', _fmtMins(totalNet)),
        pw.SizedBox(width: 12),
        _summaryChip('Straordinario', _fmtMins(totalOT)),
        pw.SizedBox(width: 12),
        _summaryChip('Buoni pasto', '$totalMeal'),
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
      'Giorno',
      'Tipo',
      'Entrata',
      'Uscita',
      'Netto',
      'OT',
      'Buono',
      'Nota',
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
        // Data rows
        ...sortedEntries.map((e) {
          final date = DateTime.tryParse(e.dateId) ?? DateTime(year, month, 1);
          final day = date.day;
          final dayName = AppStrings.weekdaysShort[date.weekday - 1];
          final isWeekend = date.weekday >= 6;
          final bg = isWeekend ? PdfColors.grey100 : PdfColors.white;
          final hasMeal = e.netWorkedMins >= mealThresholdMins;
          final typeLabel = e.isRemote
              ? 'SW'
              : e.isLeave
              ? 'Perm.'
              : e.isHoliday
              ? 'Ferie'
              : 'Pres.';

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              _cell('$day $dayName'),
              _cell(typeLabel),
              _cell(_fmtTime(e.startTime)),
              _cell(_fmtTime(e.endTime)),
              _cell(_fmtMins(e.netWorkedMins)),
              _cell(e.extraMins > 0 ? '+${_fmtMins(e.extraMins)}' : '—'),
              _cell(
                hasMeal ? '✓' : '—',
                color: hasMeal ? PdfColors.green700 : PdfColors.grey400,
              ),
              _cell(e.note ?? '', maxLines: 1),
            ],
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

  static String _fmtMins(int mins) {
    if (mins <= 0) return '—';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}m';
  }

  static String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  // ─────────────────────────────────────────────────────────────────────────
  // Cartellino mensile ufficiale PCM
  // Conforms to the PCM standard monthly attendance sheet format used for
  // protocol submission. Watermarked "Generato con Chigio Time".
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> exportOfficialCartellino({
    required int year,
    required int month,
    required List<DailyTimesheet> entries,
    required String userName,
    required String administration,
    required String dipartimento,
    required String sede,
    int mealThresholdMins = 380,
    int standardDailyMins = 456,
  }) async {
    final doc = pw.Document();
    final monthName = AppStrings.months[month - 1];
    final sortedEntries = [...entries]
      ..sort((a, b) => a.dateId.compareTo(b.dateId));

    // Totals
    final presenceDays = sortedEntries
        .where(
          (e) =>
              !e.isLeave && !e.isHoliday && !e.isRemote && e.netWorkedMins > 0,
        )
        .length;
    final remoteDays = sortedEntries.where((e) => e.isRemote).length;
    final leaveDays = sortedEntries.where((e) => e.isLeave).length;
    final holidayDays = sortedEntries.where((e) => e.isHoliday).length;
    final totalNet = sortedEntries.fold<int>(0, (s, e) => s + e.netWorkedMins);
    final totalOT = sortedEntries.fold<int>(
      0,
      (s, e) => s + (e.extraMins > 0 ? e.extraMins : 0),
    );
    final totalDeficit = sortedEntries.fold<int>(
      0,
      (s, e) => s + (e.extraMins < 0 ? -e.extraMins : 0),
    );
    final mealCount = sortedEntries
        .where((e) => e.netWorkedMins >= mealThresholdMins)
        .length;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 32, 28, 40),
        header: (_) => _cartellinoHeader(
          userName: userName,
          administration: administration,
          dipartimento: dipartimento,
          sede: sede,
          month: monthName,
          year: year,
        ),
        footer: (ctx) => _cartellinoFooter(ctx),
        build: (_) => [
          _cartellinoSummary(
            presenceDays: presenceDays,
            remoteDays: remoteDays,
            leaveDays: leaveDays,
            holidayDays: holidayDays,
            totalNet: totalNet,
            totalOT: totalOT,
            totalDeficit: totalDeficit,
            mealCount: mealCount,
          ),
          pw.SizedBox(height: 14),
          _cartellinoTable(sortedEntries, month, year, mealThresholdMins),
          pw.SizedBox(height: 28),
          _signatureRow(),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename:
          'cartellino_${year}_${month.toString().padLeft(2, '0')}_${userName.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _cartellinoHeader({
    required String userName,
    required String administration,
    required String dipartimento,
    required String sede,
    required String month,
    required int year,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    administration.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'CARTELLINO MENSILE PRESENZE',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue800,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                '$month $year',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Row(
            children: [
              _headerField('DIPENDENTE', userName),
              pw.SizedBox(width: 20),
              _headerField('DIPARTIMENTO', dipartimento),
              pw.SizedBox(width: 20),
              _headerField('SEDE', sede),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.blue200, thickness: 0.5),
        pw.SizedBox(height: 4),
      ],
    );
  }

  static pw.Widget _headerField(String label, String value) => pw.Expanded(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
      ],
    ),
  );

  static pw.Widget _cartellinoSummary({
    required int presenceDays,
    required int remoteDays,
    required int leaveDays,
    required int holidayDays,
    required int totalNet,
    required int totalOT,
    required int totalDeficit,
    required int mealCount,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _summaryChip('Presenze', '$presenceDays gg'),
        _summaryChip('Smart Working', '$remoteDays gg'),
        _summaryChip('Permessi', '$leaveDays gg'),
        _summaryChip('Ferie', '$holidayDays gg'),
        _summaryChip('Ore lavorate', _fmtMins(totalNet)),
        _summaryChip('Straordinario', _fmtMins(totalOT)),
        _summaryChip('Debito', totalDeficit > 0 ? _fmtMins(totalDeficit) : '—'),
        _summaryChip('Buoni pasto', '$mealCount'),
      ],
    );
  }

  static pw.Widget _cartellinoTable(
    List<DailyTimesheet> entries,
    int month,
    int year,
    int mealThresholdMins,
  ) {
    const headers = [
      'G',
      'Giorno',
      'Tipo',
      'Entrata',
      'Uscita',
      'Lav.',
      'P.Lun',
      'P.Brv',
      'OT/Def',
      'BP',
      'Nota',
    ];

    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.4),
        bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      ),
      columnWidths: {
        0: const pw.FixedColumnWidth(20),
        1: const pw.FixedColumnWidth(28),
        2: const pw.FixedColumnWidth(35),
        3: const pw.FixedColumnWidth(38),
        4: const pw.FixedColumnWidth(38),
        5: const pw.FixedColumnWidth(38),
        6: const pw.FixedColumnWidth(32),
        7: const pw.FixedColumnWidth(32),
        8: const pw.FixedColumnWidth(38),
        9: const pw.FixedColumnWidth(22),
        10: const pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue900),
          children: headers
              .map(
                (h) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 5,
                  ),
                  child: pw.Text(
                    h,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        ...entries.map((e) {
          final date = DateTime.tryParse(e.dateId) ?? DateTime(year, month, 1);
          final day = date.day;
          final wd = AppStrings.weekdaysShort[date.weekday - 1];
          final isWeekend = date.weekday >= 6;
          final bg = isWeekend
              ? PdfColors.indigo50
              : (day % 2 == 0 ? PdfColors.grey50 : PdfColors.white);
          final hasMeal = e.netWorkedMins >= mealThresholdMins;
          final typeLabel = e.isRemote
              ? 'SW'
              : e.isLeave
              ? 'Perm.'
              : e.isHoliday
              ? 'Ferie'
              : 'Pres.';
          final otStr = e.extraMins > 0
              ? '+${_fmtMins(e.extraMins)}'
              : (e.extraMins < 0 ? '-${_fmtMins(-e.extraMins)}' : '—');
          final otColor = e.extraMins > 0
              ? PdfColors.green800
              : (e.extraMins < 0 ? PdfColors.red700 : PdfColors.grey400);

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              _cell('$day'),
              _cell(wd),
              _cell(typeLabel),
              _cell(e.netWorkedMins > 0 ? _fmtTime(e.startTime) : '—'),
              _cell(e.netWorkedMins > 0 ? _fmtTime(e.endTime) : '—'),
              _cell(e.netWorkedMins > 0 ? _fmtMins(e.netWorkedMins) : '—'),
              _cell(e.lunchPauseMins > 0 ? _fmtMins(e.lunchPauseMins) : '—'),
              _cell(
                e.standardPauseMins > 0 ? _fmtMins(e.standardPauseMins) : '—',
              ),
              _cell(otStr, color: otColor),
              _cell(
                hasMeal ? '✓' : '—',
                color: hasMeal ? PdfColors.green700 : PdfColors.grey300,
              ),
              _cell(e.note ?? '', maxLines: 2),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _signatureRow() => pw.Row(
    children: [
      _signatureBox('Il Dipendente'),
      pw.SizedBox(width: 24),
      _signatureBox('Il Responsabile'),
      pw.SizedBox(width: 24),
      _signatureBox('Ufficio Personale'),
    ],
  );

  static pw.Widget _signatureBox(String label) => pw.Expanded(
    child: pw.Column(
      children: [
        pw.Container(
          height: 36,
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
        ),
      ],
    ),
  );

  static pw.Widget _cartellinoFooter(pw.Context ctx) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        'Generato con Chigio Time  •  ${AppStrings.appName}',
        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey400),
      ),
      pw.Text(
        'Pag. ${ctx.pageNumber} / ${ctx.pagesCount}',
        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey400),
      ),
    ],
  );
}
