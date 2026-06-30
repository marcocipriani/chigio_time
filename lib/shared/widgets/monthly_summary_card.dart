import 'package:flutter/material.dart';
import '../../app/theme/color_schemes.dart';
import '../../core/constants/app_strings.dart';

/// Collapsible monthly stats card with blue header.
///
/// Header shows Art.9 / SLI / SBO / OP / Ore perse (user-customizable).
/// Expanded section: Ore tot / Straord / Buoni + optional progress bars.
class MonthlySummaryCard extends StatefulWidget {
  static const defaultItems = ['art9', 'sli', 'sbo', 'op'];

  final int year;
  final int month;
  final int totalNetMins;
  final int totalOtMins;
  final int totalMeal;
  final int art9Mins;
  final int sliMins;
  final int sboMins;
  final int deficitMins;
  final int art9Cap;
  final int sliCap;
  final int sboCap;
  final int overtimeCap;
  final List<String> visibleItems;
  final bool showProgressBars;
  final int swCount;
  final int swYearCount;
  final VoidCallback? onPrevMonth;
  final VoidCallback? onNextMonth;
  final VoidCallback? onMonthTap;
  final VoidCallback? onEditTap;
  final bool showMonthNav;
  final bool initiallyExpanded;

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
    required this.deficitMins,
    required this.art9Cap,
    required this.sliCap,
    required this.sboCap,
    this.overtimeCap = 0,
    this.visibleItems = const ['art9', 'sli', 'sbo', 'op'],
    this.showProgressBars = true,
    this.swCount = 0,
    this.swYearCount = 0,
    this.onPrevMonth,
    this.onNextMonth,
    this.onMonthTap,
    this.onEditTap,
    this.showMonthNav = true,
    this.initiallyExpanded = false,
  });

  @override
  State<MonthlySummaryCard> createState() => _MonthlySummaryCardState();
}

class _MonthlySummaryCardState extends State<MonthlySummaryCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  static String _hm(int mins) {
    final h = mins.abs() ~/ 60;
    final m = mins.abs() % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  _BigStat _statForId(String id) => switch (id) {
    'art9' => _BigStat(
      label: AppStrings.art9Label,
      value: widget.art9Mins == 0 ? '—' : _hm(widget.art9Mins),
    ),
    'sli' => _BigStat(
      label: AppStrings.sliLabel,
      value: widget.sliMins == 0 ? '—' : _hm(widget.sliMins),
    ),
    'sbo' => _BigStat(
      label: AppStrings.sboLabel,
      value: widget.sboMins == 0 ? '—' : _hm(widget.sboMins),
    ),
    'op' => _BigStat(
      label: AppStrings.deficitLabel,
      value: widget.deficitMins == 0 ? '—' : _hm(widget.deficitMins),
      accent: widget.deficitMins > 0 ? const Color(0xFFFF9B9B) : null,
    ),
    _ => _BigStat(label: id, value: '—'),
  };

