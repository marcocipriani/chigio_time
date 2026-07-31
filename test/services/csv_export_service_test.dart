import 'package:chigio_time/features/timesheet/data/csv_export_service.dart';
import 'package:chigio_time/features/timesheet/data/csv_import_service.dart';
import 'package:chigio_time/features/timesheet/domain/absence_kind.dart';
import 'package:chigio_time/features/timesheet/domain/daily_timesheet.dart';
import 'package:flutter_test/flutter_test.dart';

DailyTimesheet _presence({
  String dateId = '2026-05-15',
  int startHour = 9,
  int startMinute = 0,
  int endHour = 17,
  int endMinute = 36,
  int netWorkedMins = 456,
  int extraMins = 0,
  String? note,
}) => DailyTimesheet(
  dateId: dateId,
  startTime: DateTime(2026, 5, 15, startHour, startMinute),
  endTime: DateTime(2026, 5, 15, endHour, endMinute),
  standardPauseMins: 0,
  lunchPauseMins: 0,
  netWorkedMins: netWorkedMins,
  extraMins: extraMins,
  workType: WorkType.presence,
  note: note,
);

List<String> _rows(String csv) =>
    csv.trim().split('\n').map((l) => l.trim()).toList();

List<String> _cells(String row) => row.split(';');

void main() {
  group('buildSimpleCsv', () {
    test('writes the same header as the import template', () {
      final header = _rows(
        CsvExportService.buildSimpleCsv([_presence()]),
      ).first;

      expect(
        header,
        'data;tipo;entrata;uscita;nota;'
        'assenza_tipo;assenza_min;assenza_giorni;periodo_da;periodo_a',
      );
    });

    test('writes clock times zero-padded for presence and remote days', () {
      final csv = CsvExportService.buildSimpleCsv([
        _presence(startHour: 8, startMinute: 5, endHour: 16, endMinute: 9),
      ]);

      expect(_cells(_rows(csv)[1]).sublist(0, 4), [
        '2026-05-15',
        'presenza',
        '08:05',
        '16:09',
      ]);
    });

    test('leaves the time columns empty for full-day absences', () {
      final csv = CsvExportService.buildSimpleCsv([
        DailyTimesheet(
          dateId: '2026-05-18',
          startTime: DateTime(2026, 5, 18, 9),
          endTime: DateTime(2026, 5, 18, 17),
          standardPauseMins: 0,
          lunchPauseMins: 0,
          netWorkedMins: 0,
          extraMins: 0,
          workType: WorkType.holiday,
        ),
      ]);

      expect(_cells(_rows(csv)[1]).sublist(0, 4), [
        '2026-05-18',
        'ferie',
        '',
        '',
      ]);
    });

    test('maps every work type to its import label', () {
      const types = <String?>[
        WorkType.presence,
        WorkType.remote,
        WorkType.leave,
        WorkType.holiday,
        null,
      ];
      final entries = <DailyTimesheet>[];
      for (var i = 0; i < types.length; i++) {
        entries.add(
          DailyTimesheet(
            dateId: '2026-05-1$i',
            startTime: DateTime(2026, 5, 10 + i, 9),
            endTime: DateTime(2026, 5, 10 + i, 17),
            standardPauseMins: 0,
            lunchPauseMins: 0,
            netWorkedMins: 456,
            extraMins: 0,
            workType: types[i],
          ),
        );
      }

      final csv = CsvExportService.buildSimpleCsv(entries);

      expect(_rows(csv).skip(1).map((r) => _cells(r)[1]), [
        'presenza',
        'smart_working',
        'permesso',
        'ferie',
        'presenza', // workType null = documento legacy
      ]);
    });

    test('neutralises separators and newlines inside the note', () {
      final csv = CsvExportService.buildSimpleCsv([
        _presence(note: 'riunione; poi\nrientro\r'),
      ]);

      // Una nota "sporca" non deve spostare le colonne né spezzare la riga.
      expect(_rows(csv), hasLength(2));
      expect(_cells(_rows(csv)[1]), hasLength(10));
      expect(_cells(_rows(csv)[1])[4], 'riunione, poi rientro');
    });

    test('redacts note, kind and period of a sensitive absence', () {
      final csv = CsvExportService.buildSimpleCsv([
        DailyTimesheet(
          dateId: '2026-05-20',
          startTime: DateTime(2026, 5, 20, 9),
          endTime: DateTime(2026, 5, 20, 17),
          standardPauseMins: 0,
          lunchPauseMins: 0,
          netWorkedMins: 0,
          extraMins: 0,
          workType: WorkType.leave,
          note: 'terapia oncologica',
          absenceKind: AbsenceKind.seriousPathologyTherapy,
          periodStart: '2026-05-20',
          periodEnd: '2026-05-24',
          sensitive: true,
        ),
      ]);

      final cells = _cells(_rows(csv)[1]);
      expect(cells[4], isEmpty); // nota
      expect(cells[5], AbsenceKind.sensitiveLeave); // causale mascherata
      expect(cells[8], isEmpty); // periodo_da
      expect(cells[9], isEmpty); // periodo_a
      expect(csv, isNot(contains('oncologica')));
      expect(csv, isNot(contains(AbsenceKind.seriousPathologyTherapy)));
    });

    test('writes absence counters only when they carry a value', () {
      final csv = CsvExportService.buildSimpleCsv([
        DailyTimesheet(
          dateId: '2026-05-21',
          startTime: DateTime(2026, 5, 21, 9),
          endTime: DateTime(2026, 5, 21, 12),
          standardPauseMins: 0,
          lunchPauseMins: 0,
          netWorkedMins: 180,
          extraMins: 0,
          workType: WorkType.leave,
          absenceKind: AbsenceKind.specialistVisit,
          absenceMins: 180,
        ),
      ]);

      final cells = _cells(_rows(csv)[1]);
      expect(cells[5], AbsenceKind.specialistVisit);
      expect(cells[6], '180'); // assenza_min
      expect(cells[7], isEmpty); // assenza_giorni: 0 non si scrive
    });
  });

  group('buildDetailedCsv', () {
    test('writes the 21 analysis columns', () {
      final rows = _rows(
        CsvExportService.buildDetailedCsv([_presence(netWorkedMins: 456)]),
      );

      expect(_cells(rows.first), hasLength(21));
      expect(_cells(rows[1]), hasLength(21));
      expect(_cells(rows.first).first, 'data');
      expect(_cells(rows.first).last, 'nota');
    });

    test('formats minutes as HH:MM alongside the raw value', () {
      final csv = CsvExportService.buildDetailedCsv([
        _presence(netWorkedMins: 456, extraMins: 75),
      ]);

      final cells = _cells(_rows(csv)[1]);
      expect(cells[7], '456'); // netto_min
      expect(cells[8], '07:36'); // netto_hhmm
      expect(cells[9], '75'); // extra_min
      expect(cells[10], '01:15'); // extra_hhmm
    });

    test('clamps a negative extra and leaves its HH:MM empty', () {
      final csv = CsvExportService.buildDetailedCsv([
        _presence(netWorkedMins: 400, extraMins: -56),
      ]);

      final cells = _cells(_rows(csv)[1]);
      expect(cells[9], '0');
      expect(cells[10], isEmpty);
    });

    test('flags the meal voucher against the threshold', () {
      String mealCell(int netWorkedMins) => _cells(
        _rows(
          CsvExportService.buildDetailedCsv([
            _presence(netWorkedMins: netWorkedMins),
          ]),
        )[1],
      )[13];

      expect(mealCell(379), '0');
      expect(mealCell(380), '1'); // soglia inclusiva
      expect(mealCell(456), '1');
    });

    test('honours a custom meal threshold', () {
      final csv = CsvExportService.buildDetailedCsv([
        _presence(netWorkedMins: 300),
      ], mealThresholdMins: 300);

      expect(_cells(_rows(csv)[1])[13], '1');
    });

    test('marks the sensitive column and still redacts the details', () {
      final csv = CsvExportService.buildDetailedCsv([
        DailyTimesheet(
          dateId: '2026-05-20',
          startTime: DateTime(2026, 5, 20, 9),
          endTime: DateTime(2026, 5, 20, 17),
          standardPauseMins: 0,
          lunchPauseMins: 0,
          netWorkedMins: 0,
          extraMins: 0,
          workType: WorkType.leave,
          note: 'terapia oncologica',
          absenceKind: AbsenceKind.seriousPathologyTherapy,
          sensitive: true,
        ),
      ]);

      final cells = _cells(_rows(csv)[1]);
      expect(cells[14], AbsenceKind.sensitiveLeave);
      expect(cells[19], '1'); // riservata
      expect(cells[20], isEmpty); // nota
      expect(csv, isNot(contains('oncologica')));
    });
  });

  group('round-trip export → import', () {
    test(
      'the simple CSV is re-importable without errors',
      skip: 'Task 4 (ADR-0018) ha riscritto CsvImportService.parse sul '
          'formato a segmenti; buildSimpleCsv scrive ancora il vecchio '
          'formato a giornata (segmento/tipo "presenza") e non e\' piu\' '
          're-importabile. Task 5 riscrive csv_export_service.dart sul '
          'formato a segmenti e sostituisce questo test.',
      () {
        final entries = [
          _presence(dateId: '2026-05-15', note: 'riunione; team'),
          DailyTimesheet(
            dateId: '2026-05-16',
            startTime: DateTime(2026, 5, 16, 9),
            endTime: DateTime(2026, 5, 16, 17),
            standardPauseMins: 0,
            lunchPauseMins: 0,
            netWorkedMins: 456,
            extraMins: 0,
            workType: WorkType.remote,
          ),
          DailyTimesheet(
            dateId: '2026-05-18',
            startTime: DateTime(2026, 5, 18, 9),
            endTime: DateTime(2026, 5, 18, 12),
            standardPauseMins: 0,
            lunchPauseMins: 0,
            netWorkedMins: 180,
            extraMins: 0,
            workType: WorkType.leave,
            absenceKind: AbsenceKind.specialistVisit,
            absenceMins: 180,
          ),
        ];

        final reimported = CsvImportService.parse(
          CsvExportService.buildSimpleCsv(entries),
        );

        expect(reimported.errors, isEmpty);
        expect(reimported.hasErrors, isFalse);
        expect(
          reimported.entries.map((e) => e.dateId),
          entries.map((e) => e.dateId),
        );
        expect(
          reimported.entries.map((e) => e.workType),
          entries.map((e) => e.workType),
        );
        expect(reimported.entries.first.note, 'riunione, team');
        expect(
            reimported.entries.last.absenceKind, AbsenceKind.specialistVisit);
        expect(reimported.entries.last.absenceMins, 180);
      },
    );

    test('a re-imported sensitive day carries no residual detail', () {
      final reimported = CsvImportService.parse(
        CsvExportService.buildSimpleCsv([
          DailyTimesheet(
            dateId: '2026-05-20',
            startTime: DateTime(2026, 5, 20, 9),
            endTime: DateTime(2026, 5, 20, 17),
            standardPauseMins: 0,
            lunchPauseMins: 0,
            netWorkedMins: 0,
            extraMins: 0,
            workType: WorkType.leave,
            note: 'terapia oncologica',
            absenceKind: AbsenceKind.seriousPathologyTherapy,
            sensitive: true,
          ),
        ]),
      );

      expect(reimported.errors, isEmpty);
      final entry = reimported.entries.single;
      expect(entry.absenceKind, AbsenceKind.sensitiveLeave);
      expect(entry.note ?? '', isEmpty);
    });

    test('the empty export produces just the header', () {
      final csv = CsvExportService.buildSimpleCsv([]);

      expect(_rows(csv), hasLength(1));
      expect(CsvImportService.parse(csv).entries, isEmpty);
      expect(CsvImportService.parse(csv).errors, isEmpty);
    });
  });
}
