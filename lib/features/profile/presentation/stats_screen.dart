import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/color_schemes.dart';
import '../../../core/constants/app_strings.dart';
import '../../timesheet/data/timesheet_repository.dart';
import '../../timesheet/domain/daily_timesheet.dart';
import '../data/profile_repository.dart';
import '../domain/monthly_sau.dart';
import '../../social/data/social_repository.dart';
import '../../dashboard/presentation/totalizzatori_provider.dart';
import '../../../shared/widgets/monthly_summary_card.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral600;

    final now = DateTime.now();
    final profileData = ref.watch(userProfileStreamProvider).asData?.value;
    final totData = ref.watch(totalizzatoriProvider);
    final sauHistory =
        ref.watch(monthlySauHistoryStreamProvider).asData?.value ?? <MonthlySau>[];

    // Last 6 months
    final last6 = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return (year: d.year, month: d.month);
    }).reversed.toList();

    final mealThreshold =
        profileData?['mealVoucherThresholdMins'] as int? ?? 380;
    final visibleItems =
        (profileData?['summaryItems'] as List<dynamic>?)?.cast<String>() ??
        MonthlySummaryCard.defaultItems;
    final showProgress = profileData?['summaryShowProgress'] as bool? ?? true;

    // ── Collect data for all months ───────────────────────────────────────
    final monthData = last6.map((ym) {
      final entries =
          ref
              .watch(
                monthlyTimesheetsProvider((year: ym.year, month: ym.month)),
              )
              .asData
              ?.value ??
          [];
      return _MonthStats.from(entries, ym.year, ym.month, mealThreshold);
    }).toList();

    // Current month summary
    final cur = monthData.last;

    // ── OT by weekday (last 3 months) ────────────────────────────────────
    final otByWeekday = List.filled(5, 0); // Mon–Fri
    for (final ms in monthData.skip(3)) {
      for (final e in ms.entries) {
        if (e.extraMins > 0 && !e.isLeave && !e.isHoliday) {
          final wd = e.startTime.weekday - 1; // 0=Mon .. 4=Fri
          if (wd < 5) otByWeekday[wd] += e.extraMins;
        }
      }
    }
    final maxOtWd = otByWeekday.fold(1, math.max);

    // ── Advanced stats (all 6 months) ────────────────────────────────────
    final allEntries = monthData.expand((ms) => ms.entries).toList();
    final presenceEntries = allEntries
        .where((e) => !e.isLeave && !e.isHoliday && e.netWorkedMins > 0)
        .toList();

    // Best consecutive presence streak — must iterate ALL entries sorted by
    // date so leave/holiday days actually reset the counter.
    final sortedAll = [...allEntries]
      ..sort((a, b) => a.dateId.compareTo(b.dateId));
    int bestStreak = 0, curStreak = 0;
    for (final e in sortedAll) {
      if (!e.isLeave && !e.isHoliday && e.netWorkedMins > 0) {
        curStreak++;
        if (curStreak > bestStreak) bestStreak = curStreak;
      } else if (e.isLeave || e.isHoliday) {
        curStreak = 0;
      }
    }

    // Average break duration (all pause types combined, only days with pauses)
    final breakMins = presenceEntries
        .map((e) => e.standardPauseMins + e.lunchPauseMins + e.leavePauseMins)
        .where((m) => m > 0)
        .toList();
    final avgBreakMins = breakMins.isEmpty
        ? 0
        : breakMins.fold(0, (a, b) => a + b) ~/ breakMins.length;

    // Punctuality rate: arrived within ±15 min of standard start (09:00)
    const stdStartH = 9, stdStartMin = 0;
    final stdStartMins = stdStartH * 60 + stdStartMin;
    final onTimeCount = presenceEntries.where((e) {
      final entryMins = e.startTime.hour * 60 + e.startTime.minute;
      return (entryMins - stdStartMins).abs() <= 15;
    }).length;
    final punctualityPct = presenceEntries.isEmpty
        ? 0.0
        : onTimeCount / presenceEntries.length * 100;

    // ── Funny stats ───────────────────────────────────────────────────────
    // Presence count per weekday (0=Mon..4=Fri) in last 6 months
    final presenceByWd = List.filled(5, 0);
    for (final e in presenceEntries) {
      final wd = DateTime.parse(e.dateId).weekday - 1;
      if (wd < 5) presenceByWd[wd]++;
    }
    final maxPresenceWd = presenceByWd.indexOf(presenceByWd.reduce(math.max));
    final mondayPresence = presenceByWd[0];
    final totalMondays = allEntries.where((e) {
      final d = DateTime.parse(e.dateId);
      return d.weekday == 1;
    }).length;
    final mondayRate = totalMondays > 0
        ? (mondayPresence / totalMondays * 100).round()
        : 0;
    // SW count
    final swTotal = allEntries.where((e) => e.isRemote).length;
    // Earliest entry ever
    final earliestEntry = presenceEntries.isEmpty
        ? null
        : presenceEntries.reduce(
            (a, b) =>
                a.startTime.hour * 60 + a.startTime.minute <
                    b.startTime.hour * 60 + b.startTime.minute
                ? a
                : b,
          );

    // Most frequent exit hour (presence days only)
    final exitHourCounts = <int, int>{};
    for (final e in presenceEntries) {
      exitHourCounts.update(e.endTime.hour, (v) => v + 1, ifAbsent: () => 1);
    }
    int? topExitHour;
    var topExitCount = 0;
    exitHourCounts.forEach((h, c) {
      if (c > topExitCount) {
        topExitCount = c;
        topExitHour = h;
      }
    });

    // Weekday with most OT (from the same 3-month window of the chart)
    final topOtWdIdx = otByWeekday.indexOf(otByWeekday.reduce(math.max));
    final hasAnyOtWd = otByWeekday.any((m) => m > 0);

    // Coffee sent vs received (current month)
    final coffeeStats = ref.watch(coffeeStatsProvider);

    // Best / worst OT month over the 6-month window
    final monthsWithData = monthData
        .where((m) => m.entries.isNotEmpty)
        .toList();
    _MonthStats? bestOtMonth;
    _MonthStats? worstOtMonth;
    if (monthsWithData.length >= 2) {
      bestOtMonth = monthsWithData.reduce(
        (a, b) => a.totalOtMins >= b.totalOtMins ? a : b,
      );
      worstOtMonth = monthsWithData.reduce(
        (a, b) => a.totalOtMins <= b.totalOtMins ? a : b,
      );
    }

    // ── Chart helpers ─────────────────────────────────────────────────────
    String fmtHM(int m) {
      final h = m ~/ 60;
      final min = m % 60;
      if (h == 0) return '${min}m';
      if (min == 0) return '${h}h';
      return '${h}h${min.toString().padLeft(2, '0')}';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.6),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.8),
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
                  const SizedBox(width: 12),
                  Text(
                    AppStrings.advancedStats,
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                children: [
                  // ── Contatori mese corrente ─────────────────────────
                  MonthlySummaryCard(
                    year: now.year,
                    month: now.month,
                    totalNetMins: cur.totalNetMins,
                    totalOtMins: cur.totalOtMins,
                    totalMeal: cur.mealCount,
                    art9Mins: cur.leaveMins,
                    sliMins: 0,
                    sboMins: 0,
                    deficitMins: cur.deficitMins,
                    art9Cap:
                        (profileData?['monthlyArt9Hours'] as int? ?? 0) * 60,
                    sliCap: 0,
                    sboCap: 0,
                    overtimeCap:
                        (profileData?['monthlyOvertimeHours'] as int? ?? 0) *
                        60,
                    visibleItems: visibleItems,
                    showProgressBars: showProgress,
                    showMonthNav: false,
                  ),

                  const SizedBox(height: 12),

                  // ── Highlight widget ────────────────────────────────
                  _buildHighlightCard(
                    profileData: profileData,
                    cur: cur,
                    totData: totData,
                    isDark: isDark,
                    textSub: textSub,
                    fmtHM: fmtHM,
                  ),

                  // ── Chart 1: Media ore giornaliere ──────────────────
                  _ChartCard(
                    title: AppStrings.statsAvgDaily,
                    isDark: isDark,
                    legend: [
                      _LegendItem(
                        color: AppColors.blue600,
                        label: AppStrings.statsHoursPerDay,
                      ),
                    ],
                    child: SizedBox(
                      height: 130,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 10,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (g, gi, rod, ri) {
                                final avg = monthData[gi].avgDailyMins;
                                if (avg == 0) return null;
                                return BarTooltipItem(
                                  fmtHM(avg),
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
                                  if (i < 0 || i >= last6.length)
                                    return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      AppStrings.monthsShort[last6[i].month -
                                          1],
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: textSub,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            drawVerticalLine: false,
                            horizontalInterval: 2,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.04),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(monthData.length, (i) {
                            final avgH = monthData[i].avgDailyMins / 60.0;
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: avgH,
                                  width: 18,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                  gradient: LinearGradient(
                                    colors: avgH > 0
                                        ? [AppColors.blue400, AppColors.blue600]
                                        : [
                                            Colors.transparent,
                                            Colors.transparent,
                                          ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Chart 2: Straordinari per giorno settimana ───────
                  _ChartCard(
                    title: AppStrings.statsOtByWeekday,
                    subtitle: AppStrings.statsLast3Months,
                    isDark: isDark,
                    legend: [
                      _LegendItem(
                        color: AppColors.orange600,
                        label: AppStrings.overtime,
                      ),
                    ],
                    child: SizedBox(
                      height: 130,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (maxOtWd / 60.0) + 0.5,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (g, gi, rod, ri) {
                                final mins = otByWeekday[gi];
                                if (mins == 0) return null;
                                return BarTooltipItem(
                                  fmtHM(mins),
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
                                  final days = AppStrings.weekdaysShort
                                      .take(5)
                                      .toList();
                                  final i = v.toInt();
                                  if (i < 0 || i >= 5)
                                    return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      days[i],
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: textSub,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.04),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(5, (i) {
                            final otH = otByWeekday[i] / 60.0;
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: otH,
                                  width: 24,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                  gradient: LinearGradient(
                                    colors: otH > 0
                                        ? [
                                            const Color(0xFFF97316),
                                            const Color(0xFFEA580C),
                                          ]
                                        : [
                                            Colors.transparent,
                                            Colors.transparent,
                                          ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Scheda avanzata ──────────────────────────────────
                  _AdvancedStatsCard(
                    isDark: isDark,
                    textSub: textSub,
                    bestStreak: bestStreak,
                    avgBreakMins: avgBreakMins,
                    punctualityPct: punctualityPct,
                    fmtHM: fmtHM,
                    frequentExitLabel: topExitHour != null
                        ? '${topExitHour!.toString().padLeft(2, '0')}:00'
                        : null,
                    topOtWeekday: hasAnyOtWd
                        ? AppStrings.weekdaysShort[topOtWdIdx]
                        : null,
                  ),

                  const SizedBox(height: 12),

                  _FunnyStatsCard(
                    isDark: isDark,
                    textSub: textSub,
                    mondayRate: mondayRate,
                    bestWeekday: maxPresenceWd,
                    swTotal: swTotal,
                    earliestStartTime: earliestEntry != null
                        ? '${earliestEntry.startTime.hour.toString().padLeft(2, '0')}:${earliestEntry.startTime.minute.toString().padLeft(2, '0')}'
                        : null,
                    coffeeSent: coffeeStats.sent,
                    coffeeReceived: coffeeStats.received,
                    bestOtMonthLabel: bestOtMonth != null
                        ? '${AppStrings.monthsShort[bestOtMonth.month - 1]} · ${fmtHM(bestOtMonth.totalOtMins)}'
                        : null,
                    worstOtMonthLabel: worstOtMonth != null
                        ? '${AppStrings.monthsShort[worstOtMonth.month - 1]} · ${fmtHM(worstOtMonth.totalOtMins)}'
                        : null,
                  ),

                  const SizedBox(height: 12),

                  // ── Chart 3: Permessi e ferie ────────────────────────
                  _ChartCard(
                    title: AppStrings.statsLeaveVacation,
                    isDark: isDark,
                    legend: [
                      _LegendItem(
                        color: AppColors.blue400,
                        label: AppStrings.wtLeave,
                      ),
                      _LegendItem(
                        color: AppColors.green500,
                        label: AppStrings.wtHoliday,
                      ),
                    ],
                    child: SizedBox(
                      height: 130,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: math.max(
                            1.0,
                            monthData.fold<double>(
                                  0.0,
                                  (m, ms) => math.max(
                                    m,
                                    (ms.leaveDays + ms.holidayDays).toDouble(),
                                  ),
                                ) +
                                1,
                          ),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (g, gi, rod, ri) {
                                final ms = monthData[gi];
                                if (ms.leaveDays + ms.holidayDays == 0)
                                  return null;
                                return BarTooltipItem(
                                  AppStrings.leaveAndHolidayDays(
                                    ms.leaveDays,
                                    ms.holidayDays,
                                  ),
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
                                  if (i < 0 || i >= last6.length)
                                    return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      AppStrings.monthsShort[last6[i].month -
                                          1],
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: textSub,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.04),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(monthData.length, (i) {
                            final ms = monthData[i];
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: ms.leaveDays.toDouble(),
                                  width: 10,
                                  borderRadius: BorderRadius.circular(3),
                                  color: AppColors.blue400,
                                ),
                                BarChartRodData(
                                  toY: ms.holidayDays.toDouble(),
                                  width: 10,
                                  borderRadius: BorderRadius.circular(3),
                                  color: AppColors.green500,
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Tabella media entrate ────────────────────────────
                  _AvgEntryTable(
                    monthData: monthData,
                    last6: last6,
                    isDark: isDark,
                    textSub: textSub,
                  ),

                  if (sauHistory.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    // ── Chart 4: Storico SLI/SBO/SAU ──────────────────
                    _ChartCard(
                      title: AppStrings.sauMonthly,
                      isDark: isDark,
                      legend: [
                        _LegendItem(color: AppColors.blue600, label: AppStrings.sliMonthly),
                        _LegendItem(color: AppColors.green500, label: AppStrings.sboMonthly),
                        _LegendItem(color: AppColors.orange500, label: 'SAU'),
                      ],
                      child: SizedBox(
                        height: 140,
                        child: _SauHistoryChart(
                          history: sauHistory,
                          isDark: isDark,
                          textSub: textSub,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightCard({
    required Map<String, dynamic>? profileData,
    required _MonthStats cur,
    required dynamic totData,
    required bool isDark,
    required Color textSub,
    required String Function(int) fmtHM,
  }) {
    final mode = profileData?['highlightWidget'] as String? ?? 'none';
    if (mode == 'none') return const SizedBox.shrink();

    String label;
    String value;
    String icon;
    Color color;

    switch (mode) {
      case 'bankHours':
        final mins = (totData?.totaleBancaOreFruibile as int?) ?? 0;
        label = AppStrings.highlightBankHours;
        value = fmtHM(mins);
        icon = '🏦';
        color = AppColors.blue600;
      case 'overtime':
        label = AppStrings.highlightOvertime;
        value = fmtHM(cur.totalOtMins);
        icon = '⏱️';
        color = AppColors.orange600;
      case 'mealCount':
        label = AppStrings.highlightMealCount;
        value = '${cur.mealCount} 🍽️';
        icon = '🍽️';
        color = AppColors.green600;
      default:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data model ─────────────────────────────────────────────────────────────

class _MonthStats {
  final int year;
  final int month;
  final List<DailyTimesheet> entries;
  final int totalNetMins;
  final int totalOtMins;
  final int leaveMins;
  final int deficitMins;
  final int mealCount;
  final int leaveDays;
  final int holidayDays;

  _MonthStats({
    required this.year,
    required this.month,
    required this.entries,
    required this.totalNetMins,
    required this.totalOtMins,
    required this.leaveMins,
    required this.deficitMins,
    required this.mealCount,
    required this.leaveDays,
    required this.holidayDays,
  });

  int get presenceDays => entries
      .where((e) => !e.isLeave && !e.isHoliday && e.netWorkedMins > 0)
      .length;

  int get avgDailyMins => presenceDays == 0 ? 0 : totalNetMins ~/ presenceDays;

  DateTime? get avgEntryTime {
    final presenceEntries = entries
        .where((e) => !e.isLeave && !e.isHoliday && e.netWorkedMins > 0)
        .toList();
    if (presenceEntries.isEmpty) return null;
    final totalMins = presenceEntries.fold<int>(
      0,
      (s, e) => s + e.startTime.hour * 60 + e.startTime.minute,
    );
    final avgMins = totalMins ~/ presenceEntries.length;
    return DateTime(year, month, 1, avgMins ~/ 60, avgMins % 60);
  }

  factory _MonthStats.from(
    List<DailyTimesheet> entries,
    int year,
    int month,
    int mealThreshold,
  ) => _MonthStats(
    year: year,
    month: month,
    entries: entries,
    totalNetMins: entries.fold(0, (s, e) => s + e.netWorkedMins),
    totalOtMins: entries.fold(
      0,
      (s, e) => s + (e.extraMins > 0 ? e.extraMins : 0),
    ),
    leaveMins: entries.fold(0, (s, e) => s + e.leavePauseMins),
    deficitMins: entries.fold(
      0,
      (s, e) => s + (e.extraMins < 0 ? -e.extraMins : 0),
    ),
    mealCount: entries.where((e) => e.netWorkedMins >= mealThreshold).length,
    leaveDays: entries.where((e) => e.isLeave).length,
    holidayDays: entries.where((e) => e.isHoliday).length,
  );
}

// ── SAU history bar chart ────────────────────────────────────────────────────

class _SauHistoryChart extends StatelessWidget {
  final List<MonthlySau> history;
  final bool isDark;
  final Color textSub;

  const _SauHistoryChart({
    required this.history,
    required this.isDark,
    required this.textSub,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...history]
      ..sort((a, b) => a.monthId.compareTo(b.monthId));
    final last6 = sorted.length > 6 ? sorted.sublist(sorted.length - 6) : sorted;
    if (last6.isEmpty) return const SizedBox.shrink();

    final maxY = last6
        .map((s) => s.sauHours.toDouble())
        .fold(8.0, (a, b) => a > b ? a : b)
        .ceilToDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY + 2,
        groupsSpace: 8,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (g, gi, rod, ri) {
              final s = last6[gi];
              final labels = ['SLI', 'SBO', 'SAU'];
              final vals = [s.sliHours, s.sboHours, s.sauHours];
              return BarTooltipItem(
                '${labels[ri]}: ${vals[ri]}h',
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
                if (i < 0 || i >= last6.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    AppStrings.monthsShort[last6[i].month - 1],
                    style: TextStyle(fontSize: 10, color: textSub),
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
        barGroups: List.generate(last6.length, (i) {
          final s = last6[i];
          return BarChartGroupData(
            x: i,
            groupVertically: false,
            barRods: [
              BarChartRodData(
                toY: s.sliHours.toDouble(),
                color: AppColors.blue600.withValues(alpha: 0.85),
                width: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              BarChartRodData(
                toY: s.sboHours.toDouble(),
                color: AppColors.green500.withValues(alpha: 0.85),
                width: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              BarChartRodData(
                toY: s.sauHours.toDouble(),
                color: AppColors.orange500.withValues(alpha: 0.85),
                width: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Chart card wrapper ──────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isDark;
  final Widget child;
  final List<_LegendItem> legend;

  const _ChartCard({
    required this.title,
    this.subtitle,
    required this.isDark,
    required this.child,
    required this.legend,
  });

  @override
  Widget build(BuildContext context) {
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : AppColors.neutral400;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: textSub,
                  ),
                ),
              ),
              if (subtitle != null)
                Text(subtitle!, style: TextStyle(fontSize: 9, color: textSub)),
            ],
          ),
          const SizedBox(height: 14),
          child,
          const SizedBox(height: 10),
          Row(
            children: [
              for (final item in legend) ...[
                if (item != legend.first) const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.label,
                      style: TextStyle(fontSize: 9, color: textSub),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
}

// ── Average entry time table ────────────────────────────────────────────────

class _AvgEntryTable extends StatelessWidget {
  final List<_MonthStats> monthData;
  final List<({int year, int month})> last6;
  final bool isDark;
  final Color textSub;

  const _AvgEntryTable({
    required this.monthData,
    required this.last6,
    required this.isDark,
    required this.textSub,
  });

  @override
  Widget build(BuildContext context) {
    String p2(int n) => n.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.statsAvgEntry.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: textSub,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(monthData.length, (i) {
            final ms = monthData[i];
            final entry = ms.avgEntryTime;
            final days = ms.presenceDays;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      AppStrings.monthsShort[last6[i].month - 1],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textSub,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry != null
                        ? '${p2(entry.hour)}:${p2(entry.minute)}'
                        : '—',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: entry != null ? AppColors.blue600 : textSub,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    days > 0 ? AppStrings.daysCount(days) : '—',
                    style: TextStyle(fontSize: 11, color: textSub),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Advanced stats card ─────────────────────────────────────────────────────

class _AdvancedStatsCard extends StatelessWidget {
  final bool isDark;
  final Color textSub;
  final int bestStreak;
  final int avgBreakMins;
  final double punctualityPct;
  final String Function(int) fmtHM;
  final String? frequentExitLabel;
  final String? topOtWeekday;

  const _AdvancedStatsCard({
    required this.isDark,
    required this.textSub,
    required this.bestStreak,
    required this.avgBreakMins,
    required this.punctualityPct,
    required this.fmtHM,
    this.frequentExitLabel,
    this.topOtWeekday,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.75);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.9);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.advancedStatsUpper,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: textSub,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatPill(
                icon: '🔥',
                label: AppStrings.attendanceRecord,
                value: AppStrings.daysCount(bestStreak),
                color: AppColors.orange500,
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _StatPill(
                icon: '☕',
                label: AppStrings.averageBreak,
                value: avgBreakMins > 0 ? fmtHM(avgBreakMins) : '—',
                color: AppColors.blue600,
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _StatPill(
                icon: '🎯',
                label: AppStrings.punctuality,
                value: '${punctualityPct.toStringAsFixed(0)}%',
                color: AppColors.green600,
                isDark: isDark,
              ),
            ],
          ),
          if (frequentExitLabel != null || topOtWeekday != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (frequentExitLabel != null)
                  _StatPill(
                    icon: '🚪',
                    label: 'Uscita tipica',
                    value: frequentExitLabel!,
                    color: AppColors.blue600,
                    isDark: isDark,
                  ),
                if (frequentExitLabel != null && topOtWeekday != null)
                  const SizedBox(width: 10),
                if (topOtWeekday != null)
                  _StatPill(
                    icon: '⏰',
                    label: 'Giorno più OT',
                    value: topOtWeekday!,
                    color: AppColors.orange500,
                    isDark: isDark,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

const _weekdayNames = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven'];
const _weekdayEmojis = ['😤', '🧡', '💪', '😌', '🎉'];

class _FunnyStatsCard extends StatelessWidget {
  final bool isDark;
  final Color textSub;
  final int mondayRate;
  final int bestWeekday;
  final int swTotal;
  final String? earliestStartTime;
  final int coffeeSent;
  final int coffeeReceived;
  final String? bestOtMonthLabel;
  final String? worstOtMonthLabel;

  const _FunnyStatsCard({
    required this.isDark,
    required this.textSub,
    required this.mondayRate,
    required this.bestWeekday,
    required this.swTotal,
    this.earliestStartTime,
    this.coffeeSent = 0,
    this.coffeeReceived = 0,
    this.bestOtMonthLabel,
    this.worstOtMonthLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.75);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.9);
    final wdName = _weekdayNames[bestWeekday.clamp(0, 4)];
    final wdEmoji = _weekdayEmojis[bestWeekday.clamp(0, 4)];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURIOSITÀ 🐢',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: textSub,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatPill(
                icon: '📅',
                label: 'Lunedì presentato',
                value: '$mondayRate%',
                color: mondayRate >= 80
                    ? AppColors.green600
                    : mondayRate >= 50
                    ? AppColors.orange500
                    : AppColors.red700,
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _StatPill(
                icon: wdEmoji,
                label: 'Giorno preferito',
                value: wdName,
                color: AppColors.purple600,
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _StatPill(
                icon: '🏠',
                label: 'Giorni SW',
                value: '$swTotal',
                color: AppColors.blue600,
                isDark: isDark,
              ),
            ],
          ),
          if (earliestStartTime != null || coffeeSent > 0 || coffeeReceived > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (earliestStartTime != null)
                  _StatPill(
                    icon: '🌅',
                    label: 'Entrata record',
                    value: earliestStartTime!,
                    color: AppColors.amber600,
                    isDark: isDark,
                  ),
                if (earliestStartTime != null &&
                    (coffeeSent > 0 || coffeeReceived > 0))
                  const SizedBox(width: 10),
                if (coffeeSent > 0 || coffeeReceived > 0)
                  _StatPill(
                    icon: '☕',
                    label: 'Caffè ↑ / ↓',
                    value: '$coffeeSent / $coffeeReceived',
                    color: AppColors.green600,
                    isDark: isDark,
                  ),
              ],
            ),
          ],
          if (bestOtMonthLabel != null && worstOtMonthLabel != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _StatPill(
                  icon: '🏆',
                  label: 'Mese più OT',
                  value: bestOtMonthLabel!,
                  color: AppColors.orange500,
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _StatPill(
                  icon: '🧘',
                  label: 'Mese meno OT',
                  value: worstOtMonthLabel!,
                  color: AppColors.blue600,
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: color.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
