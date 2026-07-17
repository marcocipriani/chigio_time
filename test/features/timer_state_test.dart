import 'package:flutter_test/flutter_test.dart';

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
