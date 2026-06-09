import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import 'timer_provider.dart';
import 'totalizzatori_provider.dart';
import 'personal_absence_consumption_provider.dart';
import '../../../core/services/geofencing_service.dart';
import '../../../core/services/chigio_phrase_engine.dart';
import '../../timesheet/data/timesheet_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/glass_header.dart';
import '../../../shared/widgets/shift_ring.dart';
import '../../../shared/widgets/day_checkpoints.dart';
import '../../../app/theme/color_schemes.dart';
import 'custom_counters_provider.dart';
import '../domain/custom_counter.dart';
import '../widgets/favorite_colleagues_card.dart';
import '../widgets/pcm_route_planner_card.dart';
import '../widgets/totalizzatori_section.dart';
import '../../profile/presentation/profile_screen.dart' show showPortaleEdit;
import '../../timesheet/domain/daily_timesheet.dart' show BoeSlot;

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const int _stdMins = AppConstants.stdDailyMinsRuolo;
  static const int _mealMins = AppConstants.defaultMealVoucherThresholdMins;

  String _p2(int n) => n.abs().toString().padLeft(2, '0');

  String _fmtHHMM(int totalSecs) {
    final h = totalSecs ~/ 3600;
    final m = (totalSecs % 3600) ~/ 60;
    return '${_p2(h)}:${_p2(m)}';
  }

  String _fmtHM(int mins) {
    final m = mins.abs();
    final h = m ~/ 60;
    final rem = m % 60;
    if (h == 0) return '${rem}m';
    if (rem == 0) return '${h}h';
    return '${h}h ${_p2(rem)}m';
  }

  Future<DateTime?> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: AppStrings.confirmActualTimeHelp,
    );
    if (picked != null) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Exit reminder — shows once when remaining time crosses the 15-min threshold.
    ref.listen<TimerState>(workTimerProvider, (prev, next) {
      if (next.exitReminderPending && !(prev?.exitReminderPending ?? false)) {
        final mins = next.remainingTime?.inMinutes ?? 15;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('⏰', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppStrings.exitReminderBody(mins.clamp(1, 60)),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.orange600,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    });

    final state = ref.watch(workTimerProvider);
    final notifier = ref.read(workTimerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.92)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : AppColors.neutral400;

    // ── Monthly stats from Firestore ─────────────────────
    final now2 = DateTime.now();
    final monthlyAsync = ref.watch(
      monthlyTimesheetsProvider((year: now2.year, month: now2.month)),
    );
    final profileData = ref.watch(userProfileStreamProvider).asData?.value;
    final totData = ref.watch(totalizzatoriProvider);
    final absenceConsumption = ref
        .watch(personalAbsenceConsumptionProvider)
        .asData
        ?.value;
    final entries = monthlyAsync.asData?.value ?? [];

    // ── Today's shift auto-detection ─────────────────────
    // After an app restart the timer is in notStarted state, but today's
    // shift might already be saved in Firestore. Detect and show it.
    final todayId =
        '${now2.year}-'
        '${now2.month.toString().padLeft(2, '0')}-'
        '${now2.day.toString().padLeft(2, '0')}';
    final todayMatches = entries.where((e) => e.dateId == todayId);
    final todayEntry = todayMatches.isEmpty ? null : todayMatches.first;

    // Raw timer flags
    final isWorking = state.status == WorkState.working;
    final isPaused = state.status == WorkState.paused;
    final rawCompleted = state.status == WorkState.completed;
    final rawNotStarted = state.status == WorkState.notStarted;
    final isAbandoned = state.isAbandoned;

    // Effective flags — merge in-memory timer with today's Firestore entry
    // so the app shows the right state after a restart mid/post shift.
    final showTodayCompleted = rawNotStarted && todayEntry != null;
    final isCompleted = rawCompleted || showTodayCompleted;
    final isNotStarted = rawNotStarted && !showTodayCompleted;
    // "active" = shift started and not yet saved
    final isActive = isWorking || isPaused;
    // "started" = any non-idle state (including abandoned — has start time)
    final isStarted = isActive || isCompleted || isAbandoned;

    // Effective last shift — prefer in-memory, fall back to Firestore today
    final effectiveShift = state.lastCompletedShift ?? todayEntry;

    // Compute worked minutes
    int workedMins;
    if (isCompleted) {
      workedMins = effectiveShift?.netWorkedMins ?? 0;
    } else if (isAbandoned && state.startTime != null) {
      // Cap elapsed at 21:00 so the ring doesn't keep growing after abandon
      final start = state.startTime!;
      final cutoff = DateTime(start.year, start.month, start.day, 21, 0);
      final ref2 = state.currentTime.isBefore(cutoff)
          ? state.currentTime
          : cutoff;
      final elapsed = ref2.difference(start).inMinutes;
      final pauseMins =
          state.totalStandardPauseMins + state.totalLunchPauseMins;
      workedMins = (elapsed - pauseMins).clamp(0, 9999);
    } else if (state.startTime != null) {
      final elapsed = state.currentTime.difference(state.startTime!).inMinutes;
      final pauseMins =
          state.totalStandardPauseMins + state.totalLunchPauseMins;
      workedMins = (elapsed - pauseMins).clamp(0, 9999);
    } else {
      workedMins = 0;
    }

    // Use profile-driven stdMins for all calculations
    final stdMins = state.standardWorkMins;
    final mealMins = (stdMins * (_mealMins / _stdMins)).round(); // proportional
    final workedSecs = workedMins * 60;
    final mealEarned = workedMins >= mealMins;
    final isOT = workedMins > stdMins;
    final otMins = isOT ? workedMins - stdMins : 0;
    final remainMins = isOT ? 0 : (stdMins - workedMins);

    // Expected exit time string
    final exit = state.expectedExitTime;
    final exitStr = exit != null
        ? '${_p2(exit.hour)}:${_p2(exit.minute)}'
        : '--:--';

    // Today's date string
    final now = state.currentTime;
    final dateStr = _italianDate(now);

    // ── Ring center ──────────────────────────────────────
    Widget ringCenter;
    if (isAbandoned) {
      ringCenter = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 4),
          Text(
            _fmtHHMM(workedSecs),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.orange600,
              letterSpacing: -1.2,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            AppStrings.abandonedTitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.orange600,
            ),
          ),
        ],
      );
    } else if (isNotStarted) {
      ringCenter = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/app_icon.png',
            width: 68,
            height: 68,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.access_time_rounded,
              size: 56,
              color: AppColors.blue600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.statusNotStarted,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textSub,
            ),
          ),
        ],
      );
    } else if (isCompleted) {
      ringCenter = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _fmtHHMM(workedSecs),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppColors.green600,
              letterSpacing: -1.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            AppStrings.hoursWorked,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.green500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.green500.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              AppStrings.statusCompleted,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.green600,
              ),
            ),
          ),
        ],
      );
    } else if (isOT) {
      ringCenter = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.overtimeUpper,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.orange500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '+${_fmtHHMM(otMins * 60)}',
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: AppColors.orange600,
              letterSpacing: -1.5,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          if (mealEarned) ...[const SizedBox(height: 8), _MealBadge()],
        ],
      );
    } else {
      ringCenter = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _fmtHHMM(workedSecs),
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: textMain,
              letterSpacing: -1.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            AppStrings.hoursWorked,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textSub,
            ),
          ),
          const SizedBox(height: 8),
          if (mealEarned)
            _MealBadge()
          else
            _MealProgress(pct: workedMins / _mealMins, isDark: isDark),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            const GlassHeader(chigioPage: ChigioPage.dashboard),
            Expanded(
              child: LayoutBuilder(
                builder: (_, cs) {
                  final isDesktop = cs.maxWidth >= 800.0;

                  final heroCard = GlassCard(
                    radius: 32,
                    child: Column(
                      children: [
                        // Card header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: AppColors.blue600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textSub,
                                  ),
                                ),
                              ],
                            ),
                            if (isWorking)
                              _LiveBadge()
                            else if (isPaused)
                              _PauseBadge(isDark: isDark)
                            else if (isAbandoned)
                              const _AbandonedBadge()
                            else if (isCompleted)
                              _CompletedBadge(),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Ring
                        Center(
                          child: ShiftRing(
                            workedMins: workedMins,
                            size: 200,
                            child: ringCenter,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Metrics row (hidden when not started)
                        if (isStarted) ...[
                          Row(
                            children: [
                              Expanded(
                                child: GlassTile(
                                  // Green tint when completed
                                  overrideColor: isCompleted
                                      ? (isDark
                                            ? AppColors.green700.withValues(
                                                alpha: 0.25,
                                              )
                                            : AppColors.green500.withValues(
                                                alpha: 0.1,
                                              ))
                                      : null,
                                  overrideBorder: isCompleted
                                      ? Border.all(color: AppColors.green100)
                                      : null,
                                  child: Column(
                                    children: [
                                      Text(
                                        isCompleted
                                            ? AppStrings.actualExit
                                            : AppStrings.expectedExit,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: textSub,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isCompleted && effectiveShift != null
                                            ? '${_p2(effectiveShift.endTime.hour)}:${_p2(effectiveShift.endTime.minute)}'
                                            : exitStr,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: isCompleted
                                              ? AppColors.green600
                                              : (isDark
                                                    ? AppColors.blue300
                                                    : AppColors.blue600),
                                          letterSpacing: -0.5,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GlassTile(
                                  overrideColor: isOT
                                      ? (isDark
                                            ? AppColors.orange600.withValues(
                                                alpha: 0.18,
                                              )
                                            : AppColors.orange500.withValues(
                                                alpha: 0.12,
                                              ))
                                      : null,
                                  overrideBorder: isOT
                                      ? Border.all(
                                          color: AppColors.orange100,
                                          width: 1,
                                        )
                                      : null,
                                  child: Column(
                                    children: [
                                      Text(
                                        isCompleted
                                            ? AppStrings.lavorato
                                            : isOT
                                            ? AppStrings.pdfSummaryStraordinario
                                            : AppStrings.remaining,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: textSub,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isCompleted
                                            ? _fmtHHMM(workedSecs)
                                            : isOT
                                            ? '+${_fmtHM(otMins)}'
                                            : _fmtHM(remainMins),
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: isCompleted
                                              ? AppColors.green600
                                              : isOT
                                              ? AppColors.orange600
                                              : textMain,
                                          letterSpacing: -0.5,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (isActive && state.startTime != null) ...[
                            _NineHourBanner(
                              state: state,
                              workedMins: workedMins,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],

                        // Pause buttons (when working)
                        if (isWorking) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _PauseChip(
                                icon: '🍽️',
                                label: AppStrings.lunchChip,
                                onTap: () async {
                                  final t = await _pickTime(context);
                                  if (t != null) {
                                    notifier.startPause(PauseType.lunch, t);
                                  }
                                },
                              ),
                              _PauseChip(
                                icon: '☕',
                                label: AppStrings.breakChip,
                                onTap: () async {
                                  final t = await _pickTime(context);
                                  if (t != null) {
                                    notifier.startPause(PauseType.short, t);
                                  }
                                },
                              ),
                              _PauseChip(
                                icon: '🚶',
                                label: AppStrings.wtLeave,
                                onTap: () async {
                                  final t = await _pickTime(context);
                                  if (t != null) {
                                    notifier.startPause(PauseType.leave, t);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Resume button (when paused)
                        if (isPaused) ...[
                          GlassBtn(
                            label: AppStrings.resume,
                            onPressed: () async {
                              final t = await _pickTime(context);
                              if (t != null) notifier.endPause(t);
                            },
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Main CTA
                        if (isAbandoned)
                          _AbandonedCta(
                            onClockOut: () async {
                              final t = await _pickTime(context);
                              if (t != null) {
                                try {
                                  await notifier.endTurnFromAbandoned(t);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppStrings.errorGeneric(e),
                                        ),
                                        backgroundColor: AppColors.red700,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            onDismiss: notifier.dismissAbandoned,
                          )
                        else if (isNotStarted)
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: GlassBtn(
                                    label: AppStrings.clockIn,
                                    icon: const Icon(
                                      Icons.play_circle_outline_rounded,
                                      size: 18,
                                    ),
                                    onPressed: () async {
                                      final t = await _pickTime(context);
                                      if (t != null) notifier.startTurn(t);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _SmartWorkingBtn(
                                  stdMins: state.standardWorkMins,
                                ),
                              ],
                            ),
                          )
                        else if (isActive)
                          GlassBtn(
                            label: AppStrings.clockOut,
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            onPressed: () async {
                              final t = await _pickTime(context);
                              if (t == null || !context.mounted) return;

                              final deficit = notifier.previewDeficit(t);
                              int bancaOreMins = 0;
                              String? boeSlot;

                              if (deficit > 0) {
                                final apAvail = totData?.bancaOreApResiduo ?? 0;
                                final acAvail = totData?.bancaOreAcResiduo ?? 0;
                                if ((apAvail + acAvail) > 0 &&
                                    context.mounted) {
                                  final result =
                                      await showModalBottomSheet<
                                        ({int mins, String slot})
                                      >(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => _BoeSheet(
                                          deficitMins: deficit,
                                          apAvailMins: apAvail,
                                          acAvailMins: acAvail,
                                          hasLunchPause:
                                              state.totalLunchPauseMins > 0,
                                          hasShortPause:
                                              state.totalStandardPauseMins > 0,
                                        ),
                                      );
                                  if (result != null) {
                                    bancaOreMins = result.mins;
                                    boeSlot = result.slot;
                                  }
                                }
                              }

                              if (!context.mounted) return;
                              try {
                                await notifier.endTurn(
                                  t,
                                  bancaOreMins: bancaOreMins,
                                  boeSlot: boeSlot,
                                );
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppStrings.errorGeneric(e)),
                                      backgroundColor: AppColors.red700,
                                    ),
                                  );
                                }
                              }
                            },
                          )
                        else // isCompleted
                          Column(
                            children: [
                              Text(
                                AppStrings.ottimoLavoro,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.green600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              GlassBtn(
                                label: AppStrings.newDay,
                                variant: GlassBtnVariant.secondary,
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 16,
                                ),
                                onPressed: () =>
                                    notifier.startTurn(DateTime.now()),
                              ),
                            ],
                          ),
                        // GPS auto clock-in prompt (shown only when shift not started)
                        if (isNotStarted) ...[
                          _GpsPromptCard(
                            profileData: profileData,
                            isDark: isDark,
                            onClockIn: () => notifier.startTurn(DateTime.now()),
                          ),
                        ],
                        // Tabella orari reference link
                        const SizedBox(height: 4),
                        Center(
                          child: TextButton.icon(
                            onPressed: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const _OrariTableSheet(),
                            ),
                            icon: Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: textSub,
                            ),
                            label: Text(
                              AppStrings.hoursTable,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: textSub,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  final statsSection = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Alert banner (portal) ─────────────────────────
                      if (totData != null &&
                          totData.activeAlerts.isNotEmpty) ...[
                        TotAlertBanner(alerts: totData.activeAlerts),
                        const SizedBox(height: 11),
                      ],

                      // ── Colleghi preferiti (quick-access) ────────────
                      const FavoriteColleaguesCard(),
                      const SizedBox(height: 11),

                      // ── Maggior presenza widget (self-contained, month-switchable)
                      const _MaggiorPresenzaCard(),

                      // ── Contatori custom (compact strip) ─────────────
                      const _HomeCountersRow(),
                      const SizedBox(height: 11),


                      // ── Banca ore highlight ───────────────────────────
                      if (totData != null) ...[
                        BancaOreTile(data: totData),
                        const SizedBox(height: 11),
                      ],

                      // ── Totalizzatori portale (all categories) ────────
                      if (totData != null) ...[
                        const SizedBox(height: 7),
                        TotalizzatoriSection(
                          data: totData,
                          consumption: absenceConsumption,
                          onEdit: () =>
                              showPortaleEdit(context, ref, profileData ?? {}),
                          onChipEdit: (updates) async {
                            final raw = (profileData ?? {})['portaleJson'];
                            final map = raw is Map
                                ? Map<String, dynamic>.from(raw)
                                : <String, dynamic>{};
                            map.addAll(updates);
                            await ref
                                .read(profileRepositoryProvider)
                                .savePortaleData(map);
                          },
                        ),
                        const SizedBox(height: 4),
                        const CustomCountersSection(),
                        const SizedBox(height: 4),
                      ],
                      const SizedBox(height: 11),
                      const PcmRoutePlannerCard(),
                    ],
                  );

                  final noteSection = isCompleted
                      ? _NoteSection(
                          dateId: todayId,
                          initialNote: todayEntry?.note,
                        )
                      : null;

                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                heroCard,
                                if (isStarted) ...[
                                  const SizedBox(height: 11),
                                  DayCheckpoints(
                                    workedMins: workedMins,
                                    startTime: effectiveShift?.startTime ?? state.startTime,
                                    endTime: isCompleted ? effectiveShift?.endTime : null,
                                    lunchPauseMins: isCompleted
                                        ? (effectiveShift?.lunchPauseMins ?? 0)
                                        : state.totalLunchPauseMins,
                                    standardWorkMins: stdMins,
                                    mealThresholdMins: mealMins,
                                  ),
                                ],
                                if (noteSection != null) ...[
                                  const SizedBox(height: 11),
                                  noteSection,
                                ],
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                            child: statsSection,
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    children: [
                      heroCard,
                      const SizedBox(height: 11),
                      if (isStarted) ...[
                        DayCheckpoints(
                          workedMins: workedMins,
                          startTime: effectiveShift?.startTime ?? state.startTime,
                          endTime: isCompleted ? effectiveShift?.endTime : null,
                          lunchPauseMins: isCompleted
                              ? (effectiveShift?.lunchPauseMins ?? 0)
                              : state.totalLunchPauseMins,
                          standardWorkMins: stdMins,
                          mealThresholdMins: mealMins,
                        ),
                        const SizedBox(height: 11),
                      ],
                      if (noteSection != null) ...[
                        noteSection,
                        const SizedBox(height: 11),
                      ],
                      statsSection,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _italianDate(DateTime d) {
    final dayName = AppStrings.weekdaysFull[d.weekday - 1];
    final monthName = AppStrings.months[d.month - 1].toLowerCase();
    return '$dayName ${d.day} $monthName';
  }
}

// ── Maggior Presenza widget ────────────────────────────────────────────────

class _MaggiorPresenzaCard extends ConsumerStatefulWidget {
  const _MaggiorPresenzaCard();

  @override
  ConsumerState<_MaggiorPresenzaCard> createState() =>
      _MaggiorPresenzaCardState();
}

class _MaggiorPresenzaCardState extends ConsumerState<_MaggiorPresenzaCard> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _prevMonth() => setState(() {
    if (_month == 1) {
      _month = 12;
      _year--;
    } else {
      _month--;
    }
  });

  void _nextMonth() => setState(() {
    if (_month == 12) {
      _month = 1;
      _year++;
    } else {
      _month++;
    }
  });

  static String _hm(int mins) {
    if (mins == 0) return '0h';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  static const _monthsShort = AppStrings.monthsShort;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral400;

    final profileData = ref.watch(userProfileStreamProvider).asData?.value;
    final art9CapMins = (profileData?['monthlyArt9Hours'] as int? ?? 0) * 60;
    final sliCapMins = (profileData?['monthlySliHours'] as int? ?? 0) * 60;
    final sboCapMins = (profileData?['monthlySboHours'] as int? ?? 0) * 60;

    final entries =
        ref
            .watch(monthlyTimesheetsProvider((year: _year, month: _month)))
            .asData
            ?.value ??
        [];

    final totalOtMins = entries.fold<int>(
      0,
      (s, e) => s + (e.extraMins > 0 ? e.extraMins : 0),
    );

    final art9Alloc = totalOtMins.clamp(0, art9CapMins);
    final sliAlloc = (totalOtMins - art9CapMins).clamp(0, sliCapMins);
    final sboAlloc = (totalOtMins - art9CapMins - sliCapMins).clamp(
      0,
      sboCapMins,
    );
    final opeAlloc = (totalOtMins - art9CapMins - sliCapMins - sboCapMins)
        .clamp(0, 99999);
    final totalCap = art9CapMins + sliCapMins + sboCapMins;

    if (totalOtMins == 0 && totalCap == 0) return const SizedBox.shrink();

    final hasOpe = opeAlloc > 0;
    final pct = totalCap > 0
        ? (totalOtMins / totalCap * 100).clamp(0, 999).round()
        : null;

    final now = DateTime.now();
    final isCurrentMonth = _year == now.year && _month == now.month;
    final monthLabel = '${_monthsShort[_month - 1]} $_year';

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────
            Row(
              children: [
                const Text('📊', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Text(
                  AppStrings.greaterAttendance(AppStrings.maggiorPresenza),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: AppColors.blue600,
                  ),
                ),
                const SizedBox(width: 8),
                // Month navigator
                GestureDetector(
                  onTap: _prevMonth,
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 16,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppColors.neutral400,
                  ),
                ),
                Text(
                  monthLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isCurrentMonth
                        ? AppColors.blue600.withValues(alpha: 0.8)
                        : textSub,
                  ),
                ),
                GestureDetector(
                  onTap: _nextMonth,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppColors.neutral400,
                  ),
                ),
                const Spacer(),
                Text(
                  _hm(totalOtMins),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: hasOpe ? AppColors.red700 : AppColors.blue600,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (hasOpe ? AppColors.red700 : AppColors.blue600)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    hasOpe ? '+${_hm(opeAlloc)} OPE' : '${pct ?? 0}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: hasOpe ? AppColors.red700 : AppColors.blue600,
                    ),
                  ),
                ),
              ],
            ),

            // ── Segmented bar with threshold markers ─────────────────────
            if (totalCap > 0) ...[
              const SizedBox(height: 10),
              _SegmentedBarThresholds(
                art9Cap: art9CapMins,
                art9Alloc: art9Alloc,
                sliCap: sliCapMins,
                sliAlloc: sliAlloc,
                sboCap: sboCapMins,
                sboAlloc: sboAlloc,
                totalCap: totalCap,
                isDark: isDark,
              ),
              const SizedBox(height: 4),
              // Proportional labels aligned to segments
              Row(
                children: [
                  if (art9CapMins > 0)
                    Flexible(
                      flex: art9CapMins,
                      child: Text(
                        AppStrings.art9Label,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue600,
                        ),
                      ),
                    ),
                  if (sliCapMins > 0)
                    Flexible(
                      flex: sliCapMins,
                      child: Center(
                        child: Text(
                          AppStrings.sliLabel,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.green600,
                          ),
                        ),
                      ),
                    ),
                  if (sboCapMins > 0)
                    Flexible(
                      flex: sboCapMins,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          AppStrings.sboLabel,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.orange500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],

            // ── Breakdown chips ──────────────────────────────────────────
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (art9CapMins > 0)
                  _PresenzaChip(
                    label: AppStrings.art9Label,
                    value: _hm(art9Alloc),
                    cap: _hm(art9CapMins),
                    color: AppColors.blue600,
                    isDark: isDark,
                  ),
                if (sliCapMins > 0)
                  _PresenzaChip(
                    label: AppStrings.sliLabel,
                    value: _hm(sliAlloc),
                    cap: _hm(sliCapMins),
                    color: AppColors.green600,
                    isDark: isDark,
                  ),
                if (sboCapMins > 0)
                  _PresenzaChip(
                    label: AppStrings.sboLabel,
                    value: _hm(sboAlloc),
                    cap: _hm(sboCapMins),
                    color: AppColors.orange500,
                    isDark: isDark,
                  ),
                if (hasOpe || totalCap > 0)
                  _PresenzaChip(
                    label: AppStrings.opeLabel,
                    value: _hm(opeAlloc),
                    cap: null,
                    color: hasOpe ? AppColors.red700 : AppColors.neutral400,
                    isDark: isDark,
                  ),
                if (!hasOpe && totalCap == 0)
                  Text(
                    _hm(totalOtMins),
                    style: TextStyle(fontSize: 11, color: textSub),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Segmented bar with threshold dividers ─────────────────────────────────────

class _SegmentedBarThresholds extends StatelessWidget {
  final int art9Cap, art9Alloc, sliCap, sliAlloc, sboCap, sboAlloc, totalCap;
  final bool isDark;

  const _SegmentedBarThresholds({
    required this.art9Cap,
    required this.art9Alloc,
    required this.sliCap,
    required this.sliAlloc,
    required this.sboCap,
    required this.sboAlloc,
    required this.totalCap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final emptyColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.07);
    final dividerColor = isDark
        ? Colors.black.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.8);

    final segments = [
      (cap: art9Cap, alloc: art9Alloc, color: AppColors.blue600),
      (cap: sliCap, alloc: sliAlloc, color: AppColors.green600),
      (cap: sboCap, alloc: sboAlloc, color: AppColors.orange500),
    ].where((s) => s.cap > 0).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 12,
        child: Row(
          children: [
            for (int i = 0; i < segments.length; i++) ...[
              Flexible(
                flex: (segments[i].cap * 1000 ~/ totalCap),
                child: Stack(
                  children: [
                    // Filled + empty portions
                    Row(
                      children: [
                        if (segments[i].alloc > 0)
                          Flexible(
                            flex: (segments[i].alloc * 1000 ~/ segments[i].cap),
                            child: Container(color: segments[i].color),
                          ),
                        if (segments[i].alloc < segments[i].cap)
                          Flexible(
                            flex:
                                ((segments[i].cap - segments[i].alloc) *
                                1000 ~/
                                segments[i].cap),
                            child: Container(color: emptyColor),
                          ),
                      ],
                    ),
                    // Threshold divider on right edge (except last segment)
                    if (i < segments.length - 1)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(width: 2, color: dividerColor),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PresenzaChip extends StatelessWidget {
  final String label, value;
  final String? cap;
  final Color color;
  final bool isDark;

  const _PresenzaChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    this.cap,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : AppColors.neutral400;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: textMain,
            ),
          ),
          if (cap != null) ...[
            Text(' / $cap', style: TextStyle(fontSize: 9, color: textSub)),
          ],
        ],
      ),
    );
  }
}

// ── Supporting widgets ─────────────────────────────────────────────────

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.green500,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          AppStrings.statusLive,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.green500,
          ),
        ),
      ],
    );
  }
}

class _PauseBadge extends StatelessWidget {
  final bool isDark;
  const _PauseBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.orange500.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Text(
        AppStrings.statusInPausa,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.orange500,
        ),
      ),
    );
  }
}

class _CompletedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.green500.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Text(
        AppStrings.statusDoneUpper,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.green600,
        ),
      ),
    );
  }
}

class _MealBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.green500.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        AppStrings.mealEarnedFull,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.green600,
        ),
      ),
    );
  }
}

