import 'package:flutter/material.dart';
import '../../app/theme/color_schemes.dart';
import '../../core/constants/app_strings.dart';
import 'glass_card.dart';

/// Monthly stats card (glass style, S-19 redesign).
///
/// Shows Ore tot / Magg. presenza / Buoni pasto up front, with the maggior
/// presenza breakdown (Art.9 / SLI / SBO / OP) indented right below it, and
/// the uncovered deficit as a separate red line when present. No longer
/// collapsible or user-customizable — see docs/CHANGELOG.md for context.
class MonthlySummaryCard extends StatelessWidget {
  final int year;
  final int month;
  final int totalNetMins;
  final int totalOtMins;
  final int totalMeal;
  final int art9Mins;
  final int sliMins;
  final int sboMins;
  final int opMins;
  final int deficitMins;
  final int swCount;
  final int swYearCount;
  final VoidCallback? onPrevMonth;
  final VoidCallback? onNextMonth;
  final VoidCallback? onMonthTap;
  final bool showMonthNav;

  const MonthlySummaryCard({
    super.key,
    required this.year,
    required this.month,
    required this.totalNetMins,
    required this.totalOtMins,
    required this.totalMeal,
    required this.art9Mins,
    required this.sliMins,
    required this.sboMins,
    required this.opMins,
    required this.deficitMins,
    this.swCount = 0,
    this.swYearCount = 0,
    this.onPrevMonth,
    this.onNextMonth,
    this.onMonthTap,
    this.showMonthNav = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : AppColors.neutral600;
    final badgeBg = AppColors.blue600.withValues(alpha: isDark ? 0.22 : 0.10);
    final badgeFg = isDark ? AppColors.blue300 : AppColors.blue600;

    return GlassCard(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        children: [
          // Month nav row
          if (showMonthNav) ...[
            Row(
              children: [
                _NavCircle(
                  icon: Icons.chevron_left_rounded,
                  onTap: onPrevMonth,
                  isDark: isDark,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: onMonthTap,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${AppStrings.months[month - 1]} $year',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textMain,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (swCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '🖥 $swCount SW',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: badgeFg,
                              ),
                            ),
                          ),
                        ],
                        if (swYearCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '🖥 $year: $swYearCount SW',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: badgeFg.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                        if (onMonthTap != null) ...[
                          const SizedBox(width: 3),
                          Icon(
                            Icons.expand_more_rounded,
                            size: 14,
                            color: textSub,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                _NavCircle(
                  icon: Icons.chevron_right_rounded,
                  onTap: onNextMonth,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Riga principale: Ore tot · Magg. presenza · Buoni pasto
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BigStat(
                label: AppStrings.totalHours,
                value: '${totalNetMins ~/ 60}h',
                isDark: isDark,
              ),
              _BigStat(
                label: AppStrings.maggiorPresenzaShort,
                value: totalOtMins == 0 ? '—' : _fmtHm(totalOtMins),
                isDark: isDark,
              ),
              _BigStat(
                label: AppStrings.buoniPastoLabel,
                value: '$totalMeal 🍽️',
                isDark: isDark,
              ),
            ],
          ),

          // Scorporo maggior presenza — visivamente legato (indent + dot)
          if (totalOtMins > 0) ...[
            const SizedBox(height: 10),
            _BreakdownRow(
              isDark: isDark,
              entries: [
                (AppStrings.art9Label, art9Mins),
                (AppStrings.sliLabel, sliMins),
                (AppStrings.sboLabel, sboMins),
                (AppStrings.opLabel, opMins),
              ],
            ),
          ],

          // Deficit — riga separata rossa, solo se > 0
          if (deficitMins > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${AppStrings.deficitLabel} −${_fmtHm(deficitMins)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFFF9B9B) : AppColors.red700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Format minutes as `HH:MM`.
String _fmtHm(int mins) {
  final h = mins.abs() ~/ 60;
  final m = mins.abs() % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

// ── Small nav circle button ───────────────────────────────────────────────────

class _NavCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;
  const _NavCircle({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return const SizedBox(width: 28);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.05),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isDark
              ? Colors.white.withValues(alpha: 0.85)
              : AppColors.neutral700,
        ),
      ),
    );
  }
}

// ── Header stat ───────────────────────────────────────────────────────────────

class _BigStat extends StatelessWidget {
  final String label, value;
  final bool isDark;
  const _BigStat({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark
                ? Colors.white.withValues(alpha: 0.90)
                : AppColors.neutral900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark
                ? Colors.white.withValues(alpha: 0.55)
                : AppColors.neutral600,
          ),
        ),
      ],
    );
  }
}

// ── Indented maggior presenza breakdown ─────────────────────────────────────

/// Indented breakdown: "Art.9 8:00 · SLI 2:00 · SBO 1:30 · OP 0:54".
/// Zero entries render as "—" to keep the sum readable at a glance.
class _BreakdownRow extends StatelessWidget {
  final bool isDark;
  final List<(String, int)> entries;
  const _BreakdownRow({required this.isDark, required this.entries});

  @override
  Widget build(BuildContext context) {
    final sub = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : AppColors.neutral600;
    final val = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.neutral900;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.blue600.withValues(alpha: isDark ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        children: [
          for (final (label, mins) in entries)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: sub,
                    ),
                  ),
                  TextSpan(
                    text: mins == 0 ? '—' : _fmtHm(mins),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: val,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
