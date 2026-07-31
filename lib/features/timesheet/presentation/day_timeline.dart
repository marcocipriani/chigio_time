import 'package:flutter/material.dart';

import '../../../app/theme/color_schemes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/app_tappable.dart';
import '../domain/absence_kind.dart';
import '../domain/daily_timesheet.dart';
import '../domain/day_segment.dart';
import 'segment_editor_sheet.dart';

/// Timeline della giornata (ADR-0018): una riga per segmento nell'ordine in
/// cui la giornata e' stata vissuta, piu' una riga per ogni buco non coperto
/// fra due segmenti posizionati.
///
/// Non e' una card: si innesta dentro il dettaglio giornata. Non tocca
/// Firestore: ogni modifica risale al chiamante via [onChanged] con la lista
/// completa dei segmenti, gia' validata con la stessa regola dell'import CSV
/// ([DaySegment.validationError]). Una lista che l'import rifiuterebbe non
/// viene emessa: al suo posto compare il motivo in una SnackBar.
class DayTimeline extends StatelessWidget {
  final DailyTimesheet entry;
  final ValueChanged<List<DaySegment>> onChanged;

  const DayTimeline({super.key, required this.entry, required this.onChanged});

  // Il colore vive sulla barra laterale, non sul testo: cosi' la riga resta
  // leggibile in entrambi i temi senza dover declinare ogni tinta.
  static const _barColors = <String, Color>{
    DaySegment.work: AppColors.blue600,
    DaySegment.leave: AppColors.purple600,
    DaySegment.bancaOre: AppColors.green600,
    DaySegment.lunch: AppColors.green500,
    DaySegment.pause: AppColors.amber600,
  };

  // Il tipo non e' comunicato dal solo colore: emoji + etichetta lo ripetono.
  static const _emoji = <String, String>{
    DaySegment.work: '💼',
    DaySegment.leave: '🚶',
    DaySegment.bancaOre: '🏦',
    DaySegment.lunch: '🍽️',
    DaySegment.pause: '☕',
  };

  static String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  DateTime get _day => DateTime.tryParse(entry.dateId) ?? entry.startTime;

  /// Emette [next] solo se forma una giornata valida; altrimenti mostra il
  /// motivo, lo stesso che l'import stamperebbe sulla riga scartata.
  void _emit(BuildContext context, List<DaySegment> next) {
    final invalid = DaySegment.validationError(next);
    if (invalid != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(invalid), backgroundColor: AppColors.red700),
      );
      return;
    }
    onChanged(next);
  }

  Future<void> _edit(
    BuildContext context,
    List<DaySegment> segments,
    int index,
  ) async {
    final edited = await showSegmentEditor(
      context,
      initial: segments[index],
      day: _day,
    );
    if (edited == null || !context.mounted) return;
    _emit(context, DaySegment.sorted([...segments]..[index] = edited));
  }

  Future<void> _add(BuildContext context, List<DaySegment> segments) async {
    final created = await showSegmentEditor(context, day: _day);
    if (created == null || !context.mounted) return;
    _emit(context, DaySegment.sorted([...segments, created]));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.65)
        : AppColors.neutral600;
    final accent = isDark ? AppColors.blue300 : AppColors.blue600;
    final warn = isDark ? AppColors.orange500 : AppColors.orange600;

    final segments = DaySegment.sorted(entry.segments);
    final rows = <Widget>[];
    DateTime? coveredUntil;
    for (var i = 0; i < segments.length; i++) {
      final s = segments[i];
      if (s.start != null && coveredUntil != null) {
        final gap = s.start!.difference(coveredUntil).inMinutes;
        if (gap > 0) rows.add(_gapRow(gap, warn));
      }
      rows.add(_segmentRow(context, segments, i, textMain, textSub, isDark));
      if (s.end != null &&
          (coveredUntil == null || s.end!.isAfter(coveredUntil))) {
        coveredUntil = s.end;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text('🕒', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              AppStrings.timelineTitle,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textMain,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              AppStrings.nessunSegmento,
              style: TextStyle(fontSize: 12, color: textSub),
            ),
          )
        else
          ...rows,
        const SizedBox(height: 6),
        AppTappable(
          onTap: () => _add(context, segments),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 16, color: accent),
                const SizedBox(width: 6),
                Text(
                  AppStrings.aggiungiSegmento,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _segmentRow(
    BuildContext context,
    List<DaySegment> segments,
    int index,
    Color textMain,
    Color textSub,
    bool isDark,
  ) {
    final s = segments[index];
    final positioned = s.start != null && s.end != null;
    final value = positioned
        ? '${_hm(s.start!)} – ${_hm(s.end!)}'
        : AppStrings.minutiLabel(s.durationMins);
    final subtitle = s.type == DaySegment.leave
        ? AbsenceKind.labelFor(s.absenceKind)
        : null;

    return AppTappable(
      onTap: () => _edit(context, segments, index),
      semanticLabel: '${AppStrings.modificaSegmento}: '
          '${DaySegment.labelFor(s.type)} $value',
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 26,
              decoration: BoxDecoration(
                color: _barColors[s.type] ?? AppColors.neutral400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(_emoji[s.type] ?? '•', style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DaySegment.labelFor(s.type),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textMain,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: textSub),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textMain,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            AppTappable(
              onTap: () => _emit(context, [...segments]..removeAt(index)),
              tooltip: AppStrings.eliminaSegmento,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: isDark ? AppColors.red300 : AppColors.red700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gapRow(int mins, Color warn) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        const SizedBox(width: 4),
        Icon(Icons.warning_amber_rounded, size: 15, color: warn),
        const SizedBox(width: 8),
        Text(
          AppStrings.nonCopertoDetail(mins),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: warn,
          ),
        ),
      ],
    ),
  );
}
