import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/features/timesheet/domain/daily_timesheet.dart';
import 'package:chigio_time/features/timesheet/domain/day_segment.dart';

DailyTimesheet _day(List<DaySegment> segs) => DailyTimesheet(
  dateId: '2026-07-09',
  startTime: DateTime(2026, 7, 9),
  endTime: DateTime(2026, 7, 9),
  standardPauseMins: 0,
  lunchPauseMins: 0,
  netWorkedMins: 0,
  extraMins: 0,
  segments: segs,
);

DaySegment _w(int h1, int m1, int h2, int m2) => DaySegment(
  type: DaySegment.work,
  start: DateTime(2026, 7, 9, h1, m1),
  end: DateTime(2026, 7, 9, h2, m2),
);

void main() {
  test(
    'single work segment 9:00-17:36, std 456 → net 456, extra 0, no lunch',
    () {
      final r = _day([_w(9, 0, 17, 36)]).recomputedFromSegments(stdMins: 456);
      // 9:00→17:36 = 516 elapsed minutes (not 456 — that's 9:00→16:36).
      expect(r.netWorkedMins, 516);
      expect(r.lunchPauseMins, 0); // elapsed 516 < 540 → zone 1
      expect(r.extraMins, 60);
      expect(r.startTime, DateTime(2026, 7, 9, 9));
      expect(r.endTime, DateTime(2026, 7, 9, 17, 36));
    },
  );

  test('9h+ elapsed triggers 3-zone forced lunch on work total', () {
    // Two work segments 30m apart, no pause/leave segment declared for the
    // gap: ADR-0018 collapses the whole punch-to-punch span into net, so
    // the gap counts as worked too (previously only summed durations).
    final r = _day([
      _w(8, 0, 13, 0),
      _w(13, 30, 18, 0),
    ]).recomputedFromSegments(stdMins: 456);
    // span = 8:00→18:00 = 600 → zone 3 → lunch 30, net 570
    expect(r.lunchPauseMins, 30);
    expect(r.netWorkedMins, 570);
    expect(r.extraMins, 114);
  });

  test('leave segments sum into leavePauseMins, not net', () {
    final r = _day([
      _w(9, 0, 13, 0), // 240
      DaySegment(type: DaySegment.leave, mins: 96, absenceKind: 'short_leave'),
      _w(14, 30, 17, 30), // 180
    ]).recomputedFromSegments(stdMins: 456);
    // span = 9:00→17:30 = 510. The unpositioned leave sits inside the span
    // (DaySegment.overlapMins), so it covers 96 of it: net = 510-96 = 414.
    // extraMins now folds the leave back in (ADR-0018): 414+96-456 = 54,
    // vs. the old -36 that ignored leave in the deficit entirely.
    expect(r.netWorkedMins, 414);
    expect(r.leavePauseMins, 96);
    expect(r.extraMins, 54);
  });

  test('standard pauses subtract from net', () {
    // standardPauseMins is derived from `pause` segments now, not a
    // constructor field (see fromMap's legacy-only fallback).
    final r = _day([
      _w(9, 0, 17, 36),
      const DaySegment(type: DaySegment.pause, mins: 20),
    ]).recomputedFromSegments(stdMins: 456);
    // 516 elapsed − 20 standard pause = 496 net (see note in first test).
    expect(r.standardPauseMins, 20);
    expect(r.netWorkedMins, 496);
    expect(r.extraMins, 40);
  });

  test('banca ore counts toward extra', () {
    // bancaOreMins is derived from `bancaOre` segments now. Unpositioned
    // banca ore sits outside the span (DaySegment.overlapMins), so it adds
    // straight to extraMins without reducing net.
    final r = _day([
      _w(9, 0, 16, 36),
      const DaySegment(type: DaySegment.bancaOre, mins: 60),
    ]).recomputedFromSegments(stdMins: 456);
    expect(r.bancaOreMins, 60);
    expect(r.netWorkedMins, 456);
    expect(r.extraMins, 60);
  });

  test('lunch already taken never reduced by rule', () {
    // lunchPauseMins is derived from `lunch` segments now, not a
    // constructor field.
    final r = _day([
      _w(9, 0, 17, 0),
      const DaySegment(type: DaySegment.lunch, mins: 45),
    ]).recomputedFromSegments(stdMins: 456);
    expect(r.lunchPauseMins, 45);
    expect(r.netWorkedMins, 480 - 45);
  });

  test('uncoveredDeficitMins: unpositioned permesso stays inside the span', () {
    // An unpositioned leave (mins only, no start/end) is assumed to fall
    // inside the punched span (ADR-0018): it relabels part of the span as
    // covered but the span itself doesn't grow, so it never reduces the
    // deficit below what the span alone already leaves uncovered. Only a
    // leave positioned outside the span (see daily_timesheet_test.dart)
    // adds real coverage. Both 96 and 30 minutes of unpositioned leave
    // leave the same 96m gap between the 360m span and the 456m due.
    final covered = _day([
      _w(9, 0, 15, 0), // 360, std 456 → deficit 96
      DaySegment(type: DaySegment.leave, mins: 96),
    ]).recomputedFromSegments(stdMins: 456);
    expect(covered.extraMins, -96);
    expect(DailyTimesheet.uncoveredDeficitMins(covered), 96);

    final partial = _day([
      _w(9, 0, 15, 0),
      DaySegment(type: DaySegment.leave, mins: 30),
    ]).recomputedFromSegments(stdMins: 456);
    expect(DailyTimesheet.uncoveredDeficitMins(partial), 96);
  });

  test('empty segments → unchanged copy', () {
    final e = _day(const []);
    expect(e.recomputedFromSegments(stdMins: 456).netWorkedMins, 0);
  });
}
