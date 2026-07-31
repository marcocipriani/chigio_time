import 'dart:async';
import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/active_timer_repository.dart';
import '../../timesheet/data/timesheet_repository.dart';
import '../../timesheet/domain/daily_timesheet.dart';
import '../../timesheet/domain/day_segment.dart';
import '../../profile/data/profile_repository.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/date_utils.dart';

part 'timer_provider.g.dart';

const _logTag = 'timer';

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
const _kClosedPauses = 'timer_closedPauses';
const _kLeaveKind = 'timer_leaveKind';
const _kPendingRemoteSync = 'timer_pendingRemoteSync';
const _kClearPending = 'timer_clearPending';

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

  /// Pause gia' chiuse del turno, come segmenti pronti da salvare.
  final List<DaySegment> closedPauses;

  /// Causale della pausa permesso in corso, se e' una pausa permesso.
  final String? currentLeaveKind;

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
    this.closedPauses = const [],
    this.currentLeaveKind,
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
    List<DaySegment>? closedPauses,
    String? currentLeaveKind,
    Object? leaveKindOrNull = _sentinel,
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
      closedPauses: closedPauses ?? this.closedPauses,
      currentLeaveKind: leaveKindOrNull != _sentinel
          ? leaveKindOrNull as String?
          : (currentLeaveKind ?? this.currentLeaveKind),
    );
  }

  DateTime? get expectedExitTime {
    if (startTime == null) return null;

    // Elapsed minutes of the current in-progress pause (not yet committed).
    final ongoingPauseMins = currentPauseStart != null
        ? currentTime.difference(currentPauseStart!).inMinutes
        : 0;

    // minsToAdd = standard shift + all completed pauses + ongoing pause.
    // Il permesso non allunga l'uscita: da ADR-0018 copre l'orario dovuto,
    // quindi restare per la sua durata produrrebbe eccedenza vera — l'ora di
    // permesso verrebbe scalata dal plafond e in piu' messa in banca ore.
    // Resta invece sottratto dall'elapsed effettivo qui sotto: non e' tempo
    // lavorato, e non deve far scattare il pranzo forzato.
    int minsToAdd =
        standardWorkMins +
        totalStandardPauseMins +
        totalLunchPauseMins +
        (currentPauseType == PauseType.leave ? 0 : ongoingPauseMins);

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

  /// Chiude la pausa in corso a [time]: aggiorna i totali e accoda il
  /// segmento corrispondente. Puro, come [buildEntry]: il notifier ci mette
  /// solo la persistenza.
  ///
  /// La pausa pranzo ha un pavimento di 30 minuti (regola CCNL, gia' applicata
  /// al contatore mostrato dal vivo) e il segmento porta quella durata, non
  /// quella reale: altrimenti una pausa di 20 minuti mostrerebbe 30 e ne
  /// salverebbe 20, alzando il netto di 10. Il pavimento anticipa l'inizio
  /// invece di posticipare la fine: una pausa a ridosso dell'uscita
  /// sforerebbe il turno, sottraendo la durata reale invece dei 30 minuti e
  /// producendo una giornata che viola l'invariante di ADR-0018.
  TimerState withPauseClosed(DateTime time) {
    if (currentPauseStart == null) return this;
    final pauseMins = time.difference(currentPauseStart!).inMinutes;
    final isLunch = currentPauseType == PauseType.lunch;
    final lunchMins = pauseMins < 30 ? 30 : pauseMins;
    // L'inizio non risale oltre l'entrata: su un turno piu' corto del
    // pavimento il segmento resta quello vissuto e i minuti mancanti li
    // aggiunge `_pauseSegments` dal contatore, senza posizione.
    final flooredStart = time.subtract(Duration(minutes: lunchMins));
    final lunchStart = startTime != null && flooredStart.isBefore(startTime!)
        ? startTime!
        : flooredStart;
    return copyWith(
      status: WorkState.working,
      pauseStartOrNull: null,
      currentPauseType: PauseType.none,
      leaveKindOrNull: null,
      totalLunchPauseMins: isLunch
          ? totalLunchPauseMins + lunchMins
          : totalLunchPauseMins,
      // permesso breve (Art. 35) tracked separately
      totalLeavePauseMins: currentPauseType == PauseType.leave
          ? totalLeavePauseMins + pauseMins
          : totalLeavePauseMins,
      totalStandardPauseMins:
          currentPauseType == PauseType.lunch ||
              currentPauseType == PauseType.leave
          ? totalStandardPauseMins
          : totalStandardPauseMins + pauseMins,
      closedPauses: [
        ...closedPauses,
        DaySegment(
          type: switch (currentPauseType) {
            PauseType.lunch => DaySegment.lunch,
            PauseType.leave => DaySegment.leave,
            _ => DaySegment.pause,
          },
          start: isLunch ? lunchStart : currentPauseStart,
          end: time,
          absenceKind: currentLeaveKind,
        ),
      ],
    );
  }

  /// Pause del turno come segmenti. Uno stato restaurato da una versione
  /// precedente (prefs o doc Firestore senza `closedPauses`) porta solo i tre
  /// totali: la differenza fra il totale e i segmenti gia' in lista si aggiunge
  /// senza posizione, come fa `DailyTimesheet.fromMap` per i documenti legacy.
  ///
  /// Riempire per tipo, e non commutare fra le due sorgenti, e' quello che
  /// tiene i minuti restaurati: appena l'utente chiudeva la prima pausa dopo
  /// l'aggiornamento, `closedPauses` smetteva di essere vuota e i vecchi
  /// totali sparivano di nuovo.
  List<DaySegment> get _pauseSegments {
    int missing(String type, int total) =>
        total -
        closedPauses
            .where((s) => s.type == type)
            .fold(0, (sum, s) => sum + s.durationMins);

    final leaveGap = missing(DaySegment.leave, totalLeavePauseMins);
    final lunchGap = missing(DaySegment.lunch, totalLunchPauseMins);
    final pauseGap = missing(DaySegment.pause, totalStandardPauseMins);
    return [
      ...closedPauses,
      if (leaveGap > 0)
        DaySegment(
          type: DaySegment.leave,
          mins: leaveGap,
          absenceKind: currentLeaveKind,
        ),
      if (lunchGap > 0) DaySegment(type: DaySegment.lunch, mins: lunchGap),
      if (pauseGap > 0) DaySegment(type: DaySegment.pause, mins: pauseGap),
    ];
  }

  /// Costruisce la giornata da salvare a fine turno. Puro: nessuna scrittura,
  /// nessun accesso a Firestore, cosi' e' testabile da solo.
  DailyTimesheet buildEntry({
    required DateTime endTime,
    int bancaOreMins = 0,
    String? boeSlot,
  }) {
    final entry = DailyTimesheet(
      dateId: dateIdOf(startTime!),
      startTime: startTime!,
      endTime: endTime,
      standardPauseMins: 0,
      lunchPauseMins: 0,
      netWorkedMins: 0,
      extraMins: 0,
      boeSlot: boeSlot,
      segments: [
        DaySegment(type: DaySegment.work, start: startTime!, end: endTime),
        ..._pauseSegments,
        if (bancaOreMins > 0)
          DaySegment(type: DaySegment.bancaOre, mins: bancaOreMins),
      ],
    ).recomputedFromSegments(stdMins: standardWorkMins);

    // Tutto lo straordinario positivo va di default in banca ore; l'utente
    // lo puo' spostare dal cartellino.
    return entry.copyWith(
      sboMins: entry.extraMins > 0 ? entry.extraMins : 0,
    );
  }
}

