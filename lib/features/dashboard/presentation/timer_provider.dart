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
const _kPendingRemoteSync = 'timer_pendingRemoteSync';

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

  DateTime? get exitReminderAt {
    if (status != WorkState.working || exitNotifMins <= 0) return null;
    return expectedExitTime?.subtract(Duration(minutes: exitNotifMins));
  }

  bool get isShiftActive =>
      status == WorkState.working || status == WorkState.paused;

  bool get isAbandoned => status == WorkState.abandoned;
}

class TimerProfileUpdate {
  final TimerState state;
  final bool shouldUpdateReminder;

  const TimerProfileUpdate({
    required this.state,
    required this.shouldUpdateReminder,
  });
}

TimerProfileUpdate computeTimerProfileUpdate(
  TimerState current, {
  required int standardWorkMins,
  required int exitNotifMins,
}) {
  final changed =
      current.standardWorkMins != standardWorkMins ||
      current.exitNotifMins != exitNotifMins;
  return TimerProfileUpdate(
    state: current.copyWith(
      standardWorkMins: standardWorkMins,
      exitNotifMins: exitNotifMins,
    ),
    shouldUpdateReminder: current.isShiftActive && changed,
  );
}

TimerState mergeRestoredTimerState({
  required TimerState restored,
  required TimerState current,
}) => restored.copyWith(
  standardWorkMins: current.standardWorkMins,
  exitNotifMins: current.exitNotifMins,
  currentTime: current.currentTime,
);

TimerState applyRemoteTimerState({
  required TimerState local,
  required ActiveTimerData? remote,
  required DateTime now,
}) {
  if (local.status == WorkState.completed ||
      local.status == WorkState.abandoned) {
    return local;
  }
  if (remote == null) {
    if (!local.isShiftActive) return local;
    return TimerState(
      currentTime: now,
      standardWorkMins: local.standardWorkMins,
      exitNotifMins: local.exitNotifMins,
    );
  }
  return TimerState(
    status: WorkState.values.firstWhere(
      (status) => status.name == remote.status,
      orElse: () => WorkState.notStarted,
    ),
    startTime: remote.startTime,
    currentPauseStart: remote.pauseStart,
    currentPauseType: PauseType.values.firstWhere(
      (type) => type.name == remote.pauseType,
      orElse: () => PauseType.none,
    ),
    totalStandardPauseMins: remote.stdPauseMins,
    totalLeavePauseMins: remote.leavePauseMins,
    totalLunchPauseMins: remote.lunchPauseMins,
    standardWorkMins: local.standardWorkMins,
    exitNotifMins: local.exitNotifMins,
    currentTime: now,
  );
}

ActiveTimerData _activeTimerDataFromState(TimerState state) => ActiveTimerData(
  status: state.status.name,
  startTime: state.startTime!,
  pauseStart: state.currentPauseStart,
  pauseType: state.currentPauseType.name,
  stdPauseMins: state.totalStandardPauseMins,
  leavePauseMins: state.totalLeavePauseMins,
  lunchPauseMins: state.totalLunchPauseMins,
  reminderAt: state.exitReminderAt,
  reminderLeadMins: state.exitNotifMins,
);

class RemoteTimerApplyResult {
  final TimerState state;
  final bool shouldApply;
  final bool shouldSyncRemote;

  const RemoteTimerApplyResult.apply(
    this.state, {
    this.shouldSyncRemote = false,
  }) : shouldApply = true;
  const RemoteTimerApplyResult.noOp(this.state)
    : shouldApply = false,
      shouldSyncRemote = false;
}

class RemoteTimerHandshake {
  final Future<TimerState?> Function() _loadLocalState;
  final Future<bool> Function() _loadPendingRemoteSync;
  final Future<void> Function() _clearPendingRemoteSync;
  final Future<void> Function() _clearLocalState;
  bool _hasSeenRemoteState = false;
  bool _remoteAbsentConfirmed = false;
  bool _localClearPending = false;
  int _generation = 0;
  int? _pendingStartGeneration;

  bool get canRestoreLocal => !_remoteAbsentConfirmed;
  bool get hasPendingLocalStart => _pendingStartGeneration != null;

  RemoteTimerHandshake({
    Future<TimerState?> Function()? loadLocalState,
    Future<bool> Function()? loadPendingRemoteSync,
    Future<void> Function()? clearPendingRemoteSync,
    Future<void> Function()? clearLocalState,
  }) : _loadLocalState = loadLocalState ?? loadTimerState,
       _loadPendingRemoteSync =
           loadPendingRemoteSync ?? _hasPendingRemoteTimerSync,
       _clearPendingRemoteSync =
           clearPendingRemoteSync ?? _clearPendingRemoteTimerSync,
       _clearLocalState = clearLocalState ?? _clearTimerState;

