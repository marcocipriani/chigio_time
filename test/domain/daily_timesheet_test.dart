import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/features/timesheet/domain/daily_timesheet.dart';
import 'package:chigio_time/features/timesheet/domain/absence_kind.dart';
import 'package:chigio_time/features/timesheet/domain/day_segment.dart';

void main() {
  group('DailyTimesheet', () {
    test('getter tipo giornata', () {
      DailyTimesheet base(String? t) => DailyTimesheet(
        dateId: '2026-06-01',
        startTime: DateTime(2026, 6, 1, 9),
        endTime: DateTime(2026, 6, 1, 17),
        standardPauseMins: 0,
        lunchPauseMins: 30,
        netWorkedMins: 450,
        extraMins: 0,
        workType: t,
      );
      expect(base(WorkType.remote).isRemote, isTrue);
      expect(base(WorkType.leave).isLeave, isTrue);
      expect(base(WorkType.holiday).isHoliday, isTrue);
      expect(base(WorkType.presence).isRemote, isFalse);
      expect(base(null).isLeave, isFalse); // null = presence backward-compat
    });

    test('toMap/fromMap round-trip conserva i campi chiave', () {
      final entry = DailyTimesheet(
        dateId: '2026-06-02',
        startTime: DateTime(2026, 6, 2, 9, 0),
        endTime: DateTime(2026, 6, 2, 17, 36),
        standardPauseMins: 0,
        lunchPauseMins: 30,
        netWorkedMins: 456,
        extraMins: 20,
        sliMins: 12,
        sboMins: 8,
        workType: WorkType.presence,
        note: 'Meeting',
      );
      final back = DailyTimesheet.fromMap(entry.toMap());
      expect(back.dateId, entry.dateId);
      expect(back.netWorkedMins, 456);
      expect(back.extraMins, 20);
      expect(back.sliMins, 12);
      expect(back.sboMins, 8);
      expect(back.workType, WorkType.presence);
      expect(back.note, 'Meeting');
    });

    test('fromMap tollera start/end mancanti o corrotti (no throw)', () {
      // Un doc legacy/corrotto non deve far crashare l'intero stream timesheet.
      DailyTimesheet parse(Map<String, dynamic> m) => DailyTimesheet.fromMap(m);

      // startTime/endTime assenti → fallback alla mezzanotte del dateId.
      final missing = parse({'dateId': '2026-06-04', 'netWorkedMins': 100});
      expect(missing.startTime, DateTime(2026, 6, 4));
      expect(missing.endTime, DateTime(2026, 6, 4));
      expect(missing.netWorkedMins, 100);

      // Valori non-stringa / non parsabili → nessuna eccezione.
      expect(
        () => parse({'dateId': '2026-06-05', 'startTime': 12345}),
        returnsNormally,
      );
      expect(
        () => parse({'dateId': 'corrotto', 'startTime': 'non-una-data'}),
        returnsNormally,
      );

      // dateId valido + start valido → parsing normale preservato.
      final ok = parse({
        'dateId': '2026-06-06',
        'startTime': DateTime(2026, 6, 6, 9).toIso8601String(),
        'endTime': DateTime(2026, 6, 6, 17).toIso8601String(),
      });
      expect(ok.startTime, DateTime(2026, 6, 6, 9));
      expect(ok.endTime, DateTime(2026, 6, 6, 17));
    });

    test('round-trip di una giornata di permesso con causale', () {
      final entry = DailyTimesheet(
        dateId: '2026-06-03',
        startTime: DateTime(2026, 6, 3, 9),
        endTime: DateTime(2026, 6, 3, 12),
        standardPauseMins: 0,
        lunchPauseMins: 0,
        netWorkedMins: 0,
        extraMins: 0,
        workType: WorkType.leave,
        absenceKind: AbsenceKind.specialistVisit,
        absenceUnit: AbsenceUnit.hourly,
        absenceMins: 180,
      );
      final back = DailyTimesheet.fromMap(entry.toMap());
      expect(back.workType, WorkType.leave);
      expect(back.absenceKind, AbsenceKind.specialistVisit);
      expect(back.absenceMins, 180);
    });
  });

  group('recomputedFromSegments — casi reali del portale', () {
    DailyTimesheet base(String dateId, List<DaySegment> segments) =>
        DailyTimesheet(
          dateId: dateId,
          startTime: DateTime.parse('${dateId}T00:00:00'),
          endTime: DateTime.parse('${dateId}T00:00:00'),
          standardPauseMins: 0,
          lunchPauseMins: 0,
          netWorkedMins: 0,
          extraMins: 0,
          segments: segments,
        ).recomputedFromSegments(stdMins: 456);

    DateTime at(String dateId, int h, int m) =>
        DateTime(int.parse(dateId.substring(0, 4)),
            int.parse(dateId.substring(5, 7)),
            int.parse(dateId.substring(8, 10)), h, m);

    test('permesso dentro lo span: copre il dovuto senza doppio conteggio', () {
      const d = '2026-07-23';
      final e = base(d, [
        DaySegment(type: DaySegment.work, start: at(d, 10, 25), end: at(d, 12, 52)),
        DaySegment(
          type: DaySegment.leave,
          start: at(d, 12, 52),
          end: at(d, 15, 8),
          absenceKind: 'specialist_visit',
        ),
        DaySegment(type: DaySegment.work, start: at(d, 15, 8), end: at(d, 18, 2)),
      ]);
      expect(e.netWorkedMins, 321);
      expect(e.leavePauseMins, 136);
      expect(e.extraMins, 1);
      expect(DailyTimesheet.uncoveredDeficitMins(e), 0);
    });

    test('permesso fuori dallo span: si somma alla copertura', () {
      const d = '2026-07-07';
      final e = base(d, [
        DaySegment(
          type: DaySegment.leave,
          start: at(d, 8, 45),
          end: at(d, 10, 31),
          absenceKind: 'specialist_visit',
        ),
        DaySegment(type: DaySegment.work, start: at(d, 10, 31), end: at(d, 15, 13)),
        DaySegment(type: DaySegment.work, start: at(d, 15, 16), end: at(d, 16, 3)),
        DaySegment(type: DaySegment.work, start: at(d, 16, 6), end: at(d, 17, 5)),
      ]);
      // I buchi fra le timbrature restano lavorati: work collassa nello span.
      expect(e.netWorkedMins, 394);
      expect(e.extraMins, 44);
    });

    test('esonero banca ore fuori span piu\' pausa senza orario', () {
      const d = '2026-03-04';
      final e = base(d, [
        DaySegment(type: DaySegment.bancaOre, start: at(d, 8, 40), end: at(d, 10, 23)),
        DaySegment(type: DaySegment.work, start: at(d, 10, 23), end: at(d, 13, 34)),
        DaySegment(type: DaySegment.work, start: at(d, 13, 41), end: at(d, 16, 23)),
        const DaySegment(type: DaySegment.pause, mins: 7),
      ]);
      expect(e.standardPauseMins, 7);
      expect(e.bancaOreMins, 103);
      expect(e.netWorkedMins, 353);
      expect(e.extraMins, 0);
    });

    test('pausa pranzo dichiarata e regola delle 9 ore', () {
      const d = '2026-07-29';
      final e = base(d, [
        DaySegment(type: DaySegment.work, start: at(d, 8, 17), end: at(d, 9, 30)),
        DaySegment(type: DaySegment.lunch, start: at(d, 9, 30), end: at(d, 10, 3)),
        DaySegment(type: DaySegment.work, start: at(d, 10, 3), end: at(d, 10, 30)),
        DaySegment(type: DaySegment.work, start: at(d, 10, 37), end: at(d, 12, 21)),
        DaySegment(type: DaySegment.work, start: at(d, 12, 36), end: at(d, 19, 59)),
      ]);
      expect(e.lunchPauseMins, 33); // dichiarata 33 > forzata 30
      expect(e.netWorkedMins, 669);
      expect(e.extraMins, 213);
    });

    test('estremi della giornata dai soli segmenti work', () {
      const d = '2026-07-07';
      final e = base(d, [
        DaySegment(
          type: DaySegment.leave,
          start: at(d, 8, 45),
          end: at(d, 10, 31),
          absenceKind: 'specialist_visit',
        ),
        DaySegment(type: DaySegment.work, start: at(d, 10, 31), end: at(d, 17, 5)),
      ]);
      expect(e.startTime, at(d, 10, 31));
      expect(e.endTime, at(d, 17, 5));
    });

    test('deficit scoperto solo per la parte non coperta', () {
      const d = '2026-06-04';
      final e = base(d, [
        DaySegment(type: DaySegment.work, start: at(d, 9, 0), end: at(d, 15, 0)),
        const DaySegment(type: DaySegment.leave, mins: 30, absenceKind: 'short_leave'),
      ]);
      // Span 360, di cui 30 di permesso: 330 lavorati + 30 di copertura
      // = 360 su 456 dovuti. Il permesso senza orari sta dentro lo span.
      expect(e.netWorkedMins, 330);
      expect(e.extraMins, -96);
      expect(DailyTimesheet.uncoveredDeficitMins(e), 96);
    });
  });
}
