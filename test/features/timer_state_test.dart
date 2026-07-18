import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chigio_time/core/utils/date_utils.dart';
import 'package:chigio_time/features/dashboard/data/active_timer_repository.dart';
import 'package:chigio_time/features/dashboard/presentation/timer_provider.dart';

// M5 (review 2026-07-05): il calcolo dell'uscita prevista — inclusa la
// regola CCNL del pranzo forzato a 3 zone — era la logica più critica
// senza alcun test. TimerState è puro: niente Firebase, niente mock.
void main() {
  final start = DateTime(2026, 7, 6, 9, 0); // lunedì 09:00
  const std = 456; // Ruolo 7h36

  TimerState at(
    int minsFromStart, {
    int lunch = 0,
    int stdPause = 0,
    int leave = 0,
    DateTime? pauseStart,
    PauseType pauseType = PauseType.none,
  }) => TimerState(
    status: WorkState.working,
    startTime: start,
    currentTime: start.add(Duration(minutes: minsFromStart)),
    standardWorkMins: std,
    totalLunchPauseMins: lunch,
    totalStandardPauseMins: stdPause,
    totalLeavePauseMins: leave,
    currentPauseStart: pauseStart,
    currentPauseType: pauseType,
  );

  group('expectedExitTime — pranzo forzato a 3 zone', () {
    test('senza startTime niente uscita prevista', () {
      final s = TimerState(currentTime: DateTime.now());
      expect(s.expectedExitTime, isNull);
      expect(s.remainingTime, isNull);
    });

    test('zona 1: turno normale, nessun pranzo forzato', () {
      // 60 min trascorsi, nessuna pausa → uscita = 09:00 + 7h36 = 16:36
      expect(at(60).expectedExitTime, start.add(const Duration(minutes: 456)));
    });

    test('zona 2 (540–570): pranzo forzato = eccedenza oltre 540', () {
      // 555 min effettivi → forzati 15 → uscita 09:00 + 456 + 15
      expect(
        at(555).expectedExitTime,
        start.add(const Duration(minutes: 456 + 15)),
      );
    });

    test('zona 3 (>=570): pranzo forzato pieno = 30', () {
      expect(
        at(580).expectedExitTime,
        start.add(const Duration(minutes: 456 + 30)),
      );
    });

    test('pranzo già consumato (30) → mai forzatura extra', () {
      // Il pranzo consumato allunga l'uscita di 30, non di 60.
      expect(
        at(580, lunch: 30).expectedExitTime,
        start.add(const Duration(minutes: 456 + 30)),
      );
    });

    test('pranzo parziale (20) in zona 3 → integrazione a 30', () {
      // 20 presi + 10 forzati = uscita +30 totale.
      expect(
        at(580, lunch: 20).expectedExitTime,
        start.add(const Duration(minutes: 456 + 30)),
      );
    });

    test('pausa pranzo IN CORSO ≥30 min conta come pranzo preso', () {
      final s = at(
        300,
        pauseStart: start.add(const Duration(minutes: 260)), // 40 min fa
        pauseType: PauseType.lunch,
      );
      // ongoing 40 min si somma all'uscita, nessuna forzatura aggiuntiva.
      expect(s.expectedExitTime, start.add(const Duration(minutes: 456 + 40)));
    });

    test(
      'pause caffè/permesso allungano l\'uscita e NON contano nel pranzo',
      () {
        expect(
          at(100, stdPause: 15).expectedExitTime,
          start.add(const Duration(minutes: 456 + 15)),
        );
        expect(
          at(100, leave: 60).expectedExitTime,
          start.add(const Duration(minutes: 456 + 60)),
        );
        // 560 trascorsi ma 15 di pausa caffè → effettivi 545 → forzati 5.
        expect(
          at(560, stdPause: 15).expectedExitTime,
          start.add(const Duration(minutes: 456 + 15 + 5)),
        );
      },
    );
  });

  group('exitReminderAt', () {
    test('working = uscita prevista meno anticipo', () {
      final state = at(60).copyWith(exitNotifMins: 15);
      expect(state.exitReminderAt, DateTime(2026, 7, 6, 16, 21));
    });

    test('disabilitato o in pausa non schedula', () {
      expect(at(60).copyWith(exitNotifMins: 0).exitReminderAt, isNull);
      final paused = TimerState(
        status: WorkState.paused,
        startTime: start,
        currentPauseStart: start.add(const Duration(hours: 1)),
        currentPauseType: PauseType.short,
        currentTime: start.add(const Duration(hours: 2)),
        standardWorkMins: std,
        exitNotifMins: 15,
      );
      expect(paused.exitReminderAt, isNull);
    });
  });

  group('persistenza reminder', () {
    test('serializza Timestamp e anticipo nel documento completo', () {
      final reminderAt = DateTime(2026, 7, 6, 16, 21);
      final data = ActiveTimerData(
        status: 'working',
        startTime: start,
        reminderAt: reminderAt,
        reminderLeadMins: 15,
      );

      final payload = ActiveTimerRepository.toFirestore(
        data,
        dateId: '2026-07-06',
      );

      expect(payload['reminderAt'], isA<Timestamp>());
      expect((payload['reminderAt'] as Timestamp).toDate(), reminderAt);
      expect(payload['reminderLeadMins'], 15);
    });

    test('omette reminderAt quando pausa o disabilitazione lo annullano', () {
      final payload = ActiveTimerRepository.toFirestore(
        ActiveTimerData(
          status: 'paused',
          startTime: start,
          reminderLeadMins: 0,
        ),
        dateId: '2026-07-06',
      );

      expect(payload, isNot(contains('reminderAt')));
      expect(payload['reminderLeadMins'], 0);
    });

    test('blocca update reminder se lo stato remoto è avanzato a pausa', () {
      final staleWorking = ActiveTimerData(
        status: 'working',
        startTime: start,
        reminderAt: DateTime(2026, 7, 6, 16, 21),
        reminderLeadMins: 15,
      );
      final pausedPayload = ActiveTimerRepository.toFirestore(
        ActiveTimerData(
          status: 'paused',
          startTime: start,
          pauseStart: start.add(const Duration(hours: 2)),
          pauseType: 'short',
          reminderLeadMins: 15,
        ),
        dateId: '2026-07-06',
      );

      expect(
        ActiveTimerRepository.matchesPersistedState(
          pausedPayload,
          staleWorking,
          dateId: '2026-07-06',
        ),
        isFalse,
      );
    });
  });

  group('restore e sync profilo', () {
    test('restore conserva i valori profilo correnti per anticipo 0/5/30', () {
      final restored = at(
        60,
      ).copyWith(standardWorkMins: 456, exitNotifMins: 15);

      for (final lead in [0, 5, 30]) {
        final current = TimerState(
          currentTime: start,
          standardWorkMins: 372,
          exitNotifMins: lead,
        );
        final merged = mergeRestoredTimerState(
          restored: restored,
          current: current,
        );

        expect(merged.status, WorkState.working);
        expect(merged.startTime, start);
        expect(merged.standardWorkMins, 372);
        expect(merged.exitNotifMins, lead);
      }
    });

    test('cambio durata standard o anticipo richiede reschedule', () {
      final current = at(60).copyWith(exitNotifMins: 15);

      final standardChanged = computeTimerProfileUpdate(
        current,
        standardWorkMins: 480,
        exitNotifMins: 15,
      );
      expect(standardChanged.shouldUpdateReminder, isTrue);
      expect(standardChanged.state.standardWorkMins, 480);

      final leadChanged = computeTimerProfileUpdate(
        current,
        standardWorkMins: std,
        exitNotifMins: 5,
      );
      expect(leadChanged.shouldUpdateReminder, isTrue);
      expect(leadChanged.state.exitNotifMins, 5);

      final unchanged = computeTimerProfileUpdate(
        current,
        standardWorkMins: std,
        exitNotifMins: 15,
      );
      expect(unchanged.shouldUpdateReminder, isFalse);
    });

    test(
      'watch riflette start, pausa e ripresa remoti senza perdere profilo',
      () {
        var local = TimerState(
          currentTime: start,
          standardWorkMins: 372,
          exitNotifMins: 5,
        );
        local = applyRemoteTimerState(
          local: local,
          remote: ActiveTimerData(status: 'working', startTime: start),
          now: start.add(const Duration(minutes: 1)),
        );
        expect(local.status, WorkState.working);

        local = applyRemoteTimerState(
          local: local,
          remote: ActiveTimerData(
            status: 'paused',
            startTime: start,
            pauseStart: start.add(const Duration(hours: 1)),
            pauseType: 'short',
          ),
          now: start.add(const Duration(hours: 1)),
        );
        expect(local.status, WorkState.paused);
        expect(local.exitReminderAt, isNull);

        local = applyRemoteTimerState(
          local: local,
          remote: ActiveTimerData(
            status: 'working',
            startTime: start,
            stdPauseMins: 10,
          ),
          now: start.add(const Duration(hours: 1, minutes: 10)),
        );
        expect(local.status, WorkState.working);
        expect(local.totalStandardPauseMins, 10);
        expect(local.standardWorkMins, 372);
        expect(local.exitNotifMins, 5);
        expect(local.exitReminderAt, isNotNull);
      },
    );
  });

  group('handshake null remoto', () {
    Map<String, Object> persistedWorking({
      DateTime? startTime,
      bool pendingRemoteSync = false,
    }) => {
      'timer_date': todayId(),
      'timer_status': WorkState.working.name,
      'timer_startTime': (startTime ?? start).toIso8601String(),
      'timer_stdPauseMins': 0,
      'timer_leavePauseMins': 0,
      'timer_lunchPauseMins': 0,
      'timer_pauseType': PauseType.none.name,
      'timer_pendingRemoteSync': pendingRemoteSync,
    };

    test(
      'primo null preserva prefs attive Web offline e richiede resync',
      () async {
        SharedPreferences.setMockInitialValues(
          persistedWorking(pendingRemoteSync: true),
        );
        final handshake = RemoteTimerHandshake();

        final result = await handshake.apply(
          local: TimerState(currentTime: start),
          remote: null,
          now: start,
        );

        expect(result.state.status, WorkState.working);
        expect(result.state.startTime, start);
        expect(result.shouldSyncRemote, isTrue);
        expect(handshake.hasPendingLocalStart, isTrue);
        expect(handshake.canRestoreLocal, isTrue);
        expect((await loadTimerState())?.status, WorkState.working);
      },
    );

    test('primo null elimina prefs attive senza pending remote sync', () async {
      SharedPreferences.setMockInitialValues(persistedWorking());
      final handshake = RemoteTimerHandshake();

      final result = await handshake.apply(
        local: TimerState(currentTime: start),
        remote: null,
        now: start,
      );

      expect(result.state.status, WorkState.notStarted);
      expect(result.shouldSyncRemote, isFalse);
      expect(await loadTimerState(), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('timer_pendingRemoteSync'), isFalse);
    });

    test('primo null non annulla uno start locale in gara', () async {
      SharedPreferences.setMockInitialValues(
        persistedWorking(pendingRemoteSync: true),
      );
      final handshake = RemoteTimerHandshake()..markLocalStart();
      final local = TimerState(
        status: WorkState.working,
        startTime: start,
        currentTime: start,
      );

      final next = (await handshake.apply(
        local: local,
        remote: null,
        now: start,
      )).state;

      expect(next.status, WorkState.working);
      expect(next.startTime, start);
      expect(handshake.canRestoreLocal, isTrue);
      expect((await loadTimerState())?.status, WorkState.working);
    });

    test('null del delete locale non risincronizza un turno pending', () async {
      SharedPreferences.setMockInitialValues(
        persistedWorking(pendingRemoteSync: true),
      );
      final handshake = RemoteTimerHandshake()..markLocalClear();
      final local = TimerState(
        status: WorkState.working,
        startTime: start,
        currentTime: start,
      );

      final result = await handshake.apply(
        local: local,
        remote: null,
        now: start,
      );

      expect(result.shouldApply, isFalse);
      expect(result.shouldSyncRemote, isFalse);
      expect(result.state.startTime, start);
      expect((await loadTimerState())?.status, WorkState.working);
    });

    test('null dopo non-null azzera stato e prefs anche al restart', () async {
      SharedPreferences.setMockInitialValues(
        persistedWorking(pendingRemoteSync: true),
      );
      final handshake = RemoteTimerHandshake();
      var local = (await handshake.apply(
        local: TimerState(currentTime: start),
        remote: ActiveTimerData(status: 'working', startTime: start),
        now: start,
      )).state;
      expect(local.status, WorkState.working);

      local = (await handshake.apply(
        local: local,
        remote: null,
        now: start.add(const Duration(minutes: 1)),
      )).state;

      expect(local.status, WorkState.notStarted);
      expect(await loadTimerState(), isNull);
    });

    test('null preserva completed e abandoned locali', () async {
      SharedPreferences.setMockInitialValues(persistedWorking());
      for (final status in [WorkState.completed, WorkState.abandoned]) {
        final next = (await RemoteTimerHandshake().apply(
          local: TimerState(status: status, currentTime: start),
          remote: null,
          now: start,
        )).state;
        expect(next.status, status);
      }
    });

    test(
      'primo null preserva abandoned persistito prima del restore',
      () async {
        final persisted = persistedWorking();
        persisted['timer_status'] = WorkState.abandoned.name;
        SharedPreferences.setMockInitialValues(persisted);

        await RemoteTimerHandshake().apply(
          local: TimerState(currentTime: start),
          remote: null,
          now: start,
        );

        expect((await loadTimerState())?.status, WorkState.abandoned);
      },
    );

    test('non-null poi nuovo start ignora un null ritardato', () async {
      final newStart = start.add(const Duration(hours: 1));
      SharedPreferences.setMockInitialValues(
        persistedWorking(startTime: newStart, pendingRemoteSync: true),
      );
      final handshake = RemoteTimerHandshake();
      await handshake.apply(
        local: TimerState(currentTime: start),
        remote: ActiveTimerData(status: 'working', startTime: start),
        now: start,
      );
      handshake.markLocalStart();
      final local = TimerState(
        status: WorkState.working,
        startTime: newStart,
        currentTime: newStart,
      );

      final next = (await handshake.apply(
        local: local,
        remote: null,
        now: newStart,
      )).state;

      expect(next.startTime, newStart);
      expect(handshake.hasPendingLocalStart, isTrue);
      expect((await loadTimerState())?.startTime, newStart);
    });

    test('start locale durante await rende il null una no-op', () async {
      final load = Completer<TimerState?>();
      var clearCalls = 0;
      final handshake = RemoteTimerHandshake(
        loadLocalState: () => load.future,
        clearLocalState: () async {
          clearCalls++;
        },
      );
      final initial = TimerState(currentTime: start);
      final pendingNull = handshake.apply(
        local: initial,
        remote: null,
        now: start,
      );
      await Future<void>.delayed(Duration.zero);

      handshake.markLocalStart();
      load.complete(
        TimerState(
          status: WorkState.working,
          startTime: start,
          currentTime: start,
        ),
      );
      final result = await pendingNull;

      expect(result.shouldApply, isFalse);
      expect(identical(result.state, initial), isTrue);
      expect(handshake.hasPendingLocalStart, isTrue);
      expect(handshake.canRestoreLocal, isTrue);
      expect(clearCalls, 0);
    });

    test(
      'echo vecchio resta ignorato, echo corrispondente libera pending',
      () async {
        final newStart = start.add(const Duration(hours: 1));
        SharedPreferences.setMockInitialValues(
          persistedWorking(startTime: newStart, pendingRemoteSync: true),
        );
        final handshake = RemoteTimerHandshake();
        await handshake.apply(
          local: TimerState(currentTime: start),
          remote: ActiveTimerData(status: 'working', startTime: start),
          now: start,
        );
        handshake.markLocalStart();
        var prefs = await SharedPreferences.getInstance();
        await prefs.setBool('timer_pendingRemoteSync', true);
        final local = TimerState(
          status: WorkState.working,
          startTime: newStart,
          currentTime: newStart,
        );

        final afterOldEcho = await handshake.apply(
          local: local,
          remote: ActiveTimerData(status: 'working', startTime: start),
          now: newStart,
        );
        expect(afterOldEcho.shouldApply, isFalse);
        expect(afterOldEcho.state.startTime, newStart);
        expect(handshake.hasPendingLocalStart, isTrue);
        expect(prefs.getBool('timer_pendingRemoteSync'), isTrue);

        final afterMatchingEcho = await handshake.apply(
          local: local,
          remote: ActiveTimerData(status: 'working', startTime: newStart),
          now: newStart,
        );
        expect(afterMatchingEcho.shouldApply, isTrue);
        expect(afterMatchingEcho.state.startTime, newStart);
        expect(handshake.hasPendingLocalStart, isFalse);
        prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('timer_pendingRemoteSync') ?? false, isFalse);
      },
    );

    test('null async superseded non sovrascrive echo matching', () async {
      final load = Completer<TimerState?>();
      final handshake = RemoteTimerHandshake(
        loadLocalState: () => load.future,
        clearLocalState: () async {},
      );
      final initial = TimerState(currentTime: start);
      final pendingNull = handshake.apply(
        local: initial,
        remote: null,
        now: start,
      );
      await Future<void>.delayed(Duration.zero);

      final newStart = start.add(const Duration(hours: 1));
      handshake.markLocalStart();
      var current = TimerState(
        status: WorkState.working,
        startTime: newStart,
        currentTime: newStart,
      );
      final echo = await handshake.apply(
        local: current,
        remote: ActiveTimerData(status: 'working', startTime: newStart),
        now: newStart,
      );
      expect(echo.shouldApply, isTrue);
      current = echo.state;

      load.complete(null);
      final supersededNull = await pendingNull;
      expect(supersededNull.shouldApply, isFalse);
      if (supersededNull.shouldApply) current = supersededNull.state;

      expect(current.status, WorkState.working);
      expect(current.startTime, newStart);
    });
  });

  group('clear timer remoto', () {
    test('repository attende il delete Firestore', () {
      final source = File(
        'lib/features/dashboard/data/active_timer_repository.dart',
      ).readAsStringSync();

      expect(source.contains('await doc.delete();'), isTrue);
      expect(source.contains('_doc?.delete().ignore()'), isFalse);
    });

    test('fine e reset cancellano remoto prima delle prefs locali', () {
      final source = File(
        'lib/features/dashboard/presentation/timer_provider.dart',
      ).readAsStringSync();
      final remoteThenLocal = RegExp(
        r'await _clearRemoteTimer\(\);\s+await _clearTimerState\(\);',
      );

      expect(source.contains('_remoteHandshake.markLocalClear();'), isTrue);
      expect(remoteThenLocal.allMatches(source).length, 2);
    });
  });

  group('remainingTime / stato', () {
    test('remainingTime = uscita prevista − adesso', () {
      final s = at(60);
      expect(s.remainingTime, const Duration(minutes: 456 - 60));
    });

    test('isShiftActive solo per working/paused', () {
      expect(at(10).isShiftActive, isTrue);
      final paused = TimerState(
        status: WorkState.paused,
        startTime: start,
        currentTime: start,
      );
      expect(paused.isShiftActive, isTrue);
      for (final st in [
        WorkState.notStarted,
        WorkState.completed,
        WorkState.abandoned,
      ]) {
        expect(
          TimerState(status: st, currentTime: start).isShiftActive,
          isFalse,
        );
      }
    });

    test('copyWith: i sentinel azzerano davvero i campi nullable', () {
      final s = at(60, pauseStart: start, pauseType: PauseType.short);
      final cleared = s.copyWith(pauseStartOrNull: null);
      expect(cleared.currentPauseStart, isNull);
      // Senza sentinel il valore resta.
      expect(s.copyWith().currentPauseStart, start);
    });
  });
}