  void markLocalStart() {
    _generation++;
    _localClearPending = false;
    _pendingStartGeneration = _generation;
    _remoteAbsentConfirmed = false;
  }

  void markLocalClear() {
    _generation++;
    _localClearPending = true;
    _pendingStartGeneration = null;
  }

  bool _matchesLocalState(ActiveTimerData remote, TimerState local) {
    if (local.startTime == null) return false;
    final dateId = todayId();
    return ActiveTimerRepository.matchesPersistedState(
      ActiveTimerRepository.toFirestore(remote, dateId: dateId),
      _activeTimerDataFromState(local),
      dateId: dateId,
    );
  }

  Future<RemoteTimerApplyResult> apply({
    required TimerState local,
    required ActiveTimerData? remote,
    required DateTime now,
  }) async {
    final observedGeneration = _generation;
    if (remote != null) {
      if (_localClearPending) {
        return RemoteTimerApplyResult.noOp(local);
      }
      if (_pendingStartGeneration != null &&
          !_matchesLocalState(remote, local)) {
        return RemoteTimerApplyResult.noOp(local);
      }
      _generation++;
      final appliedGeneration = _generation;
      _hasSeenRemoteState = true;
      _pendingStartGeneration = null;
      _remoteAbsentConfirmed = false;
      await _clearPendingRemoteSync();
      if (_generation != appliedGeneration) {
        return RemoteTimerApplyResult.noOp(local);
      }
      return RemoteTimerApplyResult.apply(
        applyRemoteTimerState(local: local, remote: remote, now: now),
      );
    }

    if (local.status == WorkState.completed ||
        local.status == WorkState.abandoned) {
      _generation++;
      _hasSeenRemoteState = false;
      _pendingStartGeneration = null;
      return RemoteTimerApplyResult.noOp(local);
    }

    if (_localClearPending) {
      return RemoteTimerApplyResult.noOp(local);
    }

    if (_pendingStartGeneration != null) {
      return RemoteTimerApplyResult.noOp(local);
    }
    if (!_hasSeenRemoteState) {
      final persisted = await _loadLocalState();
      if (_generation != observedGeneration) {
        return RemoteTimerApplyResult.noOp(local);
      }
      final pendingRemoteSync = await _loadPendingRemoteSync();
      if (_generation != observedGeneration) {
        return RemoteTimerApplyResult.noOp(local);
      }
      if ((persisted?.isShiftActive ?? false) && pendingRemoteSync) {
        _generation++;
        _pendingStartGeneration = _generation;
        _remoteAbsentConfirmed = false;
        return RemoteTimerApplyResult.apply(
          mergeRestoredTimerState(restored: persisted!, current: local),
          shouldSyncRemote: true,
        );
      }
      if (persisted?.status == WorkState.abandoned ||
          persisted?.status == WorkState.completed) {
        return RemoteTimerApplyResult.noOp(local);
      }
    }

    await _clearLocalState();
    if (_generation != observedGeneration) {
      return RemoteTimerApplyResult.noOp(local);
    }
    _generation++;
    _hasSeenRemoteState = false;
    _pendingStartGeneration = null;
    _remoteAbsentConfirmed = true;
    return RemoteTimerApplyResult.apply(
      applyRemoteTimerState(local: local, remote: null, now: now),
    );
  }
}

const _sentinel = Object();

// ── Local SharedPreferences persistence helpers ───────────────────────

Future<void> _saveTimerState(
  TimerState s, {
  required bool pendingRemoteSync,
}) async {
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
  await prefs.setBool(_kPendingRemoteSync, pendingRemoteSync);
}

Future<bool> _hasPendingRemoteTimerSync() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kPendingRemoteSync) ?? false;
}

Future<void> _clearPendingRemoteTimerSync() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kPendingRemoteSync);
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
  await prefs.remove(_kPendingRemoteSync);
}

Future<TimerState?> loadTimerState() async {
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
    currentTime: DateTime.now(),
  );
}

// ── Provider ─────────────────────────────────────────────────────────