class _MealProgress extends StatelessWidget {
  final double pct;
  final bool isDark;
  const _MealProgress({required this.pct, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            width: 60,
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.07),
              valueColor: const AlwaysStoppedAnimation(AppColors.blue400),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '🍽️ ${(pct * 100).round()}%',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: isDark
                ? Colors.white.withValues(alpha: 0.4)
                : AppColors.neutral400,
          ),
        ),
      ],
    );
  }
}

class _PauseChip extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _PauseChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.75)
                    : AppColors.neutral700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small secondary button — registers today as a smart-working day
/// (full standard hours + automatic meal voucher, no timer needed).
class _SmartWorkingBtn extends ConsumerStatefulWidget {
  final int stdMins;
  const _SmartWorkingBtn({required this.stdMins});

  @override
  ConsumerState<_SmartWorkingBtn> createState() => _SmartWorkingBtnState();
}

class _SmartWorkingBtnState extends ConsumerState<_SmartWorkingBtn> {
  bool _loading = false;

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(timesheetRepositoryProvider)
          .saveRemoteWorkDay(stdMins: widget.stdMins);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.remoteRegistered),
            backgroundColor: AppColors.green600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.errorGeneric(e)),
            backgroundColor: AppColors.red700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    return GestureDetector(
      onTap: _loading ? null : _save,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.blue400,
                ),
              )
            else
              Icon(
                Icons.laptop_rounded,
                size: 18,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.75)
                    : AppColors.neutral700,
              ),
            const SizedBox(width: 6),
            Text(
              isWide ? AppStrings.smartWorkingFull : AppStrings.swShort,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.75)
                    : AppColors.neutral700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Note attività ──────────────────────────────────────────────────────

