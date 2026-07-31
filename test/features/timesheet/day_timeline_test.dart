import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/features/timesheet/domain/daily_timesheet.dart';
import 'package:chigio_time/features/timesheet/domain/day_segment.dart';
import 'package:chigio_time/features/timesheet/presentation/day_timeline.dart';

DateTime _at(int h, int m) => DateTime(2026, 7, 23, h, m);

DailyTimesheet _entry(List<DaySegment> segments) => DailyTimesheet(
      dateId: '2026-07-23',
      startTime: _at(10, 25),
      endTime: _at(18, 2),
      standardPauseMins: 0,
      lunchPauseMins: 0,
      netWorkedMins: 0,
      extraMins: 0,
      workType: WorkType.presence,
      segments: segments,
    ).recomputedFromSegments(stdMins: 456);

Future<void> _pump(WidgetTester tester, DailyTimesheet e) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DayTimeline(entry: e, onChanged: (_) {})),
      ),
    );

void main() {
  testWidgets('mostra i segmenti in ordine con la loro etichetta',
      (tester) async {
    await _pump(
      tester,
      _entry([
        DaySegment(type: DaySegment.work, start: _at(10, 25), end: _at(12, 52)),
        DaySegment(
          type: DaySegment.leave,
          start: _at(12, 52),
          end: _at(15, 8),
          absenceKind: 'specialist_visit',
        ),
        DaySegment(type: DaySegment.work, start: _at(15, 8), end: _at(18, 2)),
      ]),
    );
    expect(find.text('10:25 – 12:52'), findsOneWidget);
    expect(find.text('12:52 – 15:08'), findsOneWidget);
    expect(find.text('Visita specialistica'), findsOneWidget);
  });

  testWidgets('un buco fra due segmenti e\' mostrato come non coperto',
      (tester) async {
    await _pump(
      tester,
      _entry([
        DaySegment(type: DaySegment.work, start: _at(10, 0), end: _at(12, 0)),
        DaySegment(type: DaySegment.work, start: _at(13, 0), end: _at(18, 0)),
      ]),
    );
    expect(find.textContaining('Non coperto'), findsOneWidget);
  });

  testWidgets('un segmento senza orari mostra la durata', (tester) async {
    await _pump(
      tester,
      _entry([
        DaySegment(type: DaySegment.work, start: _at(9, 0), end: _at(17, 0)),
        const DaySegment(type: DaySegment.pause, mins: 7),
      ]),
    );
    expect(find.textContaining('7 min'), findsOneWidget);
  });

  testWidgets('su ferie e permesso di giornata la timeline non compare',
      (tester) async {
    // Una giornata di assenza intera consuma sui campi di giornata: se la
    // timeline permettesse di aggiungerci un segmento `leave` con causale,
    // i contatori — che privilegiano i segmenti — perderebbero la quota.
    for (final type in [WorkType.holiday, WorkType.leave, WorkType.remote]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayTimeline(
              entry: DailyTimesheet(
                dateId: '2026-07-14',
                startTime: _at(9, 0),
                endTime: _at(17, 0),
                standardPauseMins: 0,
                lunchPauseMins: 0,
                netWorkedMins: 0,
                extraMins: 0,
                workType: type,
              ),
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('Aggiungi segmento'), findsNothing, reason: type);
      expect(find.textContaining('Timeline'), findsNothing, reason: type);
    }
  });

  testWidgets('eliminare un segmento notifica la lista aggiornata',
      (tester) async {
    List<DaySegment>? updated;
    final e = _entry([
      DaySegment(type: DaySegment.work, start: _at(10, 0), end: _at(12, 0)),
      DaySegment(
        type: DaySegment.leave,
        start: _at(12, 0),
        end: _at(13, 0),
        absenceKind: 'short_leave',
      ),
    ]);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DayTimeline(entry: e, onChanged: (s) => updated = s),
      ),
    ));
    await tester.tap(find.byTooltip('Elimina segmento').last);
    await tester.pumpAndSettle();
    expect(updated, isNotNull);
    expect(updated!.any((s) => s.type == DaySegment.leave), isFalse);
  });
}
