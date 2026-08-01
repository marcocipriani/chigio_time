import 'dart:convert';

import 'package:chigio_time/core/database/app_database.dart';
import 'package:chigio_time/features/timesheet/data/csv_export_service.dart';
import 'package:chigio_time/features/timesheet/data/timesheet_repository.dart';
import 'package:chigio_time/features/timesheet/domain/absence_kind.dart';
import 'package:chigio_time/features/timesheet/domain/daily_timesheet.dart';
import 'package:chigio_time/features/timesheet/domain/day_segment.dart';
import 'package:flutter_test/flutter_test.dart';

/// Riga di cache Drift con valori sensati, sovrascrivibili campo per campo.
TimesheetEntry _row({
  String dateId = '2026-05-15',
  String startTime = '2026-05-15T09:00:00.000',
  String endTime = '2026-05-15T17:36:00.000',
  int standardPauseMins = 0,
  int leavePauseMins = 0,
  int lunchPauseMins = 30,
  int netWorkedMins = 456,
  int extraMins = 12,
  int sliMins = 0,
  int sboMins = 0,
  String? workType = WorkType.presence,
  String? note = 'riunione',
  int bancaOreMins = 0,
  String? boeSlot,
  String? segments,
  String? absenceKind,
  String? absenceUnit,
  int? absenceMins,
  double? absenceDays,
  String? periodFrom,
  String? periodTo,
  double? quotaYear,
  bool sensitive = false,
  bool hasDocumentation = false,
  bool countsAsSicknessPeriod = false,
}) => TimesheetEntry(
  uid: 'uid-1',
  dateId: dateId,
  startTime: startTime,
  endTime: endTime,
  standardPauseMins: standardPauseMins,
  leavePauseMins: leavePauseMins,
  lunchPauseMins: lunchPauseMins,
  netWorkedMins: netWorkedMins,
  extraMins: extraMins,
  sliMins: sliMins,
  sboMins: sboMins,
  workType: workType,
  note: note,
  bancaOreMins: bancaOreMins,
  boeSlot: boeSlot,
  updatedAt: '2026-05-15T18:00:00.000Z',
  absenceKind: absenceKind,
  absenceUnit: absenceUnit,
  absenceMins: absenceMins,
  absenceDays: absenceDays,
  periodFrom: periodFrom,
  periodTo: periodTo,
  quotaYear: quotaYear,
  sensitive: sensitive,
  hasDocumentation: hasDocumentation,
  countsAsSicknessPeriod: countsAsSicknessPeriod,
  segments: segments,
);