@riverpod
class WorkTimer extends _$WorkTimer {
  Timer? _ticker;
  final _remoteHandshake = RemoteTimerHandshake();

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
      final update = computeTimerProfileUpdate(
        state,
        standardWorkMins: mins,
        exitNotifMins: notif,
      );
      state = update.state;
      if (update.shouldUpdateReminder) _updateRemoteReminder();
    });

    // ── Cross-device real-time sync (M3: via ActiveTimerRepository) ──────
    final sub = ref.read(activeTimerRepositoryProvider).watch().listen((
      remote,
    ) {
      _applyRemoteSnapshot(remote);
    });
    ref.onDispose(sub.cancel);

    // Restore today's in-progress shift: local first, then Firestore fallback
    _restore();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      // Auto-abandon: shift still active after 21:00 → remove from "In ufficio"
      if (state.isShiftActive && now.hour >= 21) {
        _autoAbandon();
        return;
      }
      state = state.copyWith(currentTime: now);
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

  ActiveTimerData _remoteData(TimerState s) => _activeTimerDataFromState(s);

  /// Persiste prima il marker locale, poi avvia il sync remoto. In questo modo
  /// un reload offline distingue una transizione ancora non confermata da
  /// prefs stale già sincronizzate in passato.
  void _persistAndSyncRemote() {
    final s = state;
    if (s.startTime == null) return;
    _saveTimerState(
      s,
      pendingRemoteSync: true,
    ).then((_) => _remoteRepo.save(_remoteData(s))).ignore();
  }

  void _updateRemoteReminder() {
    final s = state;
    if (s.startTime == null) return;
    _remoteRepo.updateReminder(_remoteData(s)).ignore();
  }

  Future<void> _clearRemoteTimer() async {
    _remoteHandshake.markLocalClear();
    try {
      await _remoteRepo.clear();
    } catch (_) {
      _remoteHandshake.markLocalStart();
      rethrow;
    }
  }

  Future<void> _applyRemoteSnapshot(ActiveTimerData? remote) async {
    final before = state;
    final result = await _remoteHandshake.apply(
      local: before,
      remote: remote,
      now: DateTime.now(),
    );
    if (!result.shouldApply) {
      if (_remoteHandshake.hasPendingLocalStart && state.isShiftActive) {
        _saveTimerState(state, pendingRemoteSync: true).ignore();
      }
      return;
    }
    if (state.status == WorkState.completed ||
        state.status == WorkState.abandoned) {
      return;
    }
    state = result.state;
    if (result.shouldSyncRemote) {
      _persistAndSyncRemote();
    }
  }

  /// Restore del turno di oggi: prefs locali, poi fallback Firestore.
  Future<void> _restore() async {
    TimerState? saved;
    var savedFromLocal = false;
    try {
      saved = await loadTimerState();
      savedFromLocal = saved != null;
      if (saved?.isShiftActive ?? false) {
        savedFromLocal = await _hasPendingRemoteTimerSync();
        if (!savedFromLocal) saved = null;
      }
    } catch (e) {
      // Prefs corrotte (DateTime non parsabile): il restore locale salta,
      // resta il fallback remoto.
      debugPrint('[timer] local restore failed: $e');
    }
    if (savedFromLocal && !_remoteHandshake.canRestoreLocal) {
      saved = null;
      savedFromLocal = false;
    }
    if (saved == null) {
      final remote = await _remoteRepo.load();
      if (remote != null) {
        final result = await _remoteHandshake.apply(
          local: state,
          remote: remote,
          now: DateTime.now(),
        );
        if (result.shouldApply) saved = result.state;
      }
    }
    if (saved == null) return;
    if (savedFromLocal && !_remoteHandshake.canRestoreLocal) return;
    // M4: il restore è async — se nel frattempo l'utente ha già avviato un
    // turno (o il giorno è stato chiuso), NON sovrascrivere lo stato.
    if (state.status != WorkState.notStarted) return;
    state = mergeRestoredTimerState(restored: saved, current: state);
    _updateRemoteReminder();
  }

  void _publishStatus(String status) {
    ref.read(profileRepositoryProvider).updateCurrentStatus(status).ignore();
  }

  void startTurn(DateTime time) {
    _remoteHandshake.markLocalStart();
    state = state.copyWith(
      status: WorkState.working,
      startTime: time,
      completedShiftOrNull: null,
    );
    _persistAndSyncRemote();
    _publishStatus('working');
  }

  void startPause(PauseType type, DateTime time) {
    state = state.copyWith(
      status: WorkState.paused,
      currentPauseType: type,
      currentPauseStart: time,
    );
    _persistAndSyncRemote();
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
    _persistAndSyncRemote();
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
    await _clearRemoteTimer();
    await _clearTimerState();
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
    await _clearRemoteTimer();
    // Persist abandoned state locally so the warning survives an app restart.
    final newState = state.copyWith(
      status: WorkState.abandoned,
      currentTime: DateTime.now(),
    );
    await _saveTimerState(newState, pendingRemoteSync: false);
    state = newState;
  }

  /// User clocks out retroactively from the abandoned/warning state.
  /// Delegates to [endTurn] which already handles any start/end time.
  Future<void> endTurnFromAbandoned(DateTime endTime) => endTurn(endTime);

  /// Riporta il timer a "non iniziato": giornata cancellata dallo sheet
  /// inline in Home, oppure dismiss del warning abbandono.
  Future<void> resetDay() async {
    await _clearRemoteTimer();
    await _clearTimerState();
    state = TimerState(
      currentTime: DateTime.now(),
      standardWorkMins: state.standardWorkMins,
    );
    _publishStatus('notStarted');
  }

  /// User dismisses the warning without saving the day.
  Future<void> dismissAbandoned() => resetDay();
}
