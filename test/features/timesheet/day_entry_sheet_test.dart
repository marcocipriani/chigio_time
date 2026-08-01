import 'package:chigio_time/core/constants/app_strings.dart';
import 'package:chigio_time/features/timesheet/data/timesheet_repository.dart';
import 'package:chigio_time/features/timesheet/domain/daily_timesheet.dart';
import 'package:chigio_time/features/timesheet/domain/day_segment.dart';
import 'package:chigio_time/features/timesheet/presentation/timesheet_screen.dart';
import 'package:chigio_time/features/profile/data/profile_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFirestore extends Fake implements FirebaseFirestore {}

class _FakeFirebaseAuth extends Fake implements FirebaseAuth {}

class _FakeTimesheetRepository extends TimesheetRepository {
  _FakeTimesheetRepository(this.entries)
    : super(_FakeFirestore(), _FakeFirebaseAuth(), null);

  final List<DailyTimesheet> entries;
  final List<String> deletedDateIds = [];
  final List<DailyTimesheet> savedEntries = [];

  @override
  Stream<List<DailyTimesheet>> watchMonthlyTimesheets(int year, int month) =>
      Stream.value(entries);

  @override
  Future<List<DailyTimesheet>> fetchRange(DateTime start, DateTime end) async =>
      entries
          .where(
            (entry) =>
                !entry.startTime.isBefore(start) &&
                !entry.startTime.isAfter(end.add(const Duration(days: 1))),
          )
          .toList();

  @override
  Future<void> deleteDailyTimesheet(String dateId) async {
    deletedDateIds.add(dateId);
  }

  @override
  Future<void> saveDailyTimesheet(
    DailyTimesheet entry, {
    bool fullOverwrite = false,
  }) async {
    savedEntries.add(entry);
  }
}

DailyTimesheet _entry(int day, {List<DaySegment> segments = const []}) =>
    DailyTimesheet(
      dateId: '2026-07-${day.toString().padLeft(2, '0')}',
      startTime: DateTime(2026, 7, day, 9),
      endTime: DateTime(2026, 7, day, 17),
      standardPauseMins: 0,
      lunchPauseMins: 0,
      netWorkedMins: 480,
      extraMins: 24,
      workType: WorkType.presence,
      segments: segments,
    );

Widget _app(_FakeTimesheetRepository repository, DailyTimesheet initialEntry) =>
    ProviderScope(
      overrides: [
        timesheetRepositoryProvider.overrideWithValue(repository),
        userProfileStreamProvider.overrideWith((ref) => Stream.value(null)),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final month = ref.watch(
            monthlyTimesheetsProvider((year: 2026, month: 7)),
          );
          return MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Text('${month.value?.length ?? 0}'),
                  Builder(
                    builder: (context) => ElevatedButton(
                      onPressed: () => showDayEntrySheet(
                        context,
                        date: DateTime(2026, 7, 23),
                        existingEntry: initialEntry,
                      ),
                      child: const Text('Apri'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

Future<void> _selectDay(WidgetTester tester, int day) async {
  await tester.tap(find.text('23 ${AppStrings.monthsShort[6]} 2026'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('$day'));
  await tester.tap(find.text(AppStrings.ok));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'annulla ripristina la giornata selezionata, non quella iniziale',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final day23 = _entry(23);
      final day24 = _entry(24);
      final repository = _FakeTimesheetRepository([day23, day24]);

      await tester.pumpWidget(_app(repository, day23));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apri'));
      await tester.pumpAndSettle();
      await _selectDay(tester, 24);

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.eliminaGiornata).last);
      await tester.pumpAndSettle();

      expect(repository.deletedDateIds, ['2026-07-24']);
      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();
      expect(repository.savedEntries.single.dateId, '2026-07-24');
    },
  );

  testWidgets('salvare sul giorno scelto conserva i suoi segmenti', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final day23 = _entry(23);
    final day24 = _entry(
      24,
      segments: [
        DaySegment(
          type: DaySegment.work,
          start: DateTime(2026, 7, 24, 9),
          end: DateTime(2026, 7, 24, 17),
        ),
        const DaySegment(
          type: DaySegment.leave,
          mins: 60,
          absenceKind: 'specialist_visit',
        ),
      ],
    );
    final repository = _FakeTimesheetRepository([day23, day24]);

    await tester.pumpWidget(_app(repository, day23));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();
    await _selectDay(tester, 24);
    await tester.tap(find.text(AppStrings.saveDay));
    await tester.pumpAndSettle();

    final saved = repository.savedEntries.single;
    expect(saved.dateId, '2026-07-24');
    expect(
      saved.segments.any((segment) => segment.type == DaySegment.leave),
      isTrue,
    );
  });
}
