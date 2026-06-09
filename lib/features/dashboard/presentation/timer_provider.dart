import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../timesheet/data/timesheet_repository.dart';
import '../../timesheet/domain/daily_timesheet.dart';
import '../../profile/data/profile_repository.dart';
import '../../../core/constants/app_constants.dart';

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
  final int totalLeavePauseMins; // Art. 9 — permessi brevi
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

    // Auto-add mandatory 30-min lunch if user hasn't taken one yet and has
    // already worked ≥ 9h net (excl. all pauses including ongoing).
    final lunchCommittedOrOngoing =
        totalLunchPauseMins +
        (currentPauseType == PauseType.lunch ? ongoingPauseMins : 0);
    if (lunchCommittedOrOngoing < 30) {
      final workedSoFar =
          currentTime.difference(startTime!).inMinutes -
          totalStandardPauseMins -
          totalLeavePauseMins -
          ongoingPauseMins;
      if (workedSoFar >= 540) minsToAdd += 30;
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

// ── Firestore cross-device sync helpers ──────────────────────────────

DocumentReference<Map<String, dynamic>>? _timerDoc() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;
  return FirebaseFirestore.instance.doc('users/$uid/activeTimer/state');
}

Future<void> _saveToFirestore(TimerState s) async {
  final doc = _timerDoc();
  if (doc == null) return;
  final data = <String, dynamic>{
    'date': _todayStr(),
    'status': s.status.name,
    'pauseType': s.currentPauseType.name,
    'stdPauseMins': s.totalStandardPauseMins,
    'leavePauseMins': s.totalLeavePauseMins,
    'lunchPauseMins': s.totalLunchPauseMins,
  };
  if (s.startTime != null) data['startTime'] = s.startTime!.toIso8601String();
  if (s.currentPauseStart != null) {
    data['pauseStart'] = s.currentPauseStart!.toIso8601String();
  }
  unawaited(
    doc
        .set(data)
        .onError((e, _) => debugPrint('[timer] Firestore sync failed: $e')),
  );
}

Future<TimerState?> _loadFromFirestore(int stdMins) async {
  final doc = _timerDoc();
  if (doc == null) return null;
  try {
    final snap = await doc.get();
    if (!snap.exists) return null;
    final d = snap.data()!;
    if ((d['date'] as String?) != _todayStr()) return null;
    final statusName = d['status'] as String?;
    if (statusName == null) return null;
    final status = WorkState.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => WorkState.notStarted,
    );
    if (status == WorkState.notStarted || status == WorkState.completed) {
      return null;
    }
    final startStr = d['startTime'] as String?;
    if (startStr == null) return null;
    final pauseStr = d['pauseStart'] as String?;
    final pauseTypeName = d['pauseType'] as String? ?? 'none';
    return TimerState(
      status: status,
      startTime: DateTime.parse(startStr),
      currentPauseStart: pauseStr != null ? DateTime.parse(pauseStr) : null,
      currentPauseType: PauseType.values.firstWhere(
        (p) => p.name == pauseTypeName,
        orElse: () => PauseType.none,
      ),
      totalStandardPauseMins: d['stdPauseMins'] as int? ?? 0,
      totalLeavePauseMins: d['leavePauseMins'] as int? ?? 0,
      totalLunchPauseMins: d['lunchPauseMins'] as int? ?? 0,
      standardWorkMins: stdMins,
      currentTime: DateTime.now(),
    );
  } catch (_) {
    return null;
  }
}

Future<void> _clearFromFirestore() async {
  _timerDoc()?.delete().ignore();
}

// ── Local SharedPreferences persistence helpers ───────────────────────