class TimerHeroSnapshot {
  final TimerState state;

  const TimerHeroSnapshot(this.state);

  int get _minuteEpoch =>
      state.currentTime.millisecondsSinceEpoch ~/
      Duration.millisecondsPerMinute;

  // List<DaySegment> non ha == di contenuto (DaySegment non lo definisce), e
  // il default e' per riferimento: confrontarla direttamente reggerebbe solo
  // perche' copyWith preserva l'istanza quando closedPauses non e' passato.
  // Conteggio + durata totale bastano a rilevare un cambiamento reale senza
  // una deep-equals sui segmenti.
  int get _closedPausesCount => state.closedPauses.length;
  int get _closedPausesTotalMins =>
      state.closedPauses.fold(0, (sum, s) => sum + s.durationMins);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimerHeroSnapshot &&
        other.state.status == state.status &&
        other.state.startTime == state.startTime &&
        other.state.currentPauseStart == state.currentPauseStart &&
        other.state.currentPauseType == state.currentPauseType &&
        other.state.totalStandardPauseMins == state.totalStandardPauseMins &&
        other.state.totalLeavePauseMins == state.totalLeavePauseMins &&
        other.state.totalLunchPauseMins == state.totalLunchPauseMins &&
        other.state.standardWorkMins == state.standardWorkMins &&
        other.state.exitNotifMins == state.exitNotifMins &&
        other.state.lastCompletedShift == state.lastCompletedShift &&
        other._closedPausesCount == _closedPausesCount &&
        other._closedPausesTotalMins == _closedPausesTotalMins &&
        other.state.currentLeaveKind == state.currentLeaveKind &&
        other._minuteEpoch == _minuteEpoch;
  }

  @override
  int get hashCode => Object.hash(
    state.status,
    state.startTime,
    state.currentPauseStart,
    state.currentPauseType,
    state.totalStandardPauseMins,
    state.totalLeavePauseMins,
    state.totalLunchPauseMins,
    state.standardWorkMins,
    state.exitNotifMins,
    state.lastCompletedShift,
    _closedPausesCount,
    _closedPausesTotalMins,
    state.currentLeaveKind,
    _minuteEpoch,
  );
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
    closedPauses: remote.closedPauses,
    currentLeaveKind: remote.currentLeaveKind,
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
  closedPauses: state.closedPauses,
  currentLeaveKind: state.currentLeaveKind,
);

