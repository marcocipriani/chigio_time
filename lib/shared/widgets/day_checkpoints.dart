import 'package:flutter/material.dart';
import '../../app/theme/color_schemes.dart';
import '../../core/constants/app_strings.dart';
import 'glass_card.dart';

class DayCheckpoints extends StatelessWidget {
  final int workedMins;
  final DateTime? startTime;
  final DateTime? endTime;
  final int lunchPauseMins;
  final int standardWorkMins;
  final int mealThresholdMins;

  const DayCheckpoints({
    super.key,
    required this.workedMins,
    required this.standardWorkMins,
    required this.mealThresholdMins,
    this.startTime,
    this.endTime,
    this.lunchPauseMins = 0,
  });

  String _fmt(int totalMins) {
    final h = totalMins ~/ 60;
    final m = (totalMins % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : AppColors.neutral400;
    final lineColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);

    final mealEarned = workedMins >= mealThresholdMins;
    final isOT = workedMins > standardWorkMins;
    final pausaDone = lunchPauseMins > 0;

    final entrataMin = startTime != null
        ? startTime!.hour * 60 + startTime!.minute
        : 9 * 60;
    final exitMin = endTime != null
        ? endTime!.hour * 60 + endTime!.minute
        : entrataMin + standardWorkMins;
    final mealMin = entrataMin + mealThresholdMins;

    final steps = [
      _Step(
        label: AppStrings.entrata,
        time: _fmt(entrataMin),
        done: true,
        color: AppColors.blue600,
      ),
      _Step(
        label: AppStrings.lunchPause,
        time: '30m',
        done: pausaDone,
        color: AppColors.red700,
      ),
      _Step(
        label: AppStrings.mealEarned,
        time: _fmt(mealMin),
        done: mealEarned,
        color: AppColors.green500,
      ),
      _Step(
        label: AppStrings.endShift,
        time: _fmt(exitMin),
        done: isOT || workedMins >= standardWorkMins,
        color: AppColors.blue600,
      ),
      _Step(
        label: AppStrings.overtimeFull,
        time: isOT ? '+${_fmtHM(workedMins - standardWorkMins)}' : '—',
        done: isOT,
        color: AppColors.orange500,
      ),
    ];

    return GlassTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.dayOverviewUpper,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textSub,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            final isLast = i == steps.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      clipBehavior: Clip.none,
                      children: [
                        // Connector line below
                        if (!isLast)
                          Positioned(
                            top: 20,
                            child: Container(
                              width: 2,
                              height: 16,
                              decoration: BoxDecoration(
                                color: s.done
                                    ? s.color.withValues(alpha: 0.4)
                                    : lineColor,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                        // Dot
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: s.done
                                ? s.color
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.05)),
                            boxShadow: s.done
                                ? [
                                    BoxShadow(
                                      color: s.color.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: s.done
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 11,
                                )
                              : Center(
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : Colors.black.withValues(
                                              alpha: 0.15,
                                            ),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: s.done
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: s.done ? textMain : textSub,
                          ),
                        ),
                        Text(
                          s.time,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: s.done ? s.color : textSub,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static String _fmtHM(int mins) {
    final m = mins.abs();
    final h = m ~/ 60;
    final rem = m % 60;
    if (h == 0) return '${rem}m';
    if (rem == 0) return '${h}h';
    return '${h}h ${rem.toString().padLeft(2, '0')}m';
  }
}

class _Step {
  final String label;
  final String time;
  final bool done;
  final Color color;

  const _Step({
    required this.label,
    required this.time,
    required this.done,
    required this.color,
  });
}
