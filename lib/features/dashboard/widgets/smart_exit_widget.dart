import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_strings.dart';
import '../presentation/timer_provider.dart';

class SmartExitWidget extends ConsumerWidget {
  const SmartExitWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the local timer state instead of Firestore streams
    final timerState = ref.watch(workTimerProvider);
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm');

    // CASE A: Not started -> Show Clock In Card
    if (timerState.status == WorkState.notStarted) {
      return _buildClockInCard(context, ref);
    }

    // CASE B: Shift in progress -> Show Timer Card
    final exitTime = timerState.expectedExitTime ?? DateTime.now();
    final exitTimeStr = timeFormat.format(exitTime);
    final remaining = timerState.remainingTime ?? Duration.zero;
    final minutesLeft = remaining.inMinutes;

    // Check if lunch was taken (minimum 30 mins)
    final mealVoucherEarned = timerState.totalLunchPauseMins >= 30;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.timer_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  AppStrings.yourDay,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (mealVoucherEarned)
                  _buildBadge(
                    theme,
                    AppStrings.pdfColBuono,
                    Icons.restaurant,
                    Colors.green,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Central Timer
            Center(
              child: Column(
                children: [
                  Text(
                    AppStrings.expectedExit,
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    exitTimeStr,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    minutesLeft > 0
                        ? AppStrings.timeUntilExit(
                            remaining.inHours,
                            remaining.inMinutes.remainder(60),
                          )
                        : AppStrings.youCanLeave,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: minutesLeft > 0
                          ? theme.colorScheme.secondary
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Visual Timeline (Placeholder)
            _buildTimeline(context, timerState),

            const SizedBox(height: 16),

            // Clock Out Button
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: () =>
                  _handleClockAction(context, ref, isClockIn: false),
              icon: const Icon(Icons.logout),
              label: const Text(AppStrings.clockOut),
            ),
          ],
        ),
      ),
    );
  }

  // Card for Clocking IN
  Widget _buildClockInCard(BuildContext context, WidgetRef ref) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.work_outline, size: 48),
            const SizedBox(height: 16),
            const Text(
              AppStrings.goodMorningEmoji,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(AppStrings.notClockedInYet),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    _handleClockAction(context, ref, isClockIn: true),
                icon: const Icon(Icons.login),
                label: const Text(AppStrings.startShift),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Handle Clocking In and Out routing through the WorkTimer provider
  void _handleClockAction(
    BuildContext context,
    WidgetRef ref, {
    required bool isClockIn,
  }) async {
    final notifier = ref.read(workTimerProvider.notifier);
    final now = DateTime.now();

    if (isClockIn) {
      notifier.startTurn(now); // Starts the timer locally
    } else {
      // endTurn handles the math and saves to Firestore via the repository!
      await notifier.endTurn(now);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.dayEndedSavedSuccess)),
        );
      }
    }
  }

  // Helper for UI Badges
  Widget _buildBadge(ThemeData theme, String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Placeholder for the visual timeline line
  Widget _buildTimeline(BuildContext context, TimerState state) {
    return Container(height: 4, color: Colors.grey[300]);
  }
}
