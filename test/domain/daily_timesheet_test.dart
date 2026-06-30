import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/features/timesheet/domain/daily_timesheet.dart';
import 'package:chigio_time/features/timesheet/domain/absence_kind.dart';

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
      DailyTimesheet parse(Map<String, dynamic> m) =>
          DailyTimesheet.fromMap(m);

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
}
