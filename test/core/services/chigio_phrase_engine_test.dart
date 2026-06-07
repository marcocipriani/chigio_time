import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/core/services/chigio_phrase_engine.dart';

void main() {
  group('ChigioPhraseEngine', () {
    test('applica genere maschile, femminile, altrə e neutro', () {
      final baseArgs = (
        page: ChigioPage.dashboard,
        firstName: 'Alex',
        shiftState: ChigioShiftState.working,
        seed: 11,
        now: DateTime(2026, 6, 7, 9),
      );

      expect(
        ChigioPhraseEngine.resolve(
          page: baseArgs.page,
          firstName: baseArgs.firstName,
          shiftState: baseArgs.shiftState,
          gender: 'M',
          seed: baseArgs.seed,
          now: baseArgs.now,
        ).phrase,
        contains('pronto'),
      );
      expect(
        ChigioPhraseEngine.resolve(
          page: baseArgs.page,
          firstName: baseArgs.firstName,
          shiftState: baseArgs.shiftState,
          gender: 'F',
          seed: baseArgs.seed,
          now: baseArgs.now,
        ).phrase,
        contains('pronta'),
      );
      expect(
        ChigioPhraseEngine.resolve(
          page: baseArgs.page,
          firstName: baseArgs.firstName,
          shiftState: baseArgs.shiftState,
          gender: 'A',
          seed: baseArgs.seed,
          now: baseArgs.now,
        ).phrase,
        contains('prontə'),
      );
      expect(
        ChigioPhraseEngine.resolve(
          page: baseArgs.page,
          firstName: baseArgs.firstName,
          shiftState: baseArgs.shiftState,
          gender: 'N',
          seed: baseArgs.seed,
          now: baseArgs.now,
        ).phrase,
        contains('in forma'),
      );
    });

    test('prima delle 5 usa il pool serale, non quello mattutino', () {
      final data = ChigioPhraseEngine.resolve(
        page: ChigioPage.dashboard,
        firstName: 'Marco',
        shiftState: ChigioShiftState.notStarted,
        seed: 0,
        now: DateTime(2026, 6, 7, 3),
      );

      expect(data.phrase, contains('è tardi'));
      expect(data.phrase, isNot(contains('Buongiorno')));
    });

    test('usa il Dipartimento in forma compatta quando previsto dal seed', () {
      final data = ChigioPhraseEngine.resolveContext(
        ChigioContext(
          page: ChigioPage.dashboard,
          firstName: 'Marco',
          shiftState: ChigioShiftState.working,
          department: 'Dipartimento per la trasformazione digitale',
          seed: 0,
          now: DateTime(2026, 6, 7, 9),
        ),
      );

      expect(data.phrase, contains('Trasformazione digitale'));
      expect(data.phrase, isNot(contains('Dipartimento per')));
    });

    test('usa la sede in forma compatta quando prevista dal seed', () {
      final data = ChigioPhraseEngine.resolveContext(
        ChigioContext(
          page: ChigioPage.dashboard,
          firstName: 'Marco',
          site: 'Palazzo Chigi / Via della Mercede, 96',
          seed: 3,
          now: DateTime(2026, 6, 7, 9),
        ),
      );

      expect(data.phrase, contains('Chigi/Mercede'));
    });

    test('usa minuti rimanenti e lavorati per i milestone del turno', () {
      final exitSoon = ChigioPhraseEngine.resolveContext(
        ChigioContext(
          page: ChigioPage.dashboard,
          firstName: 'Marco',
          shiftState: ChigioShiftState.working,
          remainingMins: 12,
          workedMins: 444,
          standardWorkMins: 456,
          mealVoucherThresholdMins: 380,
          seed: 0,
          now: DateTime(2026, 6, 7, 16),
        ),
      );
      final overtime = ChigioPhraseEngine.resolveContext(
        ChigioContext(
          page: ChigioPage.dashboard,
          firstName: 'Marco',
          shiftState: ChigioShiftState.working,
          remainingMins: -8,
          workedMins: 464,
          standardWorkMins: 456,
          mealVoucherThresholdMins: 380,
          seed: 0,
          now: DateTime(2026, 6, 7, 18),
        ),
      );

      expect(exitSoon.phrase, contains('12 min'));
      expect(overtime.phrase, contains('Straordinario'));
    });

    test('usa tipo giornata, venerdì e motivazione', () {
      final remote = ChigioPhraseEngine.resolveContext(
        ChigioContext(
          page: ChigioPage.dashboard,
          firstName: 'Marco',
          dayType: ChigioDayType.remote,
          seed: 1,
          now: DateTime(2026, 6, 7, 9),
        ),
      );
      final friday = ChigioPhraseEngine.resolveContext(
        ChigioContext(
          page: ChigioPage.dashboard,
          firstName: 'Marco',
          seed: 5,
          now: DateTime(2026, 6, 5, 9),
        ),
      );
      final motivational = ChigioPhraseEngine.resolveContext(
        ChigioContext(
          page: ChigioPage.dashboard,
          firstName: 'Marco',
          seed: 2,
          now: DateTime(2026, 6, 7, 9),
        ),
      );

      expect(remote.phrase.toLowerCase(), contains('remoto'));
      expect(friday.phrase.toLowerCase(), contains('weekend'));
      expect(motivational.phrase, contains('Piccoli minuti'));
    });

    test('non lascia marker grezzi e resta nel budget header', () {
      const pages = ChigioPage.values;
      const shiftStates = ChigioShiftState.values;
      const dayTypes = ChigioDayType.values;
      const genders = ['M', 'F', 'A', 'N'];
      const department =
          'Ufficio del bilancio e per il riscontro di regolarità '
          'amministrativo-contabile';
      const site = 'Palazzo Chigi / Via della Mercede, 96';
      final hours = [3, 9, 14, 19];
      final remainingValues = [10, 45, 120, -5];

      for (final page in pages) {
        for (final shiftState in shiftStates) {
          for (final dayType in dayTypes) {
            for (final gender in genders) {
              for (final hour in hours) {
                for (final remaining in remainingValues) {
                  for (var seed = 0; seed < 32; seed++) {
                    final data = ChigioPhraseEngine.resolveContext(
                      ChigioContext(
                        page: page,
                        firstName: 'Alessandro',
                        shiftState: shiftState,
                        gender: gender,
                        department: department,
                        site: site,
                        dayType: dayType,
                        workedMins: 390,
                        remainingMins: remaining,
                        standardWorkMins: 456,
                        mealVoucherThresholdMins: 380,
                        seed: seed,
                        now: DateTime(2026, 6, 7, hour),
                      ),
                    );

                    expect(data.phrase, isNot(contains('{')));
                    expect(data.phrase, isNot(contains('}')));
                    expect(data.phrase.length, lessThanOrEqualTo(76));
                    expect(data.label.length, lessThanOrEqualTo(17));
                  }
                }
              }
            }
          }
        }
      }
    });
  });
}