class _NoteSection extends ConsumerStatefulWidget {
  final String dateId;
  final String? initialNote;

  const _NoteSection({required this.dateId, this.initialNote});

  @override
  ConsumerState<_NoteSection> createState() => _NoteSectionState();
}

class _NoteSectionState extends ConsumerState<_NoteSection> {
  late TextEditingController _ctrl;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saved = false;
    });
    try {
      await ref
          .read(timesheetRepositoryProvider)
          .saveNote(widget.dateId, _ctrl.text);
      if (mounted) setState(() => _saved = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : AppColors.neutral400;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📝', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                AppStrings.noteLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textMain,
                ),
              ),
              const Spacer(),
              if (_saved)
                Text(
                  AppStrings.saved,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.green600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.7),
              ),
            ),
            child: TextField(
              controller: _ctrl,
              maxLines: 3,
              maxLength: 500,
              scrollPadding: const EdgeInsets.only(bottom: 220),
              style: TextStyle(fontSize: 13, color: textMain),
              decoration: InputDecoration(
                hintText: AppStrings.notePlaceholder,
                hintStyle: TextStyle(fontSize: 13, color: textSub),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
                counterText: '',
              ),
              onChanged: (_) {
                if (_saved) setState(() => _saved = false);
              },
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: _saving
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xE60055A5), Color(0xF2003D8F)],
                        ),
                  color: _saving
                      ? (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.06))
                      : null,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.blue400,
                        ),
                      )
                    : const Text(
                        AppStrings.save,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Abandoned badge ────────────────────────────────────────────────────────

class _AbandonedBadge extends StatelessWidget {
  const _AbandonedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.orange500.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Text(
        AppStrings.abandonedBadge,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.orange600,
        ),
      ),
    );
  }
}

