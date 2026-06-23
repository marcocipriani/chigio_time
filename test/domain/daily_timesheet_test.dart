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
