import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/active_timer_repository.dart';
import '../../timesheet/data/timesheet_repository.dart';
import '../../timesheet/domain/daily_timesheet.dart';
import '../../timesheet/domain/day_segment.dart';
import '../../profile/data/profile_repository.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';

part 'timer_provider.g.dart';

enum WorkState { notStarted, working, paused, completed, abandoned }

enum PauseType { none, lunch, short, leave }

// SharedPreferences keys for mid-day persistence
const _kDate = 'timer_date';
const _kStatus = 'timer_status';
const _kStart = 'timer_startTime';
const _kStdPause = 'timer_stdPauseMins';
const _kLeavePause = 'timer_leavePauseMins';
const _kLunchPause = 'timer_lunchPauseMins';
const _kPauseStart = 'timer_pauseStart';
const _kPauseType = 'timer_pauseType';

class TimerState {
  final WorkState status;
  final DateTime? startTime;
  final DateTime? currentPauseStart;
  final PauseType currentPauseType;
  final int totalStandardPauseMins; // coffee/short breaks
  final int totalLeavePauseMins; // permessi brevi (Art. 35 CCNL PCM)
  final int totalLunchPauseMins;
  final int standardWorkMins;
  // Minutes before expected exit to show reminder (0 = disabled).
  final int exitNotifMins;
  final DateTime currentTime;
  final DailyTimesheet? lastCompletedShift;
  // True for one tick when remaining time crosses the reminder threshold.
  final bool exitReminderPending;

  const TimerState({
    this.status = WorkState.notStarted,
    this.startTime,
    this.currentPauseStart,
    this.currentPauseType = PauseType.none,
    this.totalStandardPauseMins = 0,
    this.totalLeavePauseMins = 0,
    this.totalLunchPauseMins = 0,
    this.standardWorkMins = AppConstants.stdDailyMinsRuolo,
    this.exitNotifMins = 15,
    required this.currentTime,
    this.lastCompletedShift,
    this.exitReminderPending = false,
  });

  TimerState copyWith({
    WorkState? status,
    DateTime? startTime,
    Object? startTimeOrNull = _sentinel,
    DateTime? currentPauseStart,
    Object? pauseStartOrNull = _sentinel,
    PauseType? currentPauseType,
    int? totalStandardPauseMins,
    int? totalLeavePauseMins,
    int? totalLunchPauseMins,
    int? standardWorkMins,
    int? exitNotifMins,
    DateTime? currentTime,
    DailyTimesheet? lastCompletedShift,
    Object? completedShiftOrNull = _sentinel,
    bool exitReminderPending = false, // one-shot: reset unless explicitly set
  }) {
    return TimerState(
      status: status ?? this.status,
      startTime: startTimeOrNull != _sentinel
          ? startTimeOrNull as DateTime?
          : (startTime ?? this.startTime),
      currentPauseStart: pauseStartOrNull != _sentinel
          ? pauseStartOrNull as DateTime?
          : (currentPauseStart ?? this.currentPauseStart),
      currentPauseType: currentPauseType ?? this.currentPauseType,
      totalStandardPauseMins:
          totalStandardPauseMins ?? this.totalStandardPauseMins,
      totalLeavePauseMins: totalLeavePauseMins ?? this.totalLeavePauseMins,
      totalLunchPauseMins: totalLunchPauseMins ?? this.totalLunchPauseMins,
      standardWorkMins: standardWorkMins ?? this.standardWorkMins,
      exitNotifMins: exitNotifMins ?? this.exitNotifMins,
      currentTime: currentTime ?? this.currentTime,
      lastCompletedShift: completedShiftOrNull != _sentinel
          ? completedShiftOrNull as DailyTimesheet?
          : (lastCompletedShift ?? this.lastCompletedShift),
      exitReminderPending: exitReminderPending,
    );
  }