// ── Abandoned CTA card ─────────────────────────────────────────────────────

class _AbandonedCta extends StatelessWidget {
  final VoidCallback onClockOut;
  final VoidCallback onDismiss;

  const _AbandonedCta({required this.onClockOut, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.orange600.withValues(alpha: 0.12)
            : AppColors.orange50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orange500.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: AppColors.orange600,
              ),
              const SizedBox(width: 6),
              const Text(
                AppStrings.abandonedTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.orange600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            AppStrings.abandonedBody,
            style: TextStyle(fontSize: 11, color: AppColors.orange600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GlassBtn(
                  label: AppStrings.registerExit,
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  onPressed: onClockOut,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDismiss,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: const Text(
                    AppStrings.dismissDay,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 9h milestone banner ────────────────────────────────────────────────────

class _NineHourBanner extends StatelessWidget {
  final TimerState state;
  final int workedMins;
  final bool isDark;

  const _NineHourBanner({
    required this.state,
    required this.workedMins,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final sub = isDark ? Colors.white60 : Colors.black45;

    // effectiveElapsed = elapsed excluding standard/leave pauses (includes lunch taken).
    // 3-zone rule (CCNL PCM):
    //   zone 1 < 540 min : no forced lunch
    //   zone 2 540–569   : forced lunch = effectiveElapsed − 540
    //   zone 3 ≥ 570     : forced lunch = 30 min
    final effectiveElapsed = state.startTime != null
        ? state.currentTime.difference(state.startTime!).inMinutes -
            state.totalStandardPauseMins -
            state.totalLeavePauseMins
        : 0;

    int forcedLunch = 0;
    if (effectiveElapsed >= 570) {
      forcedLunch = 30;
    } else if (effectiveElapsed >= 540) {
      forcedLunch = effectiveElapsed - 540;
    }
    final lunchDeficit = (forcedLunch - state.totalLunchPauseMins).clamp(0, 30);

    if (lunchDeficit > 0) {
      final col = isDark ? AppColors.orange300 : AppColors.orange700;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.orange500.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.orange500.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline_rounded, size: 14, color: col),
            const SizedBox(width: 6),
            Text(
              AppStrings.lunchVirtualBanner(lunchDeficit),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: col,
              ),
            ),
          ],
        ),
      );
    }

    if (effectiveElapsed < 540 && state.startTime != null) {
      final nineAt = state.startTime!.add(
        Duration(
          minutes:
              540 +
              state.totalStandardPauseMins +
              state.totalLeavePauseMins +
              state.totalLunchPauseMins,
        ),
      );
      final h = nineAt.hour.toString().padLeft(2, '0');
      final m = nineAt.minute.toString().padLeft(2, '0');
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, size: 13, color: sub),
          const SizedBox(width: 4),
          Text(
            AppStrings.nineHourThreshold('$h:$m'),
            style: TextStyle(
              fontSize: 11,
              color: sub,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

// ── Tabella orari bottom sheet ─────────────────────────────────────────────

class _OrariTableSheet extends StatefulWidget {
  const _OrariTableSheet();

  @override
  State<_OrariTableSheet> createState() => _OrariTableSheetState();
}

class _OrariTableSheetState extends State<_OrariTableSheet> {
  int _mode = 0;

  static const _modes = [
    (label: '6:12', shiftMins: 372),
    (label: '6:40', shiftMins: 400),
    (label: '7:36', shiftMins: 456),
  ];

  static const _limit = 21 * 60;

  List<(int entry, int stdExit, int? nine, int? nine30)> _rows(int shiftMins) {
    final out = <(int, int, int?, int?)>[];
    for (var e = 7 * 60 + 30; e + shiftMins <= _limit; e += 15) {
      final nine = e + 540;
      final nine30 = e + 570;
      out.add((
        e,
        e + shiftMins,
        nine <= _limit ? nine : null,
        nine30 <= _limit ? nine30 : null,
      ));
    }
    return out;
  }

  static String _t(int mins) =>
      '${(mins ~/ 60).toString().padLeft(2, '0')}:${(mins % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1C1C2E) : Colors.white;
    final textMain = isDark ? Colors.white : Colors.black87;
    final textSub = isDark ? Colors.white60 : Colors.black45;
    final rows = _rows(_modes[_mode].shiftMins);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: textSub.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Header + mode toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: AppColors.blue600,
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.hoursTable,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textMain,
                  ),
                ),
                const Spacer(),
                ...List.generate(
                  _modes.length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: GestureDetector(
                      onTap: () => setState(() => _mode = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _mode == i
                              ? AppColors.blue600
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.06)),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          _modes[i].label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _mode == i ? Colors.white : textSub,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Column headers
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(
              children: [
                _OrariCell(AppStrings.entrata, textSub, isHeader: true),
                _OrariCell(
                  AppStrings.expectedExitStdHeader,
                  AppColors.blue600,
                  isHeader: true,
                ),
                _OrariCell(
                  AppStrings.nineHourThresholdHeader,
                  AppColors.orange600,
                  isHeader: true,
                ),
                _OrariCell(
                  AppStrings.lunchExtraHeader,
                  AppColors.green700,
                  isHeader: true,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Data rows
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final (entry, stdExit, nine, nine30) = rows[i];
                final rowBg = i.isEven
                    ? Colors.transparent
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.02));
                return Container(
                  color: rowBg,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      _OrariCell(_t(entry), textMain, bold: true),
                      _OrariCell(_t(stdExit), AppColors.blue600),
                      _OrariCell(
                        nine != null ? _t(nine) : '—',
                        nine != null ? AppColors.orange600 : textSub,
                      ),
                      _OrariCell(
                        nine30 != null ? _t(nine30) : '—',
                        nine30 != null ? AppColors.green700 : textSub,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Row(
              children: [
                _Dot(AppColors.blue600),
                const SizedBox(width: 4),
                Text(
                  AppStrings.expectedExitStdHeader,
                  style: TextStyle(fontSize: 10, color: textSub),
                ),
                const SizedBox(width: 12),
                _Dot(AppColors.orange600),
                const SizedBox(width: 4),
                Text(
                  AppStrings.nineHourThresholdHeader,
                  style: TextStyle(fontSize: 10, color: textSub),
                ),
                const SizedBox(width: 12),
                _Dot(AppColors.green700),
                const SizedBox(width: 4),
                Text(
                  AppStrings.nineHourPlusPauseLegend,
                  style: TextStyle(fontSize: 10, color: textSub),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

class _OrariCell extends StatelessWidget {
  final String text;
  final Color color;
  final bool isHeader;
  final bool bold;

  const _OrariCell(
    this.text,
    this.color, {
    this.isHeader = false,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Text(
      text,
      style: TextStyle(
        fontSize: isHeader ? 10 : 13,
        fontWeight: (isHeader || bold) ? FontWeight.w700 : FontWeight.w500,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    ),
  );
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// ── GPS prompt card ──────────────────────────────────────────────────────────

class _GpsPromptCard extends StatefulWidget {
  final Map<String, dynamic>? profileData;
  final bool isDark;
  final VoidCallback onClockIn;

  const _GpsPromptCard({
    required this.profileData,
    required this.isDark,
    required this.onClockIn,
  });

  @override
  State<_GpsPromptCard> createState() => _GpsPromptCardState();
}

class _GpsPromptCardState extends State<_GpsPromptCard> {
  bool _checking = false;
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.profileData;
    final gpsEnabled = data?['gpsAutoClockIn'] as bool? ?? false;
    final officeLat = data?['officeLat'] as double?;
    final officeLng = data?['officeLng'] as double?;

    // Show only between 06:00–11:00, GPS enabled, office coords set, not dismissed
    final hour = DateTime.now().hour;
    if (!gpsEnabled ||
        officeLat == null ||
        officeLng == null ||
        _dismissed ||
        hour < 6 ||
        hour >= 11) {
      return const SizedBox.shrink();
    }

    final radius =
        (data?['officeRadiusM'] as num?)?.toDouble() ??
        GeofencingService.defaultRadiusM;
    final isDark = widget.isDark;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : AppColors.neutral600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.blue600.withValues(alpha: isDark ? 0.10 : 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.blue600.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Text('📍', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppStrings.gpsAutoClockInDialog,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppColors.neutral900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_checking)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.blue600,
                ),
              )
            else ...[
              GestureDetector(
                onTap: () async {
                  final ctx = context;
                  setState(() => _checking = true);
                  final result = await GeofencingService.checkInOffice(
                    officeLat: officeLat,
                    officeLng: officeLng,
                    radiusM: radius,
                  );
                  if (!ctx.mounted) return;
                  setState(() => _checking = false);
                  if (result == GeofenceResult.inside) {
                    final ok = await showDialog<bool>(
                      context: ctx,
                      builder: (_) => AlertDialog(
                        title: const Text(AppStrings.gpsAutoClockInDialog),
                        content: const Text(AppStrings.gpsAutoClockInBody),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text(AppStrings.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(AppStrings.clockIn),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) widget.onClockIn();
                  } else if (result == GeofenceResult.permissionDenied) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text(AppStrings.gpsPermissionDenied),
                        ),
                      );
                    }
                  }
                  setState(() => _dismissed = true);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blue600,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    AppStrings.gpsSetFromHere,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() => _dismissed = true),
                child: Icon(Icons.close_rounded, size: 16, color: textSub),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── BOE bottom sheet ─────────────────────────────────────────────────────────

class _BoeSheet extends StatefulWidget {
  final int deficitMins;
  final int apAvailMins;
  final int acAvailMins;
  final bool hasLunchPause;
  final bool hasShortPause;

  const _BoeSheet({
    required this.deficitMins,
    required this.apAvailMins,
    required this.acAvailMins,
    required this.hasLunchPause,
    required this.hasShortPause,
  });

  @override
  State<_BoeSheet> createState() => _BoeSheetState();
}

class _BoeSheetState extends State<_BoeSheet> {
  String _slot = BoeSlot.postExit;

  String _hm(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    return h > 0 ? '${h}h ${m.toString().padLeft(2, '0')}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.04);
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.92)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral400;

    final totalAvail = widget.apAvailMins + widget.acAvailMins;
    final covered = widget.deficitMins.clamp(0, totalAvail);
    // Deduction order: AP first, then AC.
    final fromAp = covered.clamp(0, widget.apAvailMins);
    final fromAc = (covered - fromAp).clamp(0, widget.acAvailMins);

    final hasPauses = widget.hasLunchPause || widget.hasShortPause;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C2535) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: textSub.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.savings_outlined,
                  color: AppColors.green600,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  AppStrings.coverWithBankHours,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textMain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.workedLessThanMinimum(_hm(widget.deficitMins)),
              style: TextStyle(fontSize: 13, color: textSub),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BoeInfoRow(
                    AppStrings.deficit,
                    _hm(widget.deficitMins),
                    textMain,
                    textSub,
                    color: AppColors.red700,
                  ),
                  const SizedBox(height: 8),
                  if (fromAp > 0)
                    _BoeInfoRow(
                      AppStrings.fromPreviousYear,
                      '−${_hm(fromAp)}',
                      textMain,
                      textSub,
                      color: AppColors.neutral600,
                    ),
                  if (fromAc > 0) ...[
                    const SizedBox(height: 4),
                    _BoeInfoRow(
                      AppStrings.fromCurrentYear,
                      '−${_hm(fromAc)}',
                      textMain,
                      textSub,
                      color: AppColors.neutral600,
                    ),
                  ],
                  const Divider(height: 20),
                  _BoeInfoRow(
                    covered == widget.deficitMins
                        ? AppStrings.deficitCovered
                        : AppStrings.partiallyCovered,
                    _hm(covered),
                    textMain,
                    textSub,
                    color: covered == widget.deficitMins
                        ? AppColors.green600
                        : AppColors.orange500,
                    bold: true,
                  ),
                  if (covered < widget.deficitMins) ...[
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.residualLostHours(
                        _hm(widget.deficitMins - covered),
                      ),
                      style: TextStyle(fontSize: 11, color: textSub),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppStrings.whereToInsertHours,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textSub,
              ),
            ),
            const SizedBox(height: 10),
            _SlotTile(
              icon: Icons.login_rounded,
              label: AppStrings.beforeClockIn,
              subtitle: AppStrings.beforeClockInDesc,
              selected: _slot == BoeSlot.preEntry,
              onTap: () => setState(() => _slot = BoeSlot.preEntry),
              textMain: textMain,
              textSub: textSub,
            ),
            if (hasPauses) ...[
              const SizedBox(height: 8),
              _SlotTile(
                icon: Icons.free_breakfast_outlined,
                label: AppStrings.onAPause,
                subtitle: widget.hasLunchPause && widget.hasShortPause
                    ? AppStrings.reducesLunchOrShortPause
                    : widget.hasLunchPause
                    ? AppStrings.reducesLunchPause
                    : AppStrings.reducesShortPause,
                selected: _slot == BoeSlot.pause,
                onTap: () => setState(() => _slot = BoeSlot.pause),
                textMain: textMain,
                textSub: textSub,
              ),
            ],
            const SizedBox(height: 8),
            _SlotTile(
              icon: Icons.logout_rounded,
              label: AppStrings.afterClockOut,
              subtitle: AppStrings.afterClockOutDesc,
              selected: _slot == BoeSlot.postExit,
              onTap: () => setState(() => _slot = BoeSlot.postExit),
              textMain: textMain,
              textSub: textSub,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GlassBtn(
                    label: AppStrings.skip,
                    variant: GlassBtnVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassBtn(
                    label: AppStrings.confirmBoe,
                    onPressed: () =>
                        Navigator.of(context).pop((mins: covered, slot: _slot)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BoeInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textMain;
  final Color textSub;
  final Color color;
  final bool bold;

  const _BoeInfoRow(
    this.label,
    this.value,
    this.textMain,
    this.textSub, {
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(fontSize: 13, color: textSub)),
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          color: color,
        ),
      ),
    ],
  );
}

class _SlotTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Color textMain;
  final Color textSub;

  const _SlotTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.textMain,
    required this.textSub,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.green600.withValues(alpha: 0.12)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.green600.withValues(alpha: 0.6)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.green600 : textSub,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.green600 : textMain,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: textSub),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppColors.green600,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Compact custom counters strip on Home ────────────────────────────────────

class _HomeCountersRow extends ConsumerWidget {
  const _HomeCountersRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final counters = ref.watch(customCountersProvider);
    if (counters.isEmpty) return const SizedBox.shrink();

    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            AppStrings.yourCounters,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: textSub,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: counters.map((c) {
              final color =
                  CustomCounter.palette[c.colorIndex.clamp(
                    0,
                    CustomCounter.palette.length - 1,
                  )];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${c.value}${c.unit.isNotEmpty ? ' ${c.unit}' : ''}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: color.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