class RemoteTimerApplyResult {
  final TimerState state;
  final bool shouldApply;
  final bool shouldSyncRemote;
  final bool shouldDeleteRemote;

  const RemoteTimerApplyResult.apply(
    this.state, {
    this.shouldSyncRemote = false,
  }) : shouldApply = true,
       shouldDeleteRemote = false;
  const RemoteTimerApplyResult.noOp(this.state)
    : shouldApply = false,
      shouldSyncRemote = false,
      shouldDeleteRemote = false;
  const RemoteTimerApplyResult.deleteRemote(this.state)
    : shouldApply = false,
      shouldSyncRemote = false,
      shouldDeleteRemote = true;
}

class RemoteTimerHandshake {
  final Future<TimerState?> Function() _loadLocalState;
  final Future<bool> Function() _loadPendingRemoteSync;
  final Future<bool> Function() _loadClearPending;
  final Future<void> Function() _clearPendingRemoteSync;
  final Future<void> Function() _clearLocalState;
  bool _hasSeenRemoteState = false;
  bool _remoteAbsentConfirmed = false;
  bool _localClearPending = false;
  bool _clearRecoveryInFlight = false;
  bool _clearRecoverySucceeded = false;
  int _generation = 0;
  int? _pendingMutationGeneration;

  bool get canRestoreLocal => !_remoteAbsentConfirmed;
  bool get hasPendingLocalMutation => _pendingMutationGeneration != null;
  bool get hasPendingLocalStart => hasPendingLocalMutation;

  RemoteTimerHandshake({
    Future<TimerState?> Function()? loadLocalState,
    Future<bool> Function()? loadPendingRemoteSync,
    Future<bool> Function()? loadClearPending,
    Future<void> Function()? clearPendingRemoteSync,
    Future<void> Function()? clearLocalState,
  }) : _loadLocalState = loadLocalState ?? loadTimerState,
       _loadPendingRemoteSync =
           loadPendingRemoteSync ?? _hasPendingRemoteTimerSync,
       _loadClearPending = loadClearPending ?? _hasPendingTimerClear,
       _clearPendingRemoteSync =
           clearPendingRemoteSync ?? _clearPendingRemoteTimerSync,
       _clearLocalState = clearLocalState ?? _clearTimerState;

  void markLocalMutation() {
    _generation++;
    _localClearPending = false;
    _clearRecoveryInFlight = false;
    _clearRecoverySucceeded = false;
    _pendingMutationGeneration = _generation;
    _remoteAbsentConfirmed = false;
  }

  void markLocalStart() => markLocalMutation();

  void markLocalClear() {
    _generation++;
    _localClearPending = true;
    _pendingMutationGeneration = null;
  }

