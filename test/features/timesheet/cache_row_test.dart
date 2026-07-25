import 'dart:convert';

import 'package:chigio_time/core/database/app_database.dart';
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
  int? absenceMins,
  bool sensitive = false,
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
  absenceMins: absenceMins,
  sensitive: sensitive,
  hasDocumentation: false,
  countsAsSicknessPeriod: false,
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

    test('documenta il buco noto: la cache non trasporta i campi assenza', () {
      // La tabella Drift ha le colonne absenceKind/absenceMins/sensitive, ma
      // né `_toCompanion` né `_fromRow` le toccano: nel fallback offline una
      // giornata di permesso perde causale, minuti e flag riservata.
      // Vedi docs/funzionalita/timesheet.md § Cache locale. Se questo test
      // fallisce, il buco è stato chiuso: aggiornare doc e asserzioni.
      final entry = TimesheetRepository.entryFromCacheRow(
        _row(
          workType: WorkType.leave,
          absenceKind: AbsenceKind.specialistVisit,
          absenceMins: 180,
          sensitive: true,
        ),
      );

      expect(entry.workType, WorkType.leave);
      expect(entry.absenceKind, isNull);
      expect(entry.absenceMins, 0);
      expect(entry.sensitive, isFalse);
    });
  });
}