  DateTime? get expectedExitTime {
    if (startTime == null) return null;

    // Elapsed minutes of the current in-progress pause (not yet committed).
    final ongoingPauseMins = currentPauseStart != null
        ? currentTime.difference(currentPauseStart!).inMinutes
        : 0;

    // minsToAdd = standard shift + all completed pauses + ongoing pause.
    int minsToAdd =
        standardWorkMins +
        totalStandardPauseMins +
        totalLeavePauseMins +
        totalLunchPauseMins +
        ongoingPauseMins;

    // Mandatory lunch — 3-zone rule (CCNL PCM), see AppConstants.forcedLunchMins.
    final lunchCommittedOrOngoing =
        totalLunchPauseMins +
        (currentPauseType == PauseType.lunch ? ongoingPauseMins : 0);
    if (lunchCommittedOrOngoing < 30) {
      final effectiveElapsed =
          currentTime.difference(startTime!).inMinutes -
          totalStandardPauseMins -
          totalLeavePauseMins;
      final forcedLunch = AppConstants.forcedLunchMins(effectiveElapsed);
      if (forcedLunch > lunchCommittedOrOngoing) {
        minsToAdd += forcedLunch - lunchCommittedOrOngoing;
      }
    }

    return startTime!.add(Duration(minutes: minsToAdd));
  }

  Duration? get remainingTime {
    if (expectedExitTime == null) return null;
    return expectedExitTime!.difference(currentTime);
  }

  bool get isShiftActive =>
      status == WorkState.working || status == WorkState.paused;

  bool get isAbandoned => status == WorkState.abandoned;
}

const _sentinel = Object();

// ── Local SharedPreferences persistence helpers ───────────────────────

Future<void> _saveTimerState(TimerState s) async {
  final prefs = await SharedPreferences.getInstance();
  final today = todayId();
  await prefs.setString(_kDate, today);
  await prefs.setString(_kStatus, s.status.name);
  if (s.startTime != null) {
    await prefs.setString(_kStart, s.startTime!.toIso8601String());
  } else {
    await prefs.remove(_kStart);
  }
  await prefs.setInt(_kStdPause, s.totalStandardPauseMins);
  await prefs.setInt(_kLeavePause, s.totalLeavePauseMins);
  await prefs.setInt(_kLunchPause, s.totalLunchPauseMins);
  if (s.currentPauseStart != null) {
    await prefs.setString(_kPauseStart, s.currentPauseStart!.toIso8601String());
  } else {
    await prefs.remove(_kPauseStart);
  }
  await prefs.setString(_kPauseType, s.currentPauseType.name);
}

Future<void> _clearTimerState() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kDate);
  await prefs.remove(_kStatus);
  await prefs.remove(_kStart);
  await prefs.remove(_kStdPause);
  await prefs.remove(_kLeavePause);
  await prefs.remove(_kLunchPause);
  await prefs.remove(_kPauseStart);
  await prefs.remove(_kPauseType);
}

Future<TimerState?> _loadTimerState(int stdMins) async {
  final prefs = await SharedPreferences.getInstance();
  final savedDate = prefs.getString(_kDate);
  // Only restore if the saved state is from today
  if (savedDate == null || savedDate != todayId()) return null;

  final statusName = prefs.getString(_kStatus);
  if (statusName == null) return null;
  final status = WorkState.values.firstWhere(
    (s) => s.name == statusName,
    orElse: () => WorkState.notStarted,
  );
  if (status == WorkState.notStarted || status == WorkState.completed) {
    return null;
  }

  final startStr = prefs.getString(_kStart);
  if (startStr == null) return null;

  final pauseStartStr = prefs.getString(_kPauseStart);
  final pauseTypeName = prefs.getString(_kPauseType) ?? 'none';

  return TimerState(
    status: status,
    startTime: DateTime.parse(startStr),
    currentPauseStart: pauseStartStr != null
        ? DateTime.parse(pauseStartStr)
        : null,
    currentPauseType: PauseType.values.firstWhere(
      (p) => p.name == pauseTypeName,
      orElse: () => PauseType.none,
    ),
    totalStandardPauseMins: prefs.getInt(_kStdPause) ?? 0,
    totalLeavePauseMins: prefs.getInt(_kLeavePause) ?? 0,
    totalLunchPauseMins: prefs.getInt(_kLunchPause) ?? 0,
    standardWorkMins: stdMins,
    currentTime: DateTime.now(),
  );
}

// ── Provider ─────────────────────────────────────────────────────────

@riverpod
class WorkTimer extends _$WorkTimer {
  Timer? _ticker;