  Future<void> clearRemote({
    required Future<void> Function() persistClearIntent,
    required Future<void> Function() deleteRemote,
    required Future<void> Function() rollbackClearIntent,
  }) async {
    final hadPendingLocalMutation = _pendingMutationGeneration != null;
    markLocalClear();
    try {
      await persistClearIntent();
      await deleteRemote();
    } catch (error, stackTrace) {
      try {
        await rollbackClearIntent();
      } finally {
        _generation++;
        _localClearPending = false;
        _pendingMutationGeneration = hadPendingLocalMutation
            ? _generation
            : null;
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> recoverPendingClear(Future<void> Function() deleteRemote) async {
    try {
      await deleteRemote();
      _clearRecoverySucceeded = true;
    } catch (_) {
      _clearRecoverySucceeded = false;
      rethrow;
    } finally {
      _clearRecoveryInFlight = false;
    }
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
    bool hasPendingWrites = false,
    bool isFromCache = false,
  }) async {
    final observedGeneration = _generation;
    if (hasPendingWrites || isFromCache) {
      return RemoteTimerApplyResult.noOp(local);
    }
    if (_localClearPending) {
      return RemoteTimerApplyResult.noOp(local);
    }
    final clearPending = await _loadClearPending();
    if (_generation != observedGeneration) {
      return RemoteTimerApplyResult.noOp(local);
    }
    if (clearPending) {
      if (remote != null) {
        if (_clearRecoveryInFlight || _clearRecoverySucceeded) {
          return RemoteTimerApplyResult.noOp(local);
        }
        _clearRecoveryInFlight = true;
        return RemoteTimerApplyResult.deleteRemote(local);
      }
      await _clearLocalState();
      if (_generation != observedGeneration) {
        return RemoteTimerApplyResult.noOp(local);
      }
      _generation++;
      _hasSeenRemoteState = false;
      _clearRecoveryInFlight = false;
      _clearRecoverySucceeded = false;
      _pendingMutationGeneration = null;
      _remoteAbsentConfirmed = true;
      return RemoteTimerApplyResult.apply(
        applyRemoteTimerState(local: local, remote: null, now: now),
      );
    }
    if (remote != null) {
      final pendingRemoteSync = await _loadPendingRemoteSync();
      if (_generation != observedGeneration) {
        return RemoteTimerApplyResult.noOp(local);
      }
      var expectedLocal = local;
      if (pendingRemoteSync && !expectedLocal.isShiftActive) {
        final persisted = await _loadLocalState();
        if (_generation != observedGeneration) {
          return RemoteTimerApplyResult.noOp(local);
        }
        if (!(persisted?.isShiftActive ?? false)) {
          return RemoteTimerApplyResult.noOp(local);
        }
        expectedLocal = persisted!;
      }
      if ((_pendingMutationGeneration != null || pendingRemoteSync) &&
          !_matchesLocalState(remote, expectedLocal)) {
        return RemoteTimerApplyResult.noOp(local);
      }
      _generation++;
      final appliedGeneration = _generation;
      _hasSeenRemoteState = true;
      _pendingMutationGeneration = null;
      _remoteAbsentConfirmed = false;
      if (pendingRemoteSync) await _clearPendingRemoteSync();
      if (_generation != appliedGeneration) {
        if (_pendingMutationGeneration != null) {
          await _markPendingRemoteTimerSync();
        }
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
      _pendingMutationGeneration = null;
      return RemoteTimerApplyResult.noOp(local);
    }

    if (_pendingMutationGeneration != null) {
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
        _pendingMutationGeneration = _generation;
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
    _pendingMutationGeneration = null;
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
  await prefs.setString(
    _kClosedPauses,
    jsonEncode(s.closedPauses.map((seg) => seg.toMap()).toList()),
  );
  if (s.currentLeaveKind != null) {
    await prefs.setString(_kLeaveKind, s.currentLeaveKind!);
  } else {
    await prefs.remove(_kLeaveKind);
  }
  await prefs.setBool(_kPendingRemoteSync, pendingRemoteSync);
  await prefs.remove(_kClearPending);
}

Future<bool> _hasPendingRemoteTimerSync() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kPendingRemoteSync) ?? false;
}

Future<void> _clearPendingRemoteTimerSync() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kPendingRemoteSync);
}

Future<void> _markPendingRemoteTimerSync() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kPendingRemoteSync, true);
}

Future<void> _markPendingTimerClear() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kClearPending, true);
}

Future<bool> _hasPendingTimerClear() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kClearPending) ?? false;
}

