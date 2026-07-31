import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/features/timesheet/domain/absence_consumption.dart';
import 'package:chigio_time/features/timesheet/domain/absence_kind.dart';
import 'package:chigio_time/features/timesheet/domain/daily_timesheet.dart';
import 'package:chigio_time/features/timesheet/domain/day_segment.dart';
import 'package:chigio_time/features/timesheet/domain/manual_day_entry.dart';

DateTime _at(int h, int m) => DateTime(2026, 7, 23, h, m);

/// Giornata timbrata come la costruisce la timeline: lavoro 9–17, un permesso
/// per visita specialistica 12–13, la pausa pranzo 13–13:30 e mezz'ora di
/// esonero da banca ore senza posizione.
DailyTimesheet _fullDay() => DailyTimesheet(
  dateId: '2026-07-23',
  startTime: _at(9, 0),
  endTime: _at(17, 0),
  standardPauseMins: 0,
  lunchPauseMins: 0,
  netWorkedMins: 0,
  extraMins: 0,
  workType: WorkType.presence,
  segments: [
    DaySegment(type: DaySegment.work, start: _at(9, 0), end: _at(17, 0)),
    DaySegment(
      type: DaySegment.leave,
      start: _at(12, 0),
      end: _at(13, 0),
      absenceKind: AbsenceKind.specialistVisit,
    ),
    DaySegment(type: DaySegment.lunch, start: _at(13, 0), end: _at(13, 30)),
    DaySegment(type: DaySegment.bancaOre, mins: 30),
  ],
).recomputedFromSegments(stdMins: 456);

/// Il giorno dopo, timbrato con la sola pausa pranzo: e' la giornata su cui
/// si salva quando lo sheet e' stato aperto altrove.
DailyTimesheet _lunchDay24() => DailyTimesheet(
  dateId: '2026-07-24',
  startTime: DateTime(2026, 7, 24, 9),
  endTime: DateTime(2026, 7, 24, 17),
  standardPauseMins: 0,
  lunchPauseMins: 0,
  netWorkedMins: 0,
  extraMins: 0,
  workType: WorkType.presence,
  segments: [
    DaySegment(
      type: DaySegment.work,
      start: DateTime(2026, 7, 24, 9),
      end: DateTime(2026, 7, 24, 17),
    ),
    DaySegment(
      type: DaySegment.lunch,
      start: DateTime(2026, 7, 24, 13),
      end: DateTime(2026, 7, 24, 13, 30),
    ),
  ],
).recomputedFromSegments(stdMins: 456);

void main() {
  group('buildManualDayEntry', () {
    test('correggere l uscita non cancella permesso, pausa ed esonero', () {
      final before = _fullDay();
      expect(before.netWorkedMins, 390); // guardia sulla premessa

      final result = buildManualDayEntry(
        dateId: '2026-07-23',
        start: _at(9, 0),
        end: _at(18, 0), // l'utente corregge la sola uscita
        workType: WorkType.presence,
        stdMins: 456,
        existingDays: [before],
      );

      final after = result.entry!;
      expect(result.error, isNull);
      expect(after.leavePauseMins, 60);
      expect(after.lunchPauseMins, 30);
      expect(after.bancaOreMins, 30);
      // Span 540 − 60 permesso − 30 pranzo = 450 netti, non 480.
      expect(after.netWorkedMins, 450);
      // La causale resta sul segmento, quindi il plafond continua a scalare.
      expect(
        computeAbsenceConsumption(
          year: 2026,
          entries: [after],
        ).minsFor(AbsenceKind.specialistVisit),
        60,
      );
    });

    test('orari che non contengono piu una pausa: errore, non salvata', () {
      final result = buildManualDayEntry(
        dateId: '2026-07-23',
        start: _at(9, 0),
        end: _at(12, 0), // la pausa pranzo 13:00–13:30 resta fuori
        workType: WorkType.presence,
        stdMins: 456,
        existingDays: [_fullDay()],
      );

      expect(result.entry, isNull);
      expect(result.error, contains('fuori dallo span'));
    });

    test('cambiare giorno non trascina i segmenti di quello vecchio', () {
      final result = buildManualDayEntry(
        dateId: '2026-07-24',
        start: DateTime(2026, 7, 24, 9),
        end: DateTime(2026, 7, 24, 17),
        workType: WorkType.presence,
        stdMins: 456,
        existingDays: [_fullDay()], // solo il 23 luglio e' timbrato
      );

      expect(result.entry!.segments.map((s) => s.type), [DaySegment.work]);
      expect(result.entry!.leavePauseMins, 0);
    });

    test('i segmenti conservati sono quelli del giorno di destinazione', () {
      // "Aggiungi giornata" apre lo sheet senza nessuna giornata, e il giorno
      // di default puo' essere gia' timbrato; lo stesso vale cambiando giorno
      // da dentro lo sheet. Conta la giornata su cui si salva, non quella con
      // cui lo sheet e' stato aperto: la validazione non protegge, perche'
      // una lista col solo `work` e' valida.
      final result = buildManualDayEntry(
        dateId: '2026-07-24',
        start: DateTime(2026, 7, 24, 9),
        end: DateTime(2026, 7, 24, 18), // l'utente corregge la sola uscita
        workType: WorkType.presence,
        stdMins: 456,
        existingDays: [_fullDay(), _lunchDay24()],
      );

      final after = result.entry!;
      expect(result.error, isNull);
      expect(after.lunchPauseMins, 30); // la pausa del 24 resta
      expect(after.leavePauseMins, 0); // il permesso del 23 non si trascina
      expect(after.netWorkedMins, 510); // span 540 − 30, non 540
    });

    test('una giornata non timbrata non ha segmenti', () {
      final ferie = buildManualDayEntry(
        dateId: '2026-07-23',
        start: _at(9, 0),
        end: _at(17, 0),
        workType: WorkType.holiday,
        stdMins: 456,
        existingDays: [_fullDay()],
      ).entry!;
      expect(ferie.segments, isEmpty);

      final permesso = buildManualDayEntry(
        dateId: '2026-07-23',
        start: _at(9, 0),
        end: _at(17, 0),
        workType: WorkType.leave,
        stdMins: 456,
        existingDays: [_fullDay()],
        absenceKind: AbsenceKind.sickness,
        absenceUnit: AbsenceUnit.daily,
        absenceDays: 1,
      ).entry!;
      expect(permesso.segments, isEmpty);
      expect(permesso.absenceDays, 1);
      expect(permesso.countsAsSicknessPeriod, isTrue);
    });

    test('smart working: orario dichiarato, nessun segmento', () {
      final sw = buildManualDayEntry(
        dateId: '2026-07-23',
        start: _at(11, 0),
        end: _at(19, 0),
        workType: WorkType.remote,
        stdMins: 456,
        existingDays: [_fullDay()],
      ).entry!;

      expect(sw.startTime, _at(9, 0));
      expect(sw.netWorkedMins, 456);
      expect(sw.segments, isEmpty);
    });
  });
}