  Widget? _progressRowForId(String id, bool isDark) => switch (id) {
    'art9' => _ProgressRow(
      AppStrings.art9Label,
      widget.art9Mins,
      widget.art9Cap,
      AppColors.blue600,
      isDark,
    ),
    'sli' => _ProgressRow(
      AppStrings.sliLabel,
      widget.sliMins,
      widget.sliCap,
      AppColors.green600,
      isDark,
    ),
    'sbo' => _ProgressRow(
      AppStrings.sboLabel,
      widget.sboMins,
      widget.sboCap,
      AppColors.orange500,
      isDark,
    ),
    'op' =>
      widget.deficitMins > 0
          ? _ProgressRow(
              AppStrings.deficitLabel,
              widget.deficitMins,
              0,
              AppColors.red700,
              isDark,
            )
          : null,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blueHeader = isDark
        ? const Color(0xFF0055A5).withValues(alpha: 0.50)
        : const Color(0xFF0055A5).withValues(alpha: 0.88);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0a1628) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.75),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.28)
                : const Color(0xFF002878).withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Column(
          children: [
            // ── Blue header ─────────────────────────────────────────────
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                width: double.infinity,
                color: blueHeader,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  children: [
                    // Month nav row
                    if (widget.showMonthNav) ...[
                      Row(
                        children: [
                          _NavCircle(
                            icon: Icons.chevron_left_rounded,
                            onTap: widget.onPrevMonth,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: widget.onMonthTap,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${AppStrings.months[widget.month - 1]} ${widget.year}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  if (widget.swCount > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '🖥 ${widget.swCount} SW',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (widget.swYearCount > 0) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${widget.year}: ${widget.swYearCount} SW',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withValues(alpha: 0.85),
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (widget.onMonthTap != null) ...[
                                    const SizedBox(width: 3),
                                    Icon(
                                      Icons.expand_more_rounded,
                                      size: 14,
                                      color: Colors.white.withValues(
                                        alpha: 0.65,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          _NavCircle(
                            icon: Icons.chevron_right_rounded,
                            onTap: widget.onNextMonth,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Stats row: dynamic per user preference
                    Wrap(
                      alignment: WrapAlignment.spaceAround,
                      spacing: 12,
                      runSpacing: 8,
                      children: widget.visibleItems.map(_statForId).toList(),
                    ),

                    // Expand indicator
                    const SizedBox(height: 6),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 280),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.60),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Expandable detail ────────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: _expanded
                  ? Container(
                      width: double.infinity,
                      color: isDark ? const Color(0xFF0a1628) : Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Personalizza link — visible only when expanded
                          if (widget.onEditTap != null) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: widget.onEditTap,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.tune_rounded,
                                        size: 12,
                                        color: isDark
                                            ? AppColors.blue300
                                            : AppColors.blue600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppStrings.customise,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? AppColors.blue300
                                              : AppColors.blue600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],

                          // Secondary counters: Ore tot / Straord / Buoni
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _SecStat(
                                label: AppStrings.totalHours,
                                value: '${widget.totalNetMins ~/ 60}h',
                                isDark: isDark,
                              ),
                              _SecStat(
                                label: AppStrings.overtime,
                                value: widget.totalOtMins == 0
                                    ? '—'
                                    : _hm(widget.totalOtMins),
                                isDark: isDark,
                              ),
                              _SecStat(
                                label: AppStrings.mealVouchers,
                                value: '${widget.totalMeal} 🍽️',
                                isDark: isDark,
                              ),
                            ],
                          ),
                          if (widget.showProgressBars) ...[
                            const SizedBox(height: 14),
                            ...() {
                              final bars = widget.visibleItems
                                  .map((id) => _progressRowForId(id, isDark))
                                  .whereType<Widget>()
                                  .toList();
                              final out = <Widget>[];
                              for (var i = 0; i < bars.length; i++) {
                                out.add(bars[i]);
                                if (i < bars.length - 1) {
                                  out.add(const SizedBox(height: 9));
                                }
                              }
                              return out;
                            }(),
                          ],
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small nav circle button ───────────────────────────────────────────────────

class _NavCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _NavCircle({required this.icon, required this.onTap});

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
          color: Colors.white.withValues(alpha: 0.15),
        ),
        child: Icon(
          icon,
          size: 16,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

// ── Secondary stat (in expanded section) ─────────────────────────────────────

class _SecStat extends StatelessWidget {
  final String label, value;
  final bool isDark;
  const _SecStat({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral600;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textMain,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textSub,
          ),
        ),
      ],
    );
  }
}

// ── Header stat ───────────────────────────────────────────────────────────────

class _BigStat extends StatelessWidget {
  final String label, value;
  final Color? accent;
  const _BigStat({required this.label, required this.value, this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: accent ?? Colors.white,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.70),
          ),
        ),
      ],
    );
  }
}

// ── Progress row in expanded section ─────────────────────────────────────────

class _ProgressRow extends StatelessWidget {
  final String label;
  final int usedMins;
  final int capMins;
  final Color color;
  final bool isDark;

  const _ProgressRow(
    this.label,
    this.usedMins,
    this.capMins,
    this.color,
    this.isDark,
  );

  static String _hm(int m) {
    final h = m.abs() ~/ 60;
    final min = m.abs() % 60;
    return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final pct = capMins > 0 ? (usedMins / capMins).clamp(0.0, 1.0) : null;
    final sub = isDark
        ? Colors.white.withValues(alpha: 0.40)
        : AppColors.neutral400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: sub,
              ),
            ),
            const Spacer(),
            Text(
              capMins > 0
                  ? '${_hm(usedMins)} / ${capMins ~/ 60}h'
                  : _hm(usedMins),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        if (pct != null) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 3,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation(
                pct >= 1.0 ? AppColors.orange500 : color,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