Future<void> _clearPendingTimerClear() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kClearPending);
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
  await prefs.remove(_kClosedPauses);
  await prefs.remove(_kLeaveKind);
  await prefs.remove(_kPendingRemoteSync);
  await prefs.remove(_kClearPending);
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

  // Tollerante: prefs scritte da una versione precedente non hanno la chiave,
  // e un JSON corrotto degrada a lista vuota invece di far fallire il restore.
  var closedPauses = const <DaySegment>[];
  final closedPausesStr = prefs.getString(_kClosedPauses);
  if (closedPausesStr != null) {
    try {
      final decoded = jsonDecode(closedPausesStr);
      if (decoded is List) {
        closedPauses = decoded
            .whereType<Map>()
            .map((m) => DaySegment.fromMap(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (_) {
      // Resta lista vuota.
    }
  }

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
    closedPauses: closedPauses,
    currentLeaveKind: prefs.getString(_kLeaveKind),
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
    await _remoteHandshake.clearRemote(
      persistClearIntent: _markPendingTimerClear,
      deleteRemote: _remoteRepo.clear,
      rollbackClearIntent: _clearPendingTimerClear,
    );
  }

  Future<void> _recoverPendingRemoteClear() async {
    try {
      await _remoteHandshake.recoverPendingClear(_remoteRepo.clear);
    } catch (e, st) {
      AppLog.warning(
        _logTag,
        'pending clear recovery failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _applyRemoteSnapshot(ActiveTimerSnapshot remote) async {
    final before = state;
    final result = await _remoteHandshake.apply(
      local: before,
      remote: remote.data,
      now: DateTime.now(),
      hasPendingWrites: remote.hasPendingWrites,
      isFromCache: remote.isFromCache,
    );
    if (result.shouldDeleteRemote) {
      await _recoverPendingRemoteClear();
      return;
    }
    if (!result.shouldApply) {
      if (_remoteHandshake.hasPendingLocalMutation && state.isShiftActive) {
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
      if (await _hasPendingTimerClear()) {
        saved = null;
        savedFromLocal = false;
      }
      if (saved?.isShiftActive ?? false) {
        savedFromLocal = await _hasPendingRemoteTimerSync();
        if (!savedFromLocal) saved = null;
      }
    } catch (e) {
      // Prefs corrotte (DateTime non parsabile): il restore locale salta,
      // resta il fallback remoto.
      AppLog.warning(_logTag, 'local restore failed', error: e);
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
          remote: remote.data,
          now: DateTime.now(),
          hasPendingWrites: remote.hasPendingWrites,
          isFromCache: remote.isFromCache,
        );
        if (result.shouldDeleteRemote) {
          await _recoverPendingRemoteClear();
          return;
        }
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
    _remoteHandshake.markLocalMutation();
    state = state.copyWith(
      status: WorkState.working,
      startTime: time,
      completedShiftOrNull: null,
    );
    _persistAndSyncRemote();
    _publishStatus('working');
  }

  void startPause(PauseType type, DateTime time, {String? absenceKind}) {
    _remoteHandshake.markLocalMutation();
    state = state.copyWith(
      status: WorkState.paused,
      currentPauseType: type,
      currentPauseStart: time,
      leaveKindOrNull: absenceKind,
    );
    _persistAndSyncRemote();
    _publishStatus('paused');
  }

  void endPause(DateTime time) {
    if (state.currentPauseStart == null) return;
    _remoteHandshake.markLocalMutation();
    state = state.withPauseClosed(time);
    _persistAndSyncRemote();
    _publishStatus('working');
  }

  /// Deficit scoperto in minuti per una data uscita, 0 se non ce n'e'. Serve
  /// alla UI per decidere se proporre il BOE prima di [endTurn]. Passa dalla
  /// stessa giornata che [endTurn] salvera': il permesso copre l'orario
  /// dovuto, e un preventivo che lo ignorasse offrirebbe un esonero per
  /// minuti che non mancano.
  int previewDeficit(DateTime endTime) => state.startTime == null
      ? 0
      : DailyTimesheet.uncoveredDeficitMins(state.buildEntry(endTime: endTime));

  Future<void> endTurn(
    DateTime endTime, {
    int bancaOreMins = 0,
    String? boeSlot,
  }) async {
    if (state.startTime == null) return;

    final record = state.buildEntry(
      endTime: endTime,
      bancaOreMins: bancaOreMins,
      boeSlot: boeSlot,
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
