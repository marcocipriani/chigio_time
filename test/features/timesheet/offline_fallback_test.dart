import 'package:chigio_time/features/timesheet/data/timesheet_repository.dart';
import 'package:chigio_time/features/timesheet/domain/daily_timesheet.dart';
import 'package:flutter_test/flutter_test.dart';

DailyTimesheet _entry(String dateId) => DailyTimesheet(
  dateId: dateId,
  startTime: DateTime.parse('${dateId}T09:00:00'),
  endTime: DateTime.parse('${dateId}T17:36:00'),
  standardPauseMins: 0,
  lunchPauseMins: 30,
  netWorkedMins: 456,
  extraMins: 0,
);

Stream<List<DailyTimesheet>> _failing() =>
    Stream<List<DailyTimesheet>>.error(StateError('firestore giu'));

void main() {
  group('TimesheetRepository.offlineFallback', () {
    test(
      'senza cache (Web) propaga l errore invece di chiudere in silenzio',
      () async {
        // La regressione da impedire: inghiottendo l'errore, lo stream si chiude
        // senza valori e il StreamProvider resta in AsyncLoading per sempre —
        // Home bloccata sullo skeleton, pulsante di riprova irraggiungibile.
        await expectLater(
          TimesheetRepository.offlineFallback(_failing(), null),
          emitsError(isStateError),
        );
      },
    );

    test('con cache serve il mese locale dopo il guasto remoto', () async {
      // La `sink.add` dopo un `await` finiva su uno stream gia chiuso: la
      // cache non arrivava mai a chi ascoltava.
      await expectLater(
        TimesheetRepository.offlineFallback(_failing(), () async {
          await Future<void>.delayed(const Duration(milliseconds: 5));
          return [_entry('2026-05-15')];
        }),
        emitsInOrder([
          [
            isA<DailyTimesheet>().having(
              (e) => e.dateId,
              'dateId',
              '2026-05-15',
            ),
          ],
          emitsDone,
        ]),
      );
    });

    test(
      'se anche la cache fallisce riemerge l errore remoto originale',
      () async {
        await expectLater(
          TimesheetRepository.offlineFallback(
            _failing(),
            () async => throw Exception('drift rotto'),
          ),
          emitsError(isStateError),
        );
      },
    );

    test('senza guasti la sorgente remota passa intatta', () async {
      await expectLater(
        TimesheetRepository.offlineFallback(
          Stream.value([_entry('2026-05-02')]),
          () async => [_entry('2026-05-15')],
        ),
        emitsInOrder([
          [
            isA<DailyTimesheet>().having(
              (e) => e.dateId,
              'dateId',
              '2026-05-02',
            ),
          ],
          emitsDone,
        ]),
      );
    });
  });
}
