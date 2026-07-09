import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/features/timesheet/domain/daily_timesheet.dart';
import 'package:chigio_time/features/timesheet/domain/day_segment.dart';

void main() {
  group('DaySegment', () {
    test('work segment roundtrip + workMins', () {
      final s = DaySegment(
        type: DaySegment.work,
        start: DateTime(2026, 7, 9, 9, 2),
        end: DateTime(2026, 7, 9, 13, 0),
      );
      expect(s.workMins, 238);
      final back = DaySegment.fromMap(s.toMap());
      expect(back.type, DaySegment.work);
      expect(back.start, DateTime(2026, 7, 9, 9, 2));
      expect(back.workMins, 238);
    });

    test('leave segment roundtrip', () {
      final s = DaySegment(
        type: DaySegment.leave,
        mins: 96,
        absenceKind: 'short_leave',
      );
      final back = DaySegment.fromMap(s.toMap());
      expect(back.mins, 96);
      expect(back.absenceKind, 'short_leave');
      expect(back.workMins, 0);
    });

    test('fromMap tolerant on garbage', () {
      final s = DaySegment.fromMap({'type': 'work'});
      expect(s.workMins, 0); // no start/end → 0, no throw
    });

    test('fromMap tolerant on type-mismatched garbage', () {
      final s = DaySegment.fromMap({
        'type': 123,
        'mins': '60',
        'absenceKind': 42,
        'start': 5,
      });
      expect(s.type, DaySegment.work); // non-string type → default
      expect(s.mins, 0);
      expect(s.absenceKind, isNull);
      expect(s.workMins, 0);
    });
  });

  group('DailyTimesheet.segments', () {
    test('toMap writes segments, fromMap reads them', () {
      final e = DailyTimesheet(
        dateId: '2026-07-09',
        startTime: DateTime(2026, 7, 9, 9),
        endTime: DateTime(2026, 7, 9, 17),
        standardPauseMins: 0,
        lunchPauseMins: 0,
        netWorkedMins: 480,
        extraMins: 24,
        segments: [
          DaySegment(
            type: DaySegment.work,
            start: DateTime(2026, 7, 9, 9),
            end: DateTime(2026, 7, 9, 17),
          ),
        ],
      );
      final back = DailyTimesheet.fromMap(e.toMap());
      expect(back.segments, hasLength(1));
      expect(back.segments.first.workMins, 480);
    });

    test('legacy doc without segments derives work segment lazily', () {
      final back = DailyTimesheet.fromMap({
        'dateId': '2026-07-09',
        'startTime': '2026-07-09T09:00:00.000',
        'endTime': '2026-07-09T17:36:00.000',
        'netWorkedMins': 456,
        'extraMins': 0,
        'workType': 'presence',
      });
      expect(back.segments, hasLength(1));
      expect(back.segments.first.type, DaySegment.work);
      expect(back.segments.first.start, DateTime(2026, 7, 9, 9));
    });

    test('legacy doc with leavePauseMins derives extra leave segment', () {
      final back = DailyTimesheet.fromMap({
        'dateId': '2026-07-09',
        'startTime': '2026-07-09T09:00:00.000',
        'endTime': '2026-07-09T17:36:00.000',
        'leavePauseMins': 60,
        'netWorkedMins': 396,
        'extraMins': -60,
        'workType': 'presence',
      });
      expect(back.segments, hasLength(2));
      expect(back.segments.last.type, DaySegment.leave);
      expect(back.segments.last.mins, 60);
    });

    test('garbage segments value degrades to lazy derive, no throw', () {
      final back = DailyTimesheet.fromMap({
        'dateId': '2026-07-09',
        'startTime': '2026-07-09T09:00:00.000',
        'endTime': '2026-07-09T17:36:00.000',
        'segments': 'garbage',
        'workType': 'presence',
      });
      expect(back.segments, hasLength(1)); // derived work segment
      expect(back.segments.first.type, DaySegment.work);
    });

    test('leave/holiday full-day docs derive NO segments', () {
      final back = DailyTimesheet.fromMap({
        'dateId': '2026-07-09',
        'startTime': '2026-07-09T09:00:00.000',
        'endTime': '2026-07-09T17:36:00.000',
        'netWorkedMins': 0,
        'extraMins': 0,
        'workType': 'holiday',
      });
      expect(back.segments, isEmpty);
    });
  });
}
