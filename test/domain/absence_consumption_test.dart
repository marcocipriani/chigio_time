import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/features/timesheet/domain/absence_consumption.dart';
import 'package:chigio_time/features/timesheet/domain/absence_kind.dart';
import 'package:chigio_time/features/timesheet/domain/daily_timesheet.dart';
import 'package:chigio_time/features/timesheet/domain/day_segment.dart';

DailyTimesheet _day(String dateId, {
  String? kind,
  String? unit,
  int absenceMins = 0,
  double absenceDays = 0,
  List<DaySegment> segments = const [],
  String workType = WorkType.leave,
}) => DailyTimesheet(
      dateId: dateId,
      startTime: DateTime.parse('${dateId}T09:00:00'),
      endTime: DateTime.parse('${dateId}T09:00:00'),
      standardPauseMins: 0,
      lunchPauseMins: 0,
      netWorkedMins: 0,
      extraMins: 0,
      workType: workType,
      absenceKind: kind,
      absenceUnit: unit,
      absenceMins: absenceMins,
      absenceDays: absenceDays,
      segments: segments,
    );

void main() {
  test('i permessi dentro una giornata di presenza scalano il plafond', () {
    final c = computeAbsenceConsumption(year: 2026, entries: [
      _day('2026-07-23', workType: WorkType.presence, segments: [
        DaySegment(
          type: DaySegment.leave,
          start: DateTime(2026, 7, 23, 12, 52),
          end: DateTime(2026, 7, 23, 15, 8),
          absenceKind: AbsenceKind.specialistVisit,
        ),
      ]),
    ]);
    expect(c.specialistVisitMins, 136);
    expect(c.specialistVisitCount, 1);
  });

  test('la giornata convenzionale consuma 6 ore, non l\'orario dichiarato', () {
    final c = computeAbsenceConsumption(year: 2026, entries: [
      _day('2026-07-24',
          kind: AbsenceKind.personalFamilyHourly,
          unit: AbsenceUnit.daily,
          absenceDays: 1),
    ]);
    expect(c.personalFamilyHourlyMins, 360);
  });

  test('assemblea: plafond di 12 ore annue', () {
    expect(AbsencePlafonds.limitFor(AbsenceKind.assembly),
        (type: AbsenceLimit.hourly, amount: 12 * 60));
    final c = computeAbsenceConsumption(year: 2026, entries: [
      _day('2026-06-10', kind: AbsenceKind.assembly, absenceMins: 120),
    ]);
    expect(c.minsFor(AbsenceKind.assembly), 120);
  });

  test('festivita\' soppresse: quota di 4 giornate', () {
    expect(AbsencePlafonds.limitFor(AbsenceKind.suppressedHoliday),
        (type: AbsenceLimit.daily, amount: 4));
    final c = computeAbsenceConsumption(year: 2026, entries: [
      _day('2026-01-05',
          kind: AbsenceKind.suppressedHoliday,
          unit: AbsenceUnit.daily,
          absenceDays: 1,
          workType: WorkType.holiday),
      _day('2026-06-01',
          kind: AbsenceKind.suppressedHoliday,
          unit: AbsenceUnit.daily,
          absenceDays: 1,
          workType: WorkType.holiday),
    ]);
    expect(c.daysFor(AbsenceKind.suppressedHoliday), 2);
  });

  test('sciopero: registrato ma senza plafond', () {
    expect(AbsencePlafonds.limitFor(AbsenceKind.strike)?.type,
        AbsenceLimit.none);
    final c = computeAbsenceConsumption(year: 2026, entries: [
      _day('2026-06-11', kind: AbsenceKind.strike, absenceMins: 456),
    ]);
    expect(c.minsFor(AbsenceKind.strike), 456);
  });

  test('i recuperi consumano un credito con saldo esterno', () {
    for (final k in [
      AbsenceKind.workedHolidayComp,
      AbsenceKind.compensatoryRest,
    ]) {
      expect(AbsencePlafonds.limitFor(k)?.type, AbsenceLimit.credit, reason: k);
    }
  });

  test('i getter esistenti restano la facciata dei contatori', () {
    final c = computeAbsenceConsumption(year: 2026, entries: [
      _day('2026-02-02', kind: AbsenceKind.shortLeave, absenceMins: 45),
    ]);
    expect(c.shortLeaveMins, 45);
    expect(c.shortLeaveOverPlafond, isFalse);

    final over = computeAbsenceConsumption(year: 2026, entries: [
      _day('2026-02-03',
          kind: AbsenceKind.shortLeave, absenceMins: 38 * 60 + 1),
    ]);
    expect(over.shortLeaveOverPlafond, isTrue);
  });

  test(
      'giornata con causale di giornata E segmento leave della stessa '
      'causale: i segmenti vincono, nessuna doppia quota', () {
    final c = computeAbsenceConsumption(year: 2026, entries: [
      _day(
        '2026-03-10',
        kind: AbsenceKind.specialistVisit,
        absenceMins: 100,
        workType: WorkType.presence,
        segments: [
          DaySegment(
            type: DaySegment.leave,
            mins: 50,
            absenceKind: AbsenceKind.specialistVisit,
          ),
        ],
      ),
    ]);
    expect(c.specialistVisitMins, 50);
    expect(c.specialistVisitCount, 1);
  });

  test('ogni causale nota ha un\'etichetta', () {
    for (final k in [
      AbsenceKind.suppressedHoliday,
      AbsenceKind.assembly,
      AbsenceKind.strike,
      AbsenceKind.workedHolidayComp,
      AbsenceKind.compensatoryRest,
    ]) {
      expect(AbsenceKind.labels[k], isNotNull, reason: k);
    }
  });
}
