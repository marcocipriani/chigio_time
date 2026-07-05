import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/color_schemes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/chigio_quotes.dart';
import '../../../shared/widgets/app_tappable.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/home_widget_header.dart';
import '../../projects/data/pomodoro_repository.dart';

/// Widget Home "Pomodoro": timer in corso (countdown + progetto) oppure
/// avvio rapido con preset sull'ultimo progetto. Tap → /projects.
class PomodoroCard extends ConsumerStatefulWidget {
  const PomodoroCard({super.key});

  @override
  ConsumerState<PomodoroCard> createState() => _PomodoroCardState();
}

class _PomodoroCardState extends ConsumerState<PomodoroCard> {
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker(bool running) {
    if (running && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!running && _ticker != null) {
      _ticker!.cancel();
      _ticker = null;
    }
  }

  static String _mmss(int secs) {
    final s = secs < 0 ? 0 : secs;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeTimerStreamProvider).asData?.value;
    final projects = ref.watch(myProjectsStreamProvider).asData?.value ?? [];
    _syncTicker(active != null && !active.isPaused);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : AppColors.neutral600;

    return AppTappable(
      onTap: () => context.go('/projects'),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeWidgetHeader(
              pose: ChigioQuotes.timer,
              title: AppStrings.pomodoroWidgetTitle,
              accent: AppColors.red700,
              hasOpenLink: true,
              subtitle: active != null
                  ? active.projectName
                  : AppStrings.pomodoroStartQuick,
              trailing: active != null ? _phaseBadge(active) : null,
            ),
            const SizedBox(height: 12),
            if (active != null)
              _RunningTimer(active: active, mmss: _mmss, textSub: textSub)
            else if (projects.isEmpty)
              HomeWidgetEmpty(
                message: AppStrings.pomodoroNoProjects,
                ctaLabel: AppStrings.pomodoroGoToProjects,
                onCta: () => context.go('/projects'),
              )
            else
              Row(
                children: [
                  for (final preset in const [(f: 25, b: 5), (f: 45, b: 15)])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AppTappable(
                        onTap: () => ref
                            .read(pomodoroRepositoryProvider)
                            .startTimer(
                              ActivePomodoro(
                                projectId: projects.first.id,
                                projectName: projects.first.name,
                                focusMins: preset.f,
                                breakMins: preset.b,
                                startedAt: DateTime.now(),
                              ),
                            ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.red700.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.red700.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '🍅 ${preset.f}/${preset.b}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.red700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    projects.first.name,
                    style: TextStyle(fontSize: 11, color: textSub),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _phaseBadge(ActivePomodoro active) {
    final label = active.isPaused
        ? AppStrings.pomodoroPaused
        : active.onBreak
        ? AppStrings.pomodoroOnBreak
        : AppStrings.pomodoroFocus;
    final color = active.isPaused
        ? AppColors.orange600
        : active.onBreak
        ? AppColors.green600
        : AppColors.red700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }
}

class _RunningTimer extends StatelessWidget {
  final ActivePomodoro active;
  final String Function(int) mmss;
  final Color textSub;

  const _RunningTimer({
    required this.active,
    required this.mmss,
    required this.textSub,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final remaining = active.remainingSecs(now);
    final progress = (active.elapsedSecs(now) / active.phaseSecs).clamp(
      0.0,
      1.0,
    );
    final color = active.onBreak ? AppColors.green600 : AppColors.red700;

    return Row(
      children: [
        Text(
          mmss(remaining),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
        ),
      ],
    );
  }
}
