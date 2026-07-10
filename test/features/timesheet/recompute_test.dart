import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/features/timesheet/domain/daily_timesheet.dart';
import 'package:chigio_time/features/timesheet/domain/day_segment.dart';

DailyTimesheet _day(
  List<DaySegment> segs, {
  int standardPause = 0,
  int bancaOre = 0,
  int lunchTaken = 0,
}) => DailyTimesheet(
  dateId: '2026-07-09',
  startTime: DateTime(2026, 7, 9),
  endTime: DateTime(2026, 7, 9),
  standardPauseMins: standardPause,
  lunchPauseMins: lunchTaken,
  netWorkedMins: 0,
  extraMins: 0,
  bancaOreMins: bancaOre,
  segments: segs,
);

DaySegment _w(int h1, int m1, int h2, int m2) => DaySegment(
  type: DaySegment.work,
  start: DateTime(2026, 7, 9, h1, m1),
  end: DateTime(2026, 7, 9, h2, m2),
);

void main() {
  test('single work segment 9:00-17:36, std 456 → net 456, extra 0, no lunch', () {
    final r = _day([_w(9, 0, 17, 36)]).recomputedFromSegments(stdMins: 456);
    // 9:00→17:36 = 516 elapsed minutes (not 456 — that's 9:00→16:36).
    expect(r.netWorkedMins, 516);
    expect(r.lunchPauseMins, 0); // elapsed 516 < 540 → zone 1
    expect(r.extraMins, 60);
    expect(r.startTime, DateTime(2026, 7, 9, 9));
    expect(r.endTime, DateTime(2026, 7, 9, 17, 36));
  });

  test('9h+ elapsed triggers 3-zone forced lunch on work total', () {
    // two work segments totalling 570m elapsed-worked → forced 30
    final r = _day([_w(8, 0, 13, 0), _w(13, 30, 18, 0)])
        .recomputedFromSegments(stdMins: 456);
    // workSum = 300 + 270 = 570 → zone 3 → lunch 30, net 540
    expect(r.lunchPauseMins, 30);
    expect(r.netWorkedMins, 540);
    expect(r.extraMins, 84);
  });

  test('leave segments sum into leavePauseMins, not net', () {
    final r = _day([
      _w(9, 0, 13, 0), // 240
      DaySegment(type: DaySegment.leave, mins: 96, absenceKind: 'short_leave'),
      _w(14, 30, 17, 30), // 180
    ]).recomputedFromSegments(stdMins: 456);
    expect(r.netWorkedMins, 420);
    expect(r.leavePauseMins, 96);
    expect(r.extraMins, -36); // negative deficit preserved
  });

  test('standard pauses subtract from net', () {
    final r = _day([_w(9, 0, 17, 36)], standardPause: 20)
        .recomputedFromSegments(stdMins: 456);
    // 516 elapsed − 20 standard pause = 496 net (see note in first test).
    expect(r.netWorkedMins, 496);
    expect(r.extraMins, 40);
  });

  test('banca ore counts toward extra', () {
    final r = _day([_w(9, 0, 16, 36)], bancaOre: 60)
        .recomputedFromSegments(stdMins: 456);
    expect(r.netWorkedMins, 456);
    expect(r.extraMins, 60);
  });

  test('lunch already taken never reduced by rule', () {
    final r = _day([_w(9, 0, 17, 0)], lunchTaken: 45)
        .recomputedFromSegments(stdMins: 456);
    expect(r.lunchPauseMins, 45);
    expect(r.netWorkedMins, 480 - 45);
  });

  test('uncoveredDeficitMins: permesso covers deficit', () {
    final covered = _day([
      _w(9, 0, 15, 0), // 360, std 456 → deficit 96
      DaySegment(type: DaySegment.leave, mins: 96),
    ]).recomputedFromSegments(stdMins: 456);
    expect(covered.extraMins, -96);
    expect(DailyTimesheet.uncoveredDeficitMins(covered), 0);

    final partial = _day([
      _w(9, 0, 15, 0),
      DaySegment(type: DaySegment.leave, mins: 30),
    ]).recomputedFromSegments(stdMins: 456);
    expect(DailyTimesheet.uncoveredDeficitMins(partial), 66);
  });

  test('empty segments → unchanged copy', () {
    final e = _day(const []);
    expect(e.recomputedFromSegments(stdMins: 456).netWorkedMins, 0);
  });
}
