import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/color_schemes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/chigio_quotes.dart';
import '../../../core/services/chigio_phrase_engine.dart';
import '../../../shared/widgets/app_tappable.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../social/data/social_repository.dart';
import '../../timesheet/data/timesheet_repository.dart';
import '../../timesheet/domain/daily_timesheet.dart';
import '../../timesheet/presentation/timesheet_screen.dart';
import '../domain/totalizzatori.dart';
import '../presentation/timer_provider.dart';

/// Hero "rivoluzione timbratura" della Home (2026-07):
/// - Chigio grande a sinistra (posa contestuale allo stato del turno);
/// - a destra il contenuto di fase: tasto timbratura (slide per timbrare ora,
///   long-press per scegliere l'orario) → barre di avanzamento con orari in
///   evidenza → resoconto giornaliero con contatori di maggior presenza;
/// - assorbe saluto, frase Chigio, campanella e avatar (in Home il
///   GlassHeader non viene più montato).
class TimbraturaHero extends ConsumerStatefulWidget {
  final DailyTimesheet? todayEntry;
  final int monthlyDeficitMins;
  final Totalizzatori? totData;
  final Map<String, dynamic>? profileData;

  /// Su desktop campanella+avatar vivono in alto a destra della pagina
  /// (montati dal dashboard), non nell'header dell'hero.
  final bool showHeaderActions;

  const TimbraturaHero({
    super.key,
    required this.todayEntry,
    required this.monthlyDeficitMins,
    required this.totData,
    required this.profileData,
    this.showHeaderActions = true,
  });

  @override
  ConsumerState<TimbraturaHero> createState() => _TimbraturaHeroState();
}

class _TimbraturaHeroState extends ConsumerState<TimbraturaHero> {
  static const int _mealMins = AppConstants.defaultMealVoucherThresholdMins;

  // Bumped on tap → forces a different Chigio phrase from the pool
  int _phraseOffset = 0;

  String _p2(int n) => n.abs().toString().padLeft(2, '0');

  String _fmtHHMM(int totalMins) =>
      '${_p2(totalMins ~/ 60)}:${_p2(totalMins % 60)}';

  String _fmtHM(int mins) {
    final m = mins.abs();
    final h = m ~/ 60;
    final rem = m % 60;
    if (h == 0) return '${rem}m';
    if (rem == 0) return '${h}h';
    return '${h}h ${_p2(rem)}m';
  }

  String _fmtTime(DateTime t) => '${_p2(t.hour)}:${_p2(t.minute)}';

  Future<DateTime?> _pickTime() async {
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

  static Widget _phaseTransition(Widget child, Animation<double> anim) =>
      FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      );