Future<void> _saveTimerState(TimerState s) async {
  final prefs = await SharedPreferences.getInstance();
  final today = _todayStr();
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
  if (savedDate == null || savedDate != _todayStr()) return null;

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

String _todayStr() {
  final d = DateTime.now();
  return '${d.year}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
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
    final stdMins = profileVal?['standardDailyMins'] as int? ?? AppConstants.stdDailyMinsRuolo;
    final notifMins = profileVal?['exitNotifMins'] as int? ?? 15;

    // Update profile-derived fields without resetting a mid-shift state.
    ref.listen<AsyncValue<Map<String, dynamic>?>>(userProfileStreamProvider, (
      prev,
      next,
    ) {
      final mins = next.asData?.value?['standardDailyMins'] as int? ?? AppConstants.stdDailyMinsRuolo;
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

    // ── Cross-device real-time sync ──────────────────────────────────────
    // Listen to Firestore activeTimer doc so a second device sees timer
    // updates made on the primary device without requiring an app restart.
    // The first snapshot is always skipped: startup restore is handled below
    // by _loadTimerState / _loadFromFirestore to avoid a race.
    final syncDoc = _timerDoc();
    if (syncDoc != null) {
      bool firstSnap = true;
      final sub = syncDoc.snapshots().listen((snap) {
        if (firstSnap) {
          firstSnap = false;
          return;
        }
        // Only mirror Firestore when this device is not actively running
        // the timer (i.e. it's in read-only / second-device mode).
        if (state.isShiftActive) return;
        if (!snap.exists) return;
        final d = snap.data()!;
        if ((d['date'] as String?) != _todayStr()) return;
        final statusName = d['status'] as String?;
        if (statusName == null) return;
        final status = WorkState.values.firstWhere(
          (s) => s.name == statusName,
          orElse: () => WorkState.notStarted,
        );
        if (status == WorkState.notStarted || status == WorkState.completed) {
          return;
        }
        final startStr = d['startTime'] as String?;
        if (startStr == null) return;
        final pauseStr = d['pauseStart'] as String?;
        final pauseTypeName = d['pauseType'] as String? ?? 'none';
        state = TimerState(
          status: status,
          startTime: DateTime.parse(startStr),
          currentPauseStart: pauseStr != null ? DateTime.parse(pauseStr) : null,
          currentPauseType: PauseType.values.firstWhere(
            (p) => p.name == pauseTypeName,
            orElse: () => PauseType.none,
          ),
          totalStandardPauseMins: d['stdPauseMins'] as int? ?? 0,
          totalLeavePauseMins: d['leavePauseMins'] as int? ?? 0,
          totalLunchPauseMins: d['lunchPauseMins'] as int? ?? 0,
          // Use current state's stdMins, not the stale captured build() value.
          standardWorkMins: state.standardWorkMins,
          currentTime: DateTime.now(),
        );
      });
      ref.onDispose(sub.cancel);
    }

    // Restore today's in-progress shift: local first, then Firestore fallback
    _loadTimerState(stdMins).then((saved) async {
      if (saved != null) {
        state = saved;
      } else {
        final remote = await _loadFromFirestore(stdMins);
        if (remote != null) state = remote;
      }
    });

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

  void _sendExitNotifToFirestore() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final exit = state.expectedExitTime;
    if (exit == null) return;
    FirebaseFirestore.instance.collection('users/$uid/notifications').add({
      'type': 'exit_reminder',
      'title': 'Uscita prevista',
      'body': 'Tra ${state.exitNotifMins} min finisce il tuo turno.',
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    }).ignore();
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
    _saveTimerState(state);
    _saveToFirestore(state);
    _publishStatus('working');
  }

  void startPause(PauseType type, DateTime time) {
    state = state.copyWith(
      status: WorkState.paused,
      currentPauseType: type,
      currentPauseStart: time,
    );
    _saveTimerState(state);
    _saveToFirestore(state);
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
        // Art. 9 — permesso breve tracked separately
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
    _saveTimerState(state);
    _saveToFirestore(state);
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
      final worked =
          elapsed - state.totalStandardPauseMins - state.totalLeavePauseMins;
      if (worked >= 540) lunch += 30;
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
      final workedSoFar =
          totalElapsedMins -
          state.totalStandardPauseMins -
          state.totalLeavePauseMins;
      if (workedSoFar >= 540) finalLunchMins += 30;
    }

    final netWorkedMins =
        totalElapsedMins -
        state.totalStandardPauseMins -
        state.totalLeavePauseMins -
        finalLunchMins;
    // Effective minutes include BOE coverage for threshold calculations.
    final effectiveMins = netWorkedMins + bancaOreMins;
    final extraMins = effectiveMins - state.standardWorkMins;

    final dateId =
        '${state.startTime!.year}-'
        '${state.startTime!.month.toString().padLeft(2, '0')}-'
        '${state.startTime!.day.toString().padLeft(2, '0')}';

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
    );

    // Persist to Firestore.
    // If this throws, the exception propagates to the UI caller.
    // State is NOT mutated until the save succeeds, so the user can retry.
    await ref.read(timesheetRepositoryProvider).saveDailyTimesheet(record);

    // Save succeeded — clear local and remote persistence, advance to completed.
    await _clearTimerState();
    await _clearFromFirestore();
    state = TimerState(
      currentTime: DateTime.now(),
      standardWorkMins: state.standardWorkMins,
      status: WorkState.completed,
      lastCompletedShift: record,
    );
    _publishStatus('completed');
  }

  // ── Auto-abandon (called by ticker at 21:00 when shift still active) ──

  Future<void> _autoAbandon() async {
    // Remove user from colleagues' "In ufficio" view immediately.
    _publishStatus('notStarted');
    // Clear cross-device Firestore doc — no active shift to sync.
    await _clearFromFirestore();
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

  /// User dismisses the warning without saving the day.
  Future<void> dismissAbandoned() async {
    await _clearTimerState();
    await _clearFromFirestore();
    state = TimerState(
      currentTime: DateTime.now(),
      standardWorkMins: state.standardWorkMins,
    );
  }
}