void main() {
  group('TimesheetRepository.entryFromCacheRow', () {
    test('maps a healthy row field by field', () {
      final entry = TimesheetRepository.entryFromCacheRow(
        _row(
          sliMins: 20,
          sboMins: 40,
          bancaOreMins: 60,
          boeSlot: BoeSlot.pause,
        ),
      );

      expect(entry.dateId, '2026-05-15');
      expect(entry.startTime, DateTime(2026, 5, 15, 9));
      expect(entry.endTime, DateTime(2026, 5, 15, 17, 36));
      expect(entry.lunchPauseMins, 30);
      expect(entry.netWorkedMins, 456);
      expect(entry.extraMins, 12);
      expect(entry.sliMins, 20);
      expect(entry.sboMins, 40);
      expect(entry.bancaOreMins, 60);
      expect(entry.boeSlot, BoeSlot.pause);
      expect(entry.workType, WorkType.presence);
      expect(entry.note, 'riunione');
    });

    test('falls back to the dateId when a timestamp is corrupt', () {
      final entry = TimesheetRepository.entryFromCacheRow(
        _row(startTime: 'non-una-data', endTime: ''),
      );

      // Nessuna eccezione: il giorno resta nella lista, con l'orario azzerato.
      expect(entry.startTime, DateTime(2026, 5, 15));
      expect(entry.endTime, DateTime(2026, 5, 15));
    });

    test('falls back to the epoch when even the dateId is corrupt', () {
      final entry = TimesheetRepository.entryFromCacheRow(
        _row(dateId: 'xx', startTime: 'yy', endTime: 'zz'),
      );

      expect(entry.startTime, DateTime.fromMillisecondsSinceEpoch(0));
      expect(entry.endTime, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('parses the serialised segments', () {
      final segments = jsonEncode([
        DaySegment(
          type: DaySegment.work,
          start: DateTime(2026, 5, 15, 9),
          end: DateTime(2026, 5, 15, 13),
        ).toMap(),
        const DaySegment(
          type: DaySegment.leave,
          mins: 60,
          absenceKind: AbsenceKind.specialistVisit,
        ).toMap(),
      ]);

      final entry = TimesheetRepository.entryFromCacheRow(
        _row(segments: segments),
      );

      expect(entry.segments, hasLength(2));
      expect(entry.segments.first.workMins, 240);
      expect(entry.segments.last.leaveMins, 60);
      expect(entry.segments.last.absenceKind, AbsenceKind.specialistVisit);
    });

    test('il flag riservata sopravvive alla cache', () {
      // La cache trasporta i segmenti con la loro causale: senza il flag,
      // l'export di un mese servito dalla cache scriverebbe la causale vera
      // di una giornata riservata.
      final segments = jsonEncode([
        const DaySegment(
          type: DaySegment.leave,
          mins: 60,
          absenceKind: AbsenceKind.seriousPathologyTherapy,
        ).toMap(),
      ]);

      final entry = TimesheetRepository.entryFromCacheRow(
        _row(sensitive: true, segments: segments),
      );

      expect(entry.sensitive, isTrue);
      final csv = CsvExportService.buildSimpleCsv([entry]);
      expect(csv, isNot(contains(AbsenceKind.seriousPathologyTherapy)));
      expect(csv, contains(AbsenceKind.sensitiveLeave));
    });

    test('degrades a corrupt segments payload to an empty list', () {
      for (final payload in [
        null,
        '',
        'non-json',
        '{"type":"work"}', // mappa invece di lista
        '[1, 2, 3]', // elementi non-mappa
      ]) {
        final entry = TimesheetRepository.entryFromCacheRow(
          _row(segments: payload),
        );
        expect(entry.segments, isEmpty, reason: 'payload: $payload');
      }
    });

    test('keeps the day usable when the row is entirely degraded', () {
      final entry = TimesheetRepository.entryFromCacheRow(
        _row(
          startTime: '',
          endTime: '',
          workType: null,
          note: null,
          segments: 'garbage',
        ),
      );

      expect(entry.dateId, '2026-05-15');
      expect(entry.workType, isNull); // = presenza per i documenti legacy
      expect(entry.note, isNull);
      expect(entry.segments, isEmpty);
    });

    test('preserva tutti i campi assenza nel fallback offline', () {
      final entry = TimesheetRepository.entryFromCacheRow(
        _row(
          workType: WorkType.leave,
          absenceKind: AbsenceKind.specialistVisit,
          absenceUnit: AbsenceUnit.period,
          absenceMins: 180,
          absenceDays: 1.5,
          periodFrom: '2026-05-15',
          periodTo: '2026-05-17',
          quotaYear: 2026,
          sensitive: true,
          hasDocumentation: true,
          countsAsSicknessPeriod: true,
        ),
      );

      expect(entry.workType, WorkType.leave);
      expect(entry.absenceKind, AbsenceKind.specialistVisit);
      expect(entry.absenceUnit, AbsenceUnit.period);
      expect(entry.absenceMins, 180);
      expect(entry.absenceDays, 1.5);
      expect(entry.periodStart, '2026-05-15');
      expect(entry.periodEnd, '2026-05-17');
      expect(entry.quotaYear, 2026);
      expect(entry.sensitive, isTrue);
      expect(entry.hasDocumentation, isTrue);
      expect(entry.countsAsSicknessPeriod, isTrue);
    });
  });
}