  void _showErrorSnack(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.errorGeneric(e)),
        backgroundColor: AppColors.red700,
      ),
    );
  }

  // ── Clock actions (slide → now, long-press → picked time) ────────────

  Future<void> _clockIn(DateTime t) async {
    ref.read(workTimerProvider.notifier).startTurn(t);
  }

  Future<void> _clockOut(DateTime t) async {
    final notifier = ref.read(workTimerProvider.notifier);
    final state = ref.read(workTimerProvider);

    final deficit = notifier.previewDeficit(t);
    int bancaOreMins = 0;
    String? boeSlot;

    if (deficit > 0) {
      final apAvail = widget.totData?.bancaOreApResiduo ?? 0;
      final acAvail = widget.totData?.bancaOreAcResiduo ?? 0;
      if ((apAvail + acAvail) > 0 && mounted) {
        final result = await showModalBottomSheet<({int mins, String slot})>(
          context: context,
          useRootNavigator: true,
          useSafeArea: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => BoeSheet(
            deficitMins: deficit,
            apAvailMins: apAvail,
            acAvailMins: acAvail,
            hasLunchPause: state.totalLunchPauseMins > 0,
            hasShortPause: state.totalStandardPauseMins > 0,
          ),
        );
        if (result != null) {
          bancaOreMins = result.mins;
          boeSlot = result.slot;
        }
      }
    }

    if (!mounted) return;
    try {
      await notifier.endTurn(t, bancaOreMins: bancaOreMins, boeSlot: boeSlot);
    } catch (e) {
      if (mounted) _showErrorSnack(e);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workTimerProvider);
    final notifier = ref.read(workTimerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Effective flags — merge in-memory timer with today's Firestore entry
    // (same logic as the old hero card: right state after an app restart).
    final isWorking = state.status == WorkState.working;
    final isPaused = state.status == WorkState.paused;
    final rawCompleted = state.status == WorkState.completed;
    final rawNotStarted = state.status == WorkState.notStarted;
    final isAbandoned = state.isAbandoned;
    final showTodayCompleted = rawNotStarted && widget.todayEntry != null;
    final isCompleted = rawCompleted || showTodayCompleted;
    final isNotStarted = rawNotStarted && !showTodayCompleted;
    final isActive = isWorking || isPaused;

    // Chiave di fase per le transizioni animate (AnimatedSwitcher).
    final phaseKey = isAbandoned
        ? 'abandoned'
        : isNotStarted
        ? 'idle'
        : isActive
        ? 'active'
        : 'done';

    final effectiveShift = state.lastCompletedShift ?? widget.todayEntry;

    // Worked minutes
    int workedMins;
    if (isCompleted) {
      workedMins = effectiveShift?.netWorkedMins ?? 0;
    } else if (isAbandoned && state.startTime != null) {
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

    final stdMins = state.standardWorkMins;
    final isOT = workedMins > stdMins;
    final otMins = isOT ? workedMins - stdMins : 0;
    final mealEarned = workedMins >= _mealMins;

    final exit = state.expectedExitTime;
    final entryTimeStr = state.startTime != null
        ? _fmtTime(state.startTime!)
        : (effectiveShift != null ? _fmtTime(effectiveShift.startTime) : null);
    final exitStr = exit != null ? _fmtTime(exit) : '--:--';

    // ── Greeting + Chigio phrase ────────────────────────────────────────
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final displayName =
        (widget.profileData?['name'] as String?)?.trim().isNotEmpty == true
        ? widget.profileData!['name'] as String
        : (firebaseUser?.displayName ?? AppStrings.defaultUserName);
    final firstName = displayName.split(' ').first;
    final now = DateTime.now();
    final seed = now.hour * 12 + now.minute ~/ 5 + _phraseOffset;
    final chigioData = ChigioPhraseEngine.resolveContext(
      ChigioContext(
        page: ChigioPage.dashboard,
        firstName: firstName,
        shiftState: switch (state.status) {
          WorkState.working => ChigioShiftState.working,
          WorkState.paused => ChigioShiftState.paused,
          WorkState.completed => ChigioShiftState.completed,
          WorkState.abandoned => ChigioShiftState.abandoned,
          _ => ChigioShiftState.notStarted,
        },
        gender: (widget.profileData?['gender'] as String?) ?? 'A',
        department: (widget.profileData?['dipartimento'] as String?) ?? '',
        site: (widget.profileData?['sede'] as String?) ?? '',
        workedMins: workedMins,
        remainingMins: state.remainingTime?.inMinutes,
        standardWorkMins: stdMins,
        mealVoucherThresholdMins:
            widget.profileData?['mealVoucherThresholdMins'] as int? ??
            _mealMins,
        isPayDay: now.day == 23,
        seed: seed,
        now: now,
      ),
    );

    // Contextual pose — big mascot on the left column
    final String pose;
    if (isAbandoned) {
      pose = ChigioQuotes.avviso;
    } else if (isNotStarted) {
      pose = ChigioQuotes.ciao;
    } else if (isPaused) {
      pose = ChigioQuotes.caffe;
    } else if (isCompleted) {
      pose = ChigioQuotes.festeggia;
    } else if (isOT) {
      pose = ChigioQuotes.corre;
    } else {
      pose = ChigioQuotes.timer;
    }

    final gradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF12142E), Color(0xFF0A0C20)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.blue600, AppColors.blue800],
          );

    // ── Right column per fase ───────────────────────────────────────────
    final Widget phaseRight;
    if (isAbandoned) {
      phaseRight = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeroBadge(
            text: AppStrings.abandonedBadge,
            color: AppColors.orange300,
          ),
          const SizedBox(height: 8),
          Text(
            _fmtHHMM(workedMins),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.orange300,
              letterSpacing: -1.5,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const Text(
            AppStrings.abandonedTitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.orange300,
            ),
          ),
        ],
      );
    } else if (isNotStarted) {
      phaseRight = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SlideButton(
            label: AppStrings.clockIn,
            hint: AppStrings.slideToClockIn,
            icon: Icons.badge_rounded,
            background: Colors.white,
            foreground: AppColors.blue700,
            fillColor: AppColors.blue100,
            height: 86,
            pickTime: _pickTime,
            onConfirmed: _clockIn,
          ),
          const SizedBox(height: 10),
          _HeroSmartWorkingBtn(stdMins: stdMins),
        ],
      );
    } else if (isActive) {
      phaseRight = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWorking)
            const _LiveDot()
          else
            const _HeroBadge(
              text: AppStrings.statusInPausa,
              color: AppColors.orange300,
            ),
          const SizedBox(height: 6),
          Text(
            _fmtHHMM(workedMins),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1.5,
              height: 1.0,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            isOT
                ? '+${_fmtHM(otMins)} ${AppStrings.pdfSummaryStraordinario.toLowerCase()}'
                : AppStrings.hoursWorked,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isOT
                  ? AppColors.orange300
                  : Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _HeroTimeCol(label: AppStrings.entrata, time: entryTimeStr),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              _HeroTimeCol(
                label: AppStrings.expectedExit,
                time: exitStr,
                accent: AppColors.blue200,
              ),
            ],
          ),
        ],
      );
    } else {
      // isCompleted — resoconto compatto a destra di Chigio
      final completedOt = (effectiveShift?.extraMins ?? 0) > 0
          ? effectiveShift!.extraMins
          : 0;
      phaseRight = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeroBadge(
            text: AppStrings.statusDoneUpper,
            color: AppColors.green300,
          ),
          const SizedBox(height: 8),
          Text(
            _fmtHHMM(workedMins),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1.5,
              height: 1.0,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            completedOt > 0
                ? '+${_fmtHM(completedOt)} ${AppStrings.maggiorPresenza.toLowerCase()}'
                : AppStrings.ottimoLavoro,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: completedOt > 0 ? AppColors.orange300 : AppColors.green300,
            ),
          ),
        ],
      );
    }

    // ── Card ────────────────────────────────────────────────────────────
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppColors.blue800).withValues(
                alpha: 0.35,
              ),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header: saluto + frase | campanella + avatar ────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _phraseOffset++),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.heroGreeting(firstName),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          chigioData.phrase,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            height: 1.3,
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.showHeaderActions) ...[
                  const SizedBox(width: 10),
                  HomeHeaderActions(
                    photoUrl: firebaseUser?.photoURL,
                    firstName: firstName,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // ── Main row: Chigio grande a sinistra + fase a destra ──────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppTappable(
                  onTap: () => context.push('/chigio'),
                  semanticLabel: 'Chigio',
                  child: SizedBox(
                    width: 112,
                    height: 124,
                    child: Transform.translate(
                      offset: const Offset(-4, 8),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.85,
                              end: 1,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: Image.asset(
                          pose,
                          key: ValueKey(pose),
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                          errorBuilder: (_, _, _) => const Center(
                            child: Text('🐢', style: TextStyle(fontSize: 64)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: _phaseTransition,
                    child: KeyedSubtree(
                      key: ValueKey('phase-$phaseKey'),
                      child: phaseRight,
                    ),
                  ),
                ),
              ],
            ),

            // ── Full-width per fase (altezza e contenuto animati) ───────
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: _phaseTransition,
                child: Column(
                  key: ValueKey('bottom-$phaseKey'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isActive) ...[
                      const SizedBox(height: 14),
                      _HeroBars(
                        workedMins: workedMins,
                        stdMins: stdMins,
                        mealMins: _mealMins,
                        mealEarned: mealEarned,
                      ),
                      const SizedBox(height: 10),
                      _HeroNineHourHint(state: state),
                      if (state.expectedExitTime != null) ...[
                        const SizedBox(height: 10),
                        _HeroSmartExit(
                          exitStd: state.expectedExitTime!,
                          exitPlusHour: state.expectedExitTime!.add(
                            const Duration(hours: 1),
                          ),
                          exitMensile: widget.monthlyDeficitMins > stdMins
                              ? state.expectedExitTime!.add(
                                  Duration(
                                    minutes:
                                        widget.monthlyDeficitMins - stdMins,
                                  ),
                                )
                              : null,
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (isWorking)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _HeroPauseChip(
                              icon: '🍽️',
                              label: AppStrings.lunchChip,
                              onTap: () async {
                                final t = await _pickTime();
                                if (t != null) {
                                  notifier.startPause(PauseType.lunch, t);
                                }
                              },
                            ),
                            _HeroPauseChip(
                              icon: '☕',
                              label: AppStrings.breakChip,
                              onTap: () async {
                                final t = await _pickTime();
                                if (t != null) {
                                  notifier.startPause(PauseType.short, t);
                                }
                              },
                            ),
                            _HeroPauseChip(
                              icon: '🚶',
                              label: AppStrings.wtLeave,
                              onTap: () async {
                                final t = await _pickTime();
                                if (t != null) {
                                  notifier.startPause(PauseType.leave, t);
                                }
                              },
                            ),
                          ],
                        )
                      else
                        GlassBtn(
                          label: AppStrings.resume,
                          onPressed: () async {
                            final t = await _pickTime();
                            if (t != null) notifier.endPause(t);
                          },
                        ),
                      if (isWorking) ...[
                        const SizedBox(height: 12),
                        _SlideButton(
                          label: AppStrings.clockOut,
                          hint: AppStrings.slideToClockOut,
                          icon: Icons.logout_rounded,
                          background: Colors.white,
                          foreground: AppColors.red700,
                          fillColor: AppColors.red100,
                          height: 60,
                          pickTime: _pickTime,
                          onConfirmed: _clockOut,
                        ),
                      ],
                    ] else if (isCompleted && effectiveShift != null) ...[
                      const SizedBox(height: 14),
                      _DailySummary(
                        shift: effectiveShift,
                        mealEarned: mealEarned,
                      ),
                      const SizedBox(height: 12),
                      GlassBtn(
                        label: AppStrings.editDay,
                        variant: GlassBtnVariant.secondary,
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        onPressed: () => showDayEntrySheet(
                          context,
                          date: effectiveShift.startTime,
                          existingEntry: effectiveShift,
                          // La copia in-memory del turno diventa stale dopo il save:
                          // la scartiamo così l'hero si riallinea allo stream Firestore.
                          onSaved: () => ref
                              .read(workTimerProvider.notifier)
                              .invalidateLastCompletedShift(),
                          // Giornata cancellata → si riparte da "non iniziato".
                          onDeleted: () =>
                              ref.read(workTimerProvider.notifier).resetDay(),
                        ),
                      ),
                    ] else if (isAbandoned) ...[
                      const SizedBox(height: 14),
                      _HeroAbandonedCta(
                        onClockOut: () async {
                          final t = await _pickTime();
                          if (t != null) {
                            try {
                              await notifier.endTurnFromAbandoned(t);
                            } catch (e) {
                              if (mounted) _showErrorSnack(e);
                            }
                          }
                        },
                        onDismiss: notifier.dismissAbandoned,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Slide-to-confirm button (long-press → time picker) ──────────────────────

class _SlideButton extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color fillColor;
  final double height;

  /// Long-press: chooses a custom time (null = annullato).
  final Future<DateTime?> Function() pickTime;
  final Future<void> Function(DateTime time) onConfirmed;

  const _SlideButton({
    required this.label,
    required this.hint,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.fillColor,
    required this.height,
    required this.pickTime,
    required this.onConfirmed,
  });

  @override
  State<_SlideButton> createState() => _SlideButtonState();
}

class _SlideButtonState extends State<_SlideButton> {
  double _drag = 0; // 0..1 thumb progress
  bool _dragging = false;
  bool _busy = false; // onConfirmed in flight → spinner sul pomello

  Future<void> _fire(DateTime t) async {
    if (_busy) return;
    // Il pomello corre a fine corsa e mostra lo spinner finché il save gira.
    setState(() {
      _busy = true;
      _dragging = false;
      _drag = 1;
    });
    HapticFeedback.heavyImpact();
    try {
      await widget.onConfirmed(t);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _drag = 0;
        });
      }
    }
  }

  Future<void> _onLongPress() async {
    if (_busy) return;
    HapticFeedback.mediumImpact();
    final t = await widget.pickTime();
    if (t != null) await _fire(t);
  }

  @override
  Widget build(BuildContext context) {
    final thumbSize = widget.height - 12;
    // Implicit animation: instant while dragging, eased snap otherwise.
    final animMs = _dragging ? 0 : 250;

    return Semantics(
      button: true,
      label: '${widget.label} — ${widget.hint}. ${AppStrings.holdToPickTime}',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxDrag = constraints.maxWidth - thumbSize - 12;
          return GestureDetector(
            onLongPress: _onLongPress,
            onHorizontalDragStart: _busy
                ? null
                : (_) {
                    HapticFeedback.selectionClick();
                    setState(() => _dragging = true);
                  },
            onHorizontalDragUpdate: _busy
                ? null
                : (d) {
                    // Tick aptico a ogni quarto di corsa.
                    final prevTick = (_drag * 4).floor();
                    setState(
                      () => _drag = (_drag + d.delta.dx / maxDrag).clamp(
                        0.0,
                        1.0,
                      ),
                    );
                    if ((_drag * 4).floor() != prevTick) {
                      HapticFeedback.selectionClick();
                    }
                  },
            onHorizontalDragEnd: _busy
                ? null
                : (_) {
                    setState(() => _dragging = false);
                    if (_drag >= 0.9) {
                      _fire(DateTime.now());
                    } else {
                      setState(() => _drag = 0);
                    }
                  },
            onHorizontalDragCancel: () {
              if (_busy) return;
              setState(() {
                _dragging = false;
                _drag = 0;
              });
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.background,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Progressive fill behind the thumb
                    AnimatedPositioned(
                      duration: Duration(milliseconds: animMs),
                      curve: Curves.easeOutCubic,
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 6 + thumbSize + _drag * maxDrag,
                      child: ColoredBox(color: widget.fillColor),
                    ),
                    // Label + hint, centered
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(left: thumbSize / 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              widget.label,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: widget.foreground,
                              ),
                            ),
                            Text(
                              '${widget.hint}\n${AppStrings.holdToPickTime}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9,
                                height: 1.25,
                                fontWeight: FontWeight.w600,
                                color: widget.foreground.withValues(
                                  alpha: 0.65,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Draggable thumb (scala su drag, spinner mentre salva)
                    AnimatedPositioned(
                      duration: Duration(milliseconds: animMs),
                      curve: Curves.easeOutCubic,
                      left: 6 + _drag * maxDrag,
                      top: 6,
                      child: AnimatedScale(
                        scale: _dragging ? 1.08 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOut,
                        child: Container(
                          width: thumbSize,
                          height: thumbSize,
                          decoration: BoxDecoration(
                            color: widget.foreground,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _busy
                              ? Center(
                                  child: SizedBox(
                                    width: thumbSize * 0.45,
                                    height: thumbSize * 0.45,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: widget.background,
                                    ),
                                  ),
                                )
                              : Icon(
                                  widget.icon,
                                  size: thumbSize * 0.5,
                                  color: widget.background,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Barre di avanzamento (giornata + buono pasto) ───────────────────────────

class _HeroBars extends StatelessWidget {
  final int workedMins;
  final int stdMins;
  final int mealMins;
  final bool mealEarned;

  const _HeroBars({
    required this.workedMins,
    required this.stdMins,
    required this.mealMins,
    required this.mealEarned,
  });

  @override
  Widget build(BuildContext context) {
    const barH = 10.0;
    // Span must always include the 9h (540 min) daily-cap gate.
    final totalSpan = (stdMins + 120) > 560 ? stdMins + 120 : 560;

    double frac(int mins) => (mins / totalSpan).clamp(0.0, 1.0);

    final isOT = workedMins > stdMins;
    final fillFrac = frac(isOT ? stdMins : workedMins);
    final otFrac = isOT ? frac(workedMins) - frac(stdMins) : 0.0;
    final stdLabel =
        '${stdMins ~/ 60}:${(stdMins % 60).toString().padLeft(2, '0')}';

    final gates = [
      (
        mins: mealMins,
        label: AppStrings.mealGateShort,
        color: AppColors.green300,
      ),
      (mins: stdMins, label: stdLabel, color: Colors.white),
      (mins: 540, label: AppStrings.nineHourShort, color: AppColors.red300),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Barra giornata ────────────────────────────────────────────
        LayoutBuilder(
          builder: (_, constraints) {
            final w = constraints.maxWidth;
            return SizedBox(
              height: 34,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: barH,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(barH / 2),
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  if (fillFrac > 0)
                    Positioned(
                      left: 0,
                      top: 0,
                      width: w * fillFrac,
                      height: barH,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(barH / 2),
                          gradient: const LinearGradient(
                            colors: [AppColors.blue300, Colors.white],
                          ),
                        ),
                      ),
                    ),
                  if (otFrac > 0)
                    Positioned(
                      left: w * frac(stdMins),
                      top: 0,
                      width: w * otFrac,
                      height: barH,
                      child: Container(color: AppColors.orange500),
                    ),
                  for (final g in gates)
                    Positioned(
                      left: w * frac(g.mins) - 1,
                      top: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 2,
                            height: barH,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            g.label,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: g.color,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 4),

        // ── Buono pasto: barra sottile → badge quando maturato ────────
        if (mealEarned)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.green500.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              AppStrings.mealEarnedFull,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.green300,
              ),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2.5),
                  child: LinearProgressIndicator(
                    value: (workedMins / mealMins).clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.green300,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '🍽️ ${(workedMins / mealMins * 100).clamp(0, 100).round()}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// ── Indicatore tetto 9 ore (ex _NineHourBanner, palette hero) ───────────────

class _HeroNineHourHint extends StatelessWidget {
  final TimerState state;

  const _HeroNineHourHint({required this.state});

  @override
  Widget build(BuildContext context) {
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
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.orange500.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.orange300.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: AppColors.orange300,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                AppStrings.lunchVirtualBanner(lunchDeficit),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.orange300,
                ),
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
          Icon(
            Icons.timer_outlined,
            size: 13,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 4),
          Text(
            AppStrings.nineHourThreshold('$h:$m'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

// ── Scenari smart-exit (palette hero) ───────────────────────────────────────

class _HeroSmartExit extends StatelessWidget {
  final DateTime exitStd;
  final DateTime exitPlusHour;
  final DateTime? exitMensile;

  const _HeroSmartExit({
    required this.exitStd,
    required this.exitPlusHour,
    this.exitMensile,
  });

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, String time, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                time,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(AppStrings.smartExitStd, _fmt(exitStd), AppColors.green300),
        const SizedBox(width: 6),
        chip(
          AppStrings.smartExitPlusHour,
          _fmt(exitPlusHour),
          AppColors.orange300,
        ),
        const SizedBox(width: 6),
        exitMensile != null
            ? chip(
                AppStrings.smartExitMensile,
                _fmt(exitMensile!),
                AppColors.blue200,
              )
            : chip(AppStrings.smartExitMensile, '✓', AppColors.green300),
      ],
    );
  }
}

// ── Resoconto giornaliero (fase 3) ──────────────────────────────────────────

class _DailySummary extends StatelessWidget {
  final DailyTimesheet shift;
  final bool mealEarned;

  const _DailySummary({required this.shift, required this.mealEarned});

  static String _p2(int n) => n.toString().padLeft(2, '0');

  static String _time(DateTime t) => '${_p2(t.hour)}:${_p2(t.minute)}';

  static String _hm(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${_p2(m)}m';
  }

  @override
  Widget build(BuildContext context) {
    final hasPauses =
        shift.lunchPauseMins > 0 ||
        shift.standardPauseMins > 0 ||
        shift.leavePauseMins > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.dailySummary.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 10),

          // Orari chiave
          Row(
            children: [
              _SummaryCol(
                label: AppStrings.entrata,
                value: _time(shift.startTime),
              ),
              _SummaryCol(
                label: AppStrings.uscita,
                value: _time(shift.endTime),
              ),
              _SummaryCol(
                label: AppStrings.lavorato,
                value:
                    '${_p2(shift.netWorkedMins ~/ 60)}:${_p2(shift.netWorkedMins % 60)}',
                color: AppColors.green300,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 10),

          // Contatori maggior presenza di oggi
          Row(
            children: [
              _SummaryCol(
                label: AppStrings.maggiorPresenza,
                value: shift.extraMins > 0 ? '+${_hm(shift.extraMins)}' : '0m',
                color: shift.extraMins > 0
                    ? AppColors.orange300
                    : Colors.white.withValues(alpha: 0.6),
              ),
              if (shift.sboMins > 0)
                _SummaryCol(
                  label: AppStrings.sboCounterLabel,
                  value: '+${_hm(shift.sboMins)}',
                  color: AppColors.blue200,
                ),
              if (shift.sliMins > 0)
                _SummaryCol(
                  label: AppStrings.sliCounterLabel,
                  value: '+${_hm(shift.sliMins)}',
                  color: AppColors.green300,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 10),

          // Pause + extra maturati
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (!hasPauses)
                _SummaryChip(
                  text: AppStrings.noPauses,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              if (shift.lunchPauseMins > 0)
                _SummaryChip(
                  text:
                      '🍽️ ${AppStrings.lunchChip} ${_hm(shift.lunchPauseMins)}',
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              if (shift.standardPauseMins > 0)
                _SummaryChip(
                  text:
                      '☕ ${AppStrings.breakChip} ${_hm(shift.standardPauseMins)}',
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              if (shift.leavePauseMins > 0)
                _SummaryChip(
                  text: '🚶 ${AppStrings.wtLeave} ${_hm(shift.leavePauseMins)}',
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              if (mealEarned)
                const _SummaryChip(
                  text: '🍽️ ${AppStrings.mealVoucherShort} ✓',
                  color: AppColors.green300,
                ),
              if (shift.bancaOreMins > 0)
                _SummaryChip(
                  text: AppStrings.bancaOreUsedChip(_hm(shift.bancaOreMins)),
                  color: AppColors.blue200,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCol extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _SummaryCol({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: color ?? Colors.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String text;
  final Color color;

  const _SummaryChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── Piccoli componenti hero ─────────────────────────────────────────────────

class _HeroBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _HeroBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.green300,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          AppStrings.statusLive,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.green300,
          ),
        ),
      ],
    );
  }
}

class _HeroTimeCol extends StatelessWidget {
  final String label;
  final String? time;
  final Color? accent;

  const _HeroTimeCol({required this.label, required this.time, this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          time ?? '--:--',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: accent ?? Colors.white,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Campanella notifiche + avatar profilo della Home. In mobile vivono
/// nell'header dell'hero (sul gradiente blu); su desktop il dashboard li
/// monta in alto a destra della pagina con [onHeroGradient] = false.
class HomeHeaderActions extends ConsumerWidget {
  final String? photoUrl;
  final String firstName;
  final bool onHeroGradient;

  const HomeHeaderActions({
    super.key,
    required this.photoUrl,
    required this.firstName,
    this.onHeroGradient = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onLight = !onHeroGradient && !isDark;
    final iconColor = onLight
        ? AppColors.blue800.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.85);
    final circleColor = onLight
        ? AppColors.blue800.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.12);
    final circleBorder = onLight
        ? AppColors.blue800.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.2);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeroCircleBtn(
          onTap: () => context.push('/notifications'),
          color: circleColor,
          borderColor: circleBorder,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_outlined, size: 19, color: iconColor),
              if (ref.watch(hasUnreadProvider))
                Positioned(
                  top: -1,
                  right: -1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.red700,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _HeroAvatar(photoUrl: photoUrl, firstName: firstName),
      ],
    );
  }
}

class _HeroCircleBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color color;
  final Color borderColor;

  const _HeroCircleBtn({
    required this.child,
    required this.onTap,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppTappable(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: borderColor),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _HeroAvatar extends StatelessWidget {
  final String? photoUrl;
  final String firstName;

  const _HeroAvatar({required this.photoUrl, required this.firstName});

  Widget _fallback() => Container(
    color: AppColors.blue400,
    child: Center(
      child: Text(
        firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/profile'),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: ClipOval(
          child: photoUrl != null
              ? Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _fallback(),
                )
              : _fallback(),
        ),
      ),
    );
  }
}

class _HeroPauseChip extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _HeroPauseChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppTappable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
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
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottone Smart Working — registra la giornata da remoto (ore standard
/// piene + buono pasto automatico, nessun timer).
class _HeroSmartWorkingBtn extends ConsumerStatefulWidget {
  final int stdMins;

  const _HeroSmartWorkingBtn({required this.stdMins});

  @override
  ConsumerState<_HeroSmartWorkingBtn> createState() =>
      _HeroSmartWorkingBtnState();
}

class _HeroSmartWorkingBtnState extends ConsumerState<_HeroSmartWorkingBtn> {
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
    return AppTappable(
      onTap: _loading ? null : _save,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                Icons.laptop_rounded,
                size: 17,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            const SizedBox(width: 7),
            Text(
              AppStrings.smartWorkingFull,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CTA giornata abbandonata (ex _AbandonedCta, palette hero) ───────────────

class _HeroAbandonedCta extends StatelessWidget {
  final VoidCallback onClockOut;
  final VoidCallback onDismiss;

  const _HeroAbandonedCta({required this.onClockOut, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.orange500.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orange300.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: AppColors.orange300,
              ),
              SizedBox(width: 6),
              Text(
                AppStrings.abandonedTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.orange300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            AppStrings.abandonedBody,
            style: TextStyle(fontSize: 11, color: AppColors.orange300),
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
              AppTappable(
                onTap: onDismiss,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Text(
                    AppStrings.dismissDay,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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

// ── BOE bottom sheet (spostato qui dalla dashboard: il flusso di uscita
//    con deficit ora parte dal hero) ─────────────────────────────────────────

class BoeSheet extends StatefulWidget {
  final int deficitMins;
  final int apAvailMins;
  final int acAvailMins;
  final bool hasLunchPause;
  final bool hasShortPause;

  const BoeSheet({
    super.key,
    required this.deficitMins,
    required this.apAvailMins,
    required this.acAvailMins,
    required this.hasLunchPause,
    required this.hasShortPause,
  });

  @override
  State<BoeSheet> createState() => _BoeSheetState();
}

class _BoeSheetState extends State<BoeSheet> {
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
        ? Colors.white.withValues(alpha: 0.6)
        : AppColors.neutral600;

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
                const Icon(
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
    return AppTappable(
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
              const Icon(
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
