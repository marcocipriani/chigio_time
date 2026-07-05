import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/color_schemes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/app_tappable.dart';
import '../../../shared/widgets/glass_card.dart';
import '../data/profile_repository.dart';
import '../domain/monthly_sau.dart';

/// Andamento dello straordinario autorizzato (SAU = SLI + SBO) registrato
/// mese per mese: grafico ultimi 12 mesi + storico delle variazioni
/// (valore, mese di inizio, mese di fine).
class SauScreen extends ConsumerWidget {
  const SauScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppColors.neutral600;

    final history =
        ref.watch(monthlySauHistoryStreamProvider).asData?.value ?? [];
    final sorted = [...history]..sort((a, b) => a.monthId.compareTo(b.monthId));
    // Momento di entrata in servizio: registrato in automatico come inizio
    // della timeline dell'andamento straordinario.
    final profile = ref.watch(userProfileStreamProvider).asData?.value;
    final hireDate = DateTime.tryParse(profile?['hireDate'] as String? ?? '');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: Row(
                children: [
                  AppTappable(
                    onTap: () => context.pop(),
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(
                                    0xFF10102A,
                                  ).withValues(alpha: 0.58)
                                : Colors.white.withValues(alpha: 0.56),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.7)
                                : AppColors.neutral700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppStrings.sauTrendTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textMain,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  // ── Cos'è ────────────────────────────────────────────
                  GlassCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppStrings.sauExplainer,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.45,
                              color: textSub,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Grafico ultimi 12 mesi ───────────────────────────
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.sauLast12.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: textSub,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _Legend(color: AppColors.blue600, label: 'SLI'),
                            const SizedBox(width: 12),
                            _Legend(color: AppColors.green500, label: 'SBO'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 180,
                          child: sorted.isEmpty
                              ? Center(
                                  child: Text(
                                    AppStrings.sauNoData,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSub,
                                    ),
                                  ),
                                )
                              : _SauStackedChart(
                                  history: sorted,
                                  isDark: isDark,
                                  textSub: textSub,
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Storico variazioni ───────────────────────────────
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.sauHistoryVariations.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: textSub,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (sorted.isEmpty && hireDate == null)
                          Text(
                            AppStrings.sauNoData,
                            style: TextStyle(fontSize: 12, color: textSub),
                          )
                        else ...[
                          ..._variationRanges(sorted).reversed.map(
                            (r) => _VariationRow(
                              range: r,
                              isDark: isDark,
                              textMain: textMain,
                              textSub: textSub,
                            ),
                          ),
                          // Momento di entrata in servizio (registrato auto).
                          if (hireDate != null)
                            _HireDateRow(
                              hireDate: hireDate,
                              isDark: isDark,
                              textMain: textMain,
                              textSub: textSub,
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Storico variazioni: mesi consecutivi con lo stesso valore ───────────────

class _SauRange {
  final int sli;
  final int sbo;
  final String fromId;
  String toId;
  bool openEnded; // ultimo range = valore ancora in corso

  _SauRange({
    required this.sli,
    required this.sbo,
    required this.fromId,
    required this.toId,
  }) : openEnded = false;

  int get sau => sli + sbo;
}

/// Raggruppa la storia (ordinata ascendente) in range di mesi consecutivi
/// con lo stesso (SLI, SBO). Un buco nei mesi chiude il range.
List<_SauRange> _variationRanges(List<MonthlySau> sorted) {
  final ranges = <_SauRange>[];
  for (final s in sorted) {
    final last = ranges.isEmpty ? null : ranges.last;
    if (last != null &&
        last.sli == s.sliHours &&
        last.sbo == s.sboHours &&
        _isNextMonth(last.toId, s.monthId)) {
      last.toId = s.monthId;
    } else {
      ranges.add(
        _SauRange(
          sli: s.sliHours,
          sbo: s.sboHours,
          fromId: s.monthId,
          toId: s.monthId,
        ),
      );
    }
  }
  if (ranges.isNotEmpty) ranges.last.openEnded = true;
  return ranges;
}

bool _isNextMonth(String a, String b) {
  final pa = a.split('-').map(int.tryParse).toList();
  final pb = b.split('-').map(int.tryParse).toList();
  if (pa.length < 2 || pb.length < 2) return false;
  final ya = pa[0] ?? 0, ma = pa[1] ?? 0, yb = pb[0] ?? 0, mb = pb[1] ?? 0;
  return (ya * 12 + ma) + 1 == (yb * 12 + mb);
}

String _monthLabel(String monthId) {
  final parts = monthId.split('-');
  final y = int.tryParse(parts.elementAtOrNull(0) ?? '') ?? 0;
  final m = int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0;
  if (m < 1 || m > 12) return monthId;
  return '${AppStrings.monthsShort[m - 1]} $y';
}

/// Riga "entrata in servizio" a fondo timeline (registrata in automatico
/// dalla Data presa servizio del profilo).
class _HireDateRow extends StatelessWidget {
  final DateTime hireDate;
  final bool isDark;
  final Color textMain;
  final Color textSub;

  const _HireDateRow({
    required this.hireDate,
    required this.isDark,
    required this.textMain,
    required this.textSub,
  });

  @override
  Widget build(BuildContext context) {
    final label =
        '${AppStrings.monthsShort[hireDate.month - 1]} ${hireDate.year}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.blue600.withValues(alpha: isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('🚀', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.hireDateLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textMain,
                  ),
                ),
                Text(label, style: TextStyle(fontSize: 11.5, color: textSub)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VariationRow extends StatelessWidget {
  final _SauRange range;
  final bool isDark;
  final Color textMain;
  final Color textSub;

  const _VariationRow({
    required this.range,
    required this.isDark,
    required this.textMain,
    required this.textSub,
  });

  @override
  Widget build(BuildContext context) {
    final from = _monthLabel(range.fromId);
    final to = range.openEnded
        ? AppStrings.sauOngoing
        : _monthLabel(range.toId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.orange500.withValues(
                alpha: isDark ? 0.18 : 0.10,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${range.sau}h',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.orange500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SLI ${range.sli}h · SBO ${range.sbo}h',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textMain,
                  ),
                ),
                Text(
                  AppStrings.sauRange(from, to),
                  style: TextStyle(fontSize: 11.5, color: textSub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grafico: barre impilate SLI+SBO per mese ─────────────────────────────────

class _SauStackedChart extends StatelessWidget {
  final List<MonthlySau> history; // ordinata ascendente
  final bool isDark;
  final Color textSub;

  const _SauStackedChart({
    required this.history,
    required this.isDark,
    required this.textSub,
  });

  @override
  Widget build(BuildContext context) {
    final last12 = history.length > 12
        ? history.sublist(history.length - 12)
        : history;
    final maxY = last12
        .map((s) => s.sauHours.toDouble())
        .fold(6.0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY + 1,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (g, gi, rod, ri) {
              final s = last12[gi];
              return BarTooltipItem(
                '${_monthLabel(s.monthId)}\nSLI ${s.sliHours}h · SBO ${s.sboHours}h',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              getTitlesWidget: (v, m) {
                final i = v.toInt();
                if (i < 0 || i >= last12.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    AppStrings.monthsShort[last12[i].month - 1],
                    style: TextStyle(fontSize: 9, color: textSub),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.06),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(last12.length, (i) {
          final s = last12[i];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: s.sauHours.toDouble(),
                width: 14,
                borderRadius: BorderRadius.circular(4),
                rodStackItems: [
                  BarChartRodStackItem(
                    0,
                    s.sliHours.toDouble(),
                    AppColors.blue600.withValues(alpha: 0.9),
                  ),
                  BarChartRodStackItem(
                    s.sliHours.toDouble(),
                    s.sauHours.toDouble(),
                    AppColors.green500.withValues(alpha: 0.9),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