  @override
  TimerState build() {
    // Use ref.read() — NOT ref.watch() — to avoid full provider rebuild (and
    // state reset) every time the profile stream emits a Firestore snapshot.
    // ref.listen() below handles stdMins updates without triggering a rebuild.
    final profileVal = ref.read(userProfileStreamProvider).asData?.value;
    final stdMins = profileVal != null
        ? AppConstants.stdMinsForDate(profileVal, DateTime.now())
        : AppConstants.stdDailyMinsRuolo;
    final notifMins = profileVal?['exitNotifMins'] as int? ?? 15;

    // Update profile-derived fields without resetting a mid-shift state.
    ref.listen<AsyncValue<Map<String, dynamic>?>>(userProfileStreamProvider, (
      prev,
      next,
    ) {
      final mins = next.asData?.value != null
          ? AppConstants.stdMinsForDate(next.asData!.value!, DateTime.now())
          : AppConstants.stdDailyMinsRuolo;
      final notif = next.asData?.value?['exitNotifMins'] as int? ?? 15;
      final wasLoading = prev == null || prev.isLoading;
      if (!state.isShiftActive || wasLoading) {
        state = state.copyWith(standardWorkMins: mins, exitNotifMins: notif);
      } else {
        // Always update exitNotifMins even during shift (no state reset).
        state = state.copyWith(
          exitReminderPending: state.exitReminderPending,
          exitNotifMins: notif,
        );
      }
    });

    // ── Cross-device real-time sync (M3: via ActiveTimerRepository) ──────
    // A second device sees timer updates made on the primary device without
    // an app restart. The first snapshot is always skipped: startup restore
    // is handled by _restore() below to avoid a race.
    bool firstSnap = true;
    final sub = ref.read(activeTimerRepositoryProvider).watch().listen((
      remote,
    ) {
      if (firstSnap) {
        firstSnap = false;
        return;
      }
      // Only mirror Firestore when this device is not actively running
      // the timer (i.e. it's in read-only / second-device mode).
      if (state.isShiftActive) return;
      if (remote == null) return;
      state = _fromRemote(remote);
    });
    ref.onDispose(sub.cancel);

    // Restore today's in-progress shift: local first, then Firestore fallback
    _restore(stdMins);

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      // Auto-abandon: shift still active after 21:00 → remove from "In ufficio"
      if (state.isShiftActive && now.hour >= 21) {
        _autoAbandon();
        return;
      }
      // Exit reminder: fire once when remaining ≤ exitNotifMins
      final remaining = state.remainingTime;
      final threshold = state.exitNotifMins;
      if (state.isShiftActive &&
          threshold > 0 &&
          remaining != null &&
          remaining.inMinutes <= threshold &&
          remaining.inMinutes > 0 &&
          !state.exitReminderPending) {
        _sendExitNotifToFirestore();
        state = state.copyWith(currentTime: now, exitReminderPending: true);
        return;
      }
      // Preserve exitReminderPending so the flag stays true after it fires
      // and doesn't retrigger _sendExitNotifToFirestore on subsequent ticks.
      state = state.copyWith(
        currentTime: now,
        exitReminderPending: state.exitReminderPending,
      );
    });
    ref.onDispose(() => _ticker?.cancel());

    return TimerState(
      currentTime: DateTime.now(),
      standardWorkMins: stdMins,
      exitNotifMins: notifMins,
    );
  }

  // ── ActiveTimerRepository glue (M3) ──────────────────────────────────

  ActiveTimerRepository get _remoteRepo =>
      ref.read(activeTimerRepositoryProvider);

  /// Sync remoto fire-and-forget dello stato corrente (no-op senza turno).
  void _syncRemote() {
    final s = state;
    if (s.startTime == null) return;
    _remoteRepo
        .save(
          ActiveTimerData(
            status: s.status.name,
            startTime: s.startTime!,
            pauseStart: s.currentPauseStart,
            pauseType: s.currentPauseType.name,
            stdPauseMins: s.totalStandardPauseMins,
            leavePauseMins: s.totalLeavePauseMins,
            lunchPauseMins: s.totalLunchPauseMins,
          ),
        )
        .ignore();
  }

  TimerState _fromRemote(ActiveTimerData d) => TimerState(
    status: WorkState.values.firstWhere(
      (s) => s.name == d.status,
      orElse: () => WorkState.notStarted,
    ),
    startTime: d.startTime,
    currentPauseStart: d.pauseStart,
    currentPauseType: PauseType.values.firstWhere(
      (p) => p.name == d.pauseType,
      orElse: () => PauseType.none,
    ),
    totalStandardPauseMins: d.stdPauseMins,
    totalLeavePauseMins: d.leavePauseMins,
    totalLunchPauseMins: d.lunchPauseMins,
    // Use current state's values, not stale captured build() ones.
    standardWorkMins: state.standardWorkMins,
    exitNotifMins: state.exitNotifMins,
    currentTime: DateTime.now(),
  );

  /// Restore del turno di oggi: prefs locali, poi fallback Firestore.
  Future<void> _restore(int stdMins) async {
    TimerState? saved;
    try {
      saved = await _loadTimerState(stdMins);
    } catch (e) {
      // Prefs corrotte (DateTime non parsabile): il restore locale salta,
      // resta il fallback remoto.
      debugPrint('[timer] local restore failed: $e');
    }
    if (saved == null) {
      final remote = await _remoteRepo.load();
      if (remote != null) saved = _fromRemote(remote);
    }
    if (saved == null) return;
    // M4: il restore è async — se nel frattempo l'utente ha già avviato un
    // turno (o il giorno è stato chiuso), NON sovrascrivere lo stato.
    if (state.status != WorkState.notStarted) return;
    state = saved;
  }

  void _sendExitNotifToFirestore() {
    if (state.expectedExitTime == null) return;
    _remoteRepo.sendExitReminder(state.exitNotifMins).ignore();
  }

  void _publishStatus(String status) {
    ref.read(profileRepositoryProvider).updateCurrentStatus(status).ignore();
  }

  void startTurn(DateTime time) {
    state = state.copyWith(
      status: WorkState.working,
      startTime: time,
      completedShiftOrNull: null,
    );
    _saveTimerState(state).ignore();
    _syncRemote();
    _publishStatus('working');
  }

  void startPause(PauseType type, DateTime time) {
    state = state.copyWith(
      status: WorkState.paused,
      currentPauseType: type,
      currentPauseStart: time,
    );
    _saveTimerState(state).ignore();
    _syncRemote();
    _publishStatus('paused');
  }

  void endPause(DateTime time) {
    if (state.currentPauseStart == null) return;
    final pauseMins = time.difference(state.currentPauseStart!).inMinutes;
    int newStandard = state.totalStandardPauseMins;
    int newLeave = state.totalLeavePauseMins;
    int newLunch = state.totalLunchPauseMins;
    switch (state.currentPauseType) {
      case PauseType.lunch:
        newLunch += pauseMins < 30 ? 30 : pauseMins;
      case PauseType.leave:
        // permesso breve (Art. 35) tracked separately
        newLeave += pauseMins;
      default:
        newStandard += pauseMins;
    }
    state = state.copyWith(
      status: WorkState.working,
      pauseStartOrNull: null,
      currentPauseType: PauseType.none,
      totalStandardPauseMins: newStandard,
      totalLeavePauseMins: newLeave,
      totalLunchPauseMins: newLunch,
    );
    _saveTimerState(state).ignore();
    _syncRemote();
    _publishStatus('working');
  }

  /// Returns the deficit in minutes (standardWorkMins - projected net) for a
  /// given end time, or 0 if no deficit. Used by the UI to decide whether to
  /// show the BOE dialog before calling [endTurn].
  int previewDeficit(DateTime endTime) {
    if (state.startTime == null) return 0;
    final elapsed = endTime.difference(state.startTime!).inMinutes;
    int lunch = state.totalLunchPauseMins;
    if (lunch < 30) {
      final effectiveElapsed =
          elapsed - state.totalStandardPauseMins - state.totalLeavePauseMins;
      lunch = AppConstants.forcedLunchMins(
        effectiveElapsed,
        alreadyTakenMins: lunch,
      );
    }
    final net =
        elapsed -
        state.totalStandardPauseMins -
        state.totalLeavePauseMins -
        lunch;
    return (state.standardWorkMins - net).clamp(0, 9999);
  }

  Future<void> endTurn(
    DateTime endTime, {
    int bancaOreMins = 0,
    String? boeSlot,
  }) async {
    if (state.startTime == null) return;

    final totalElapsedMins = endTime.difference(state.startTime!).inMinutes;
    int finalLunchMins = state.totalLunchPauseMins;
    if (finalLunchMins < 30) {
      final effectiveElapsed =
          totalElapsedMins -
          state.totalStandardPauseMins -
          state.totalLeavePauseMins;
      finalLunchMins = AppConstants.forcedLunchMins(
        effectiveElapsed,
        alreadyTakenMins: finalLunchMins,
      );
    }

    final netWorkedMins =
        totalElapsedMins -
        state.totalStandardPauseMins -
        state.totalLeavePauseMins -
        finalLunchMins;
    // Effective minutes include BOE coverage for threshold calculations.
    final effectiveMins = netWorkedMins + bancaOreMins;
    final extraMins = effectiveMins - state.standardWorkMins;

    final dateId = dateIdOf(state.startTime!);

    // All positive overtime defaults to SBO (banca ore); user can edit in timesheet.
    final record = DailyTimesheet(
      dateId: dateId,
      startTime: state.startTime!,
      endTime: endTime,
      standardPauseMins: state.totalStandardPauseMins,
      leavePauseMins: state.totalLeavePauseMins,
      lunchPauseMins: finalLunchMins,
      netWorkedMins: netWorkedMins,
      extraMins: extraMins,
      sboMins: extraMins > 0 ? extraMins : 0,
      bancaOreMins: bancaOreMins,
      boeSlot: boeSlot,
      segments: [
        DaySegment(
          type: DaySegment.work,
          start: state.startTime!,
          end: endTime,
        ),
        if (state.totalLeavePauseMins > 0)
          DaySegment(type: DaySegment.leave, mins: state.totalLeavePauseMins),
      ],
    );

    // Persist to Firestore.
    // If this throws, the exception propagates to the UI caller.
    // State is NOT mutated until the save succeeds, so the user can retry.
    await ref.read(timesheetRepositoryProvider).saveDailyTimesheet(record);

    // Save succeeded — clear local and remote persistence, advance to completed.
    await _clearTimerState();
    await _remoteRepo.clear();
    state = TimerState(
      currentTime: DateTime.now(),
      standardWorkMins: state.standardWorkMins,
      status: WorkState.completed,
      lastCompletedShift: record,
    );
    _publishStatus('completed');
  }

  /// Dopo la modifica inline della giornata (sheet "Modifica giornata" in
  /// Home) la copia in-memory del turno completato è stale: la scartiamo
  /// così l'hero legge il documento aggiornato dallo stream Firestore.
  void invalidateLastCompletedShift() {
    if (state.lastCompletedShift == null) return;
    state = state.copyWith(
      completedShiftOrNull: null,
      currentTime: DateTime.now(),
    );
  }

  // ── Auto-abandon (called by ticker at 21:00 when shift still active) ──

  Future<void> _autoAbandon() async {
    // Remove user from colleagues' "In ufficio" view immediately.
    _publishStatus('notStarted');
    // Clear cross-device Firestore doc — no active shift to sync.
    await _remoteRepo.clear();
    // Persist abandoned state locally so the warning survives an app restart.
    final newState = state.copyWith(
      status: WorkState.abandoned,
      currentTime: DateTime.now(),
    );
    await _saveTimerState(newState);
    state = newState;
  }

  /// User clocks out retroactively from the abandoned/warning state.
  /// Delegates to [endTurn] which already handles any start/end time.
  Future<void> endTurnFromAbandoned(DateTime endTime) => endTurn(endTime);

  /// Riporta il timer a "non iniziato": giornata cancellata dallo sheet
  /// inline in Home, oppure dismiss del warning abbandono.
  Future<void> resetDay() async {
    await _clearTimerState();
    await _remoteRepo.clear();
    state = TimerState(
      currentTime: DateTime.now(),
      standardWorkMins: state.standardWorkMins,
    );
    _publishStatus('notStarted');
  }

  /// User dismisses the warning without saving the day.
  Future<void> dismissAbandoned() => resetDay();
}
