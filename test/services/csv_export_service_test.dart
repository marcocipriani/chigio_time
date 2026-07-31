import 'package:chigio_time/features/timesheet/data/csv_export_service.dart';
import 'package:chigio_time/features/timesheet/data/csv_import_service.dart';
import 'package:chigio_time/features/timesheet/domain/absence_consumption.dart';
import 'package:chigio_time/features/timesheet/domain/absence_kind.dart';
import 'package:chigio_time/features/timesheet/domain/daily_timesheet.dart';
import 'package:chigio_time/features/timesheet/domain/day_segment.dart';
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
  List<DaySegment>? segments,
}) {
  final start = DateTime(2026, 5, 15, startHour, startMinute);
  final end = DateTime(2026, 5, 15, endHour, endMinute);
  return DailyTimesheet(
    dateId: dateId,
    startTime: start,
    endTime: end,
    standardPauseMins: 0,
    lunchPauseMins: 0,
    netWorkedMins: netWorkedMins,
    extraMins: extraMins,
    workType: WorkType.presence,
    note: note,
    segments:
        segments ?? [DaySegment(type: DaySegment.work, start: start, end: end)],
  );
}

List<String> _rows(String csv) =>
    csv.trim().split('\n').map((l) => l.trim()).toList();

List<String> _cells(String row) => row.split(';');

void main() {
  group('buildSimpleCsv', () {
    test('writes the segment header (ADR-0018)', () {
      final header = _rows(
        CsvExportService.buildSimpleCsv([_presence()]),
      ).first;

      expect(
        header,
        'data;segmento;da;a;minuti;causale;periodo_da;periodo_a;nota',
      );
    });

    test('writes clock times zero-padded for a work segment', () {
      final csv = CsvExportService.buildSimpleCsv([
        _presence(startHour: 8, startMinute: 5, endHour: 16, endMinute: 9),
      ]);

      expect(_cells(_rows(csv)[1]), [
        '2026-05-15',
        'work',
        '08:05',
        '16:09',
        '',
        '',
        '',
        '',
        '',
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

    test('maps every work type to its segment name', () {
      final csv = CsvExportService.buildSimpleCsv([
        _presence(dateId: '2026-05-10'),
        DailyTimesheet(
          dateId: '2026-05-11',
          startTime: DateTime(2026, 5, 11, 9),
          endTime: DateTime(2026, 5, 11, 17),
          standardPauseMins: 0,
          lunchPauseMins: 0,
          netWorkedMins: 456,
          extraMins: 0,
          workType: WorkType.remote,
        ),
        DailyTimesheet(
          dateId: '2026-05-12',
          startTime: DateTime(2026, 5, 12, 9),
          endTime: DateTime(2026, 5, 12, 17),
          standardPauseMins: 0,
          lunchPauseMins: 0,
          netWorkedMins: 0,
          extraMins: 0,
          workType: WorkType.holiday,
        ),
        DailyTimesheet(
          dateId: '2026-05-13',
          startTime: DateTime(2026, 5, 13, 9),
          endTime: DateTime(2026, 5, 13, 12),
          standardPauseMins: 0,
          lunchPauseMins: 0,
          netWorkedMins: 180,
          extraMins: 0,
          workType: WorkType.leave,
          absenceUnit: AbsenceUnit.hourly,
          absenceMins: 180,
        ),
        DailyTimesheet(
          dateId: '2026-05-14',
          startTime: DateTime(2026, 5, 14, 9),
          endTime: DateTime(2026, 5, 14, 17),
          standardPauseMins: 0,
          lunchPauseMins: 0,
          netWorkedMins: 0,
          extraMins: 0,
          workType: WorkType.leave,
          absenceUnit: AbsenceUnit.daily,
          absenceDays: 1,
        ),
        // workType null = documento legacy salvato prima che il campo
        // esistesse: va trattato come presenza, non scartato.
        DailyTimesheet(
          dateId: '2026-05-09',
          startTime: DateTime(2026, 5, 9, 9),
          endTime: DateTime(2026, 5, 9, 17),
          standardPauseMins: 0,
          lunchPauseMins: 0,
          netWorkedMins: 456,
          extraMins: 0,
          segments: [
            DaySegment(
              type: DaySegment.work,
              start: DateTime(2026, 5, 9, 9),
              end: DateTime(2026, 5, 9, 17),
            ),
          ],
        ),
      ]);

      final segByDate = {
        for (final r in _rows(csv).skip(1)) _cells(r)[0]: _cells(r)[1],
      };
      expect(segByDate['2026-05-09'], 'work'); // workType null
      expect(segByDate['2026-05-10'], 'work');
      expect(segByDate['2026-05-11'], 'smart_working');
      expect(segByDate['2026-05-12'], 'ferie');
      expect(segByDate['2026-05-13'], 'permesso');
      expect(segByDate['2026-05-14'], 'permesso_gg');
    });

    test('a legacy day with no segments still writes a fallback work row', () {
      // TimesheetRepository._fromRow (fallback offline) non deriva i
      // segmenti come fa DailyTimesheet.fromMap: una riga di cache scritta
      // prima della migrazione arriva con segments vuota. Senza fallback
      // questa giornata sparirebbe silenziosamente dall'export.
      final csv = CsvExportService.buildSimpleCsv([
        DailyTimesheet(
          dateId: '2026-05-08',
          startTime: DateTime(2026, 5, 8, 8, 30),
          endTime: DateTime(2026, 5, 8, 16, 42),
          standardPauseMins: 0,
          lunchPauseMins: 0,
          netWorkedMins: 456,
          extraMins: 0,
          workType: WorkType.presence,
          note: 'legacy',
        ),
      ]);

      expect(_rows(csv), hasLength(2));
      expect(_cells(_rows(csv)[1]), [
        '2026-05-08',
        'work',
        '08:30',
        '16:42',
        '',
        '',
        '',
        '',
        'legacy',
      ]);
    });

    test('neutralises separators and newlines inside the note', () {
      final csv = CsvExportService.buildSimpleCsv([
        _presence(note: 'riunione; poi\nrientro\r'),
      ]);

      // Una nota "sporca" non deve spostare le colonne né spezzare la riga.
      expect(_rows(csv), hasLength(2));
      expect(_cells(_rows(csv)[1]), hasLength(9));
      expect(_cells(_rows(csv)[1])[8], 'riunione, poi rientro');
    });

    test('redacts note and kind of a sensitive absence', () {
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
          sensitive: true,
        ),
      ]);

      final cells = _cells(_rows(csv)[1]);
      expect(cells[5], AbsenceKind.sensitiveLeave); // causale mascherata
      expect(cells[8], isEmpty); // nota
      expect(csv, isNot(contains('oncologica')));
      expect(csv, isNot(contains(AbsenceKind.seriousPathologyTherapy)));
    });

    test(
      'un permesso intra-giornata riservato non espone la causale reale',
      () {
        final start = DateTime(2026, 5, 25, 9);
        final end = DateTime(2026, 5, 25, 17);
        final csv = CsvExportService.buildSimpleCsv([
          DailyTimesheet(
            dateId: '2026-05-25',
            startTime: start,
            endTime: end,
            standardPauseMins: 0,
            lunchPauseMins: 0,
            netWorkedMins: 0,
            extraMins: 0,
            workType: WorkType.presence,
            sensitive: true,
            segments: [
              DaySegment(
                type: DaySegment.work,
                start: start,
                end: DateTime(2026, 5, 25, 12),
              ),
              DaySegment(
                type: DaySegment.leave,
                start: DateTime(2026, 5, 25, 12),
                end: DateTime(2026, 5, 25, 13),
                absenceKind: AbsenceKind.seriousPathologyTherapy,
              ),
              DaySegment(
                type: DaySegment.work,
                start: DateTime(2026, 5, 25, 13),
                end: end,
              ),
            ],
          ),
        ]);

        final leaveRow = _rows(
          csv,
        ).skip(1).map(_cells).firstWhere((c) => c[1] == DaySegment.leave);
        expect(leaveRow[5], AbsenceKind.sensitiveLeave);
        expect(csv, isNot(contains(AbsenceKind.seriousPathologyTherapy)));
      },
    );

    test('una giornata riservata non espone la causale', () {
      final e = DailyTimesheet(
        dateId: '2026-07-24',
        startTime: DateTime(2026, 7, 24, 9),
        endTime: DateTime(2026, 7, 24, 9),
        standardPauseMins: 0,
        lunchPauseMins: 0,
        netWorkedMins: 0,
        extraMins: 0,
        workType: WorkType.leave,
        absenceKind: AbsenceKind.specialistVisit,
        absenceUnit: AbsenceUnit.daily,
        absenceDays: 1,
        note: 'dettaglio privato',
        sensitive: true,
      );
      final csv = CsvExportService.buildSimpleCsv([e]);
      expect(csv, contains(AbsenceKind.sensitiveLeave));
      expect(csv, isNot(contains('specialist_visit')));
      expect(csv, isNot(contains('dettaglio privato')));
    });

    test('writes the absence minutes only for hourly leave, not daily', () {
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
          absenceUnit: AbsenceUnit.hourly,
          absenceMins: 180,
        ),
        DailyTimesheet(
          dateId: '2026-05-22',
          startTime: DateTime(2026, 5, 22, 9),
          endTime: DateTime(2026, 5, 22, 17),
          standardPauseMins: 0,
          lunchPauseMins: 0,
          netWorkedMins: 0,
          extraMins: 0,
          workType: WorkType.leave,
          absenceUnit: AbsenceUnit.daily,
          absenceDays: 1,
        ),
      ]);

      final rows = _rows(csv).skip(1).map(_cells).toList();
      expect(rows[0][1], 'permesso');
      expect(rows[0][4], '180'); // minuti
      expect(rows[0][5], AbsenceKind.specialistVisit);
      expect(rows[1][1], 'permesso_gg');
      expect(rows[1][4], isEmpty); // minuti: le giornate intere non li usano
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
    test('the simple CSV is re-importable without errors', () {
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
          absenceUnit: AbsenceUnit.hourly,
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
      expect(reimported.entries.last.absenceKind, AbsenceKind.specialistVisit);
      expect(reimported.entries.last.absenceMins, 180);
    });

    test(
      'round-trip: export semplice riletto dal parser da la stessa giornata',
      () {
        const d = '2026-07-23';
        DateTime at(int h, int m) => DateTime(2026, 7, 23, h, m);
        final original = DailyTimesheet(
          dateId: d,
          startTime: at(10, 25),
          endTime: at(18, 2),
          standardPauseMins: 0,
          lunchPauseMins: 0,
          netWorkedMins: 0,
          extraMins: 0,
          workType: WorkType.presence,
          note: 'Visita',
          segments: [
            DaySegment(
              type: DaySegment.work,
              start: at(10, 25),
              end: at(12, 52),
            ),
            DaySegment(
              type: DaySegment.leave,
              start: at(12, 52),
              end: at(15, 8),
              absenceKind: AbsenceKind.specialistVisit,
            ),
            DaySegment(type: DaySegment.work, start: at(15, 8), end: at(18, 2)),
          ],
        ).recomputedFromSegments(stdMins: 456);

        final csv = CsvExportService.buildSimpleCsv([original]);
        final back = CsvImportService.parse(csv).entries.single;

        expect(back.segments.length, 3);
        expect(back.netWorkedMins, original.netWorkedMins);
        expect(back.extraMins, original.extraMins);
        expect(back.leavePauseMins, original.leavePauseMins);
        expect(back.note, 'Visita');
      },
    );

    test('il template scaricabile e\' rileggibile dal parser', () {
      final r = CsvImportService.parse(CsvExportService.templateCsv);
      expect(r.errors, isEmpty);
      expect(r.entries, isNotEmpty);
    });

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

    test('permesso intra-giornata riservato: esportato e riletto', () {
      // L'export maschera la causale del segmento in `sensitive_leave`, che
      // non e' un istituto a plafond orario: l'import la rifiutava e la
      // giornata spariva del tutto (zero entries). Export e import devono
      // concordare sul file che l'app stessa produce.
      final start = DateTime(2026, 5, 25, 9);
      final end = DateTime(2026, 5, 25, 17);
      final csv = CsvExportService.buildSimpleCsv([
        DailyTimesheet(
          dateId: '2026-05-25',
          startTime: start,
          endTime: end,
          standardPauseMins: 0,
          lunchPauseMins: 0,
          netWorkedMins: 0,
          extraMins: 0,
          workType: WorkType.presence,
          sensitive: true,
          segments: [
            DaySegment(
              type: DaySegment.work,
              start: start,
              end: DateTime(2026, 5, 25, 12),
            ),
            DaySegment(
              type: DaySegment.leave,
              start: DateTime(2026, 5, 25, 12),
              end: DateTime(2026, 5, 25, 13),
              absenceKind: AbsenceKind.seriousPathologyTherapy,
            ),
            DaySegment(type: DaySegment.work, start: DateTime(2026, 5, 25, 13), end: end),
          ],
        ).recomputedFromSegments(stdMins: 456),
      ]);

      final back = CsvImportService.parse(csv);
      expect(back.errors, isEmpty);
      final entry = back.entries.single;
      expect(entry.sensitive, isTrue);
      expect(csv, isNot(contains(AbsenceKind.seriousPathologyTherapy)));
      // La maschera copre come il permesso che nasconde: gli stessi minuti
      // della giornata di partenza.
      expect(entry.leavePauseMins, 60);
      expect(entry.netWorkedMins, 420);
      expect(entry.extraMins, 24);
    });

    test(
      'giornata legacy: la causale sopravvive a export e reimport, '
      'e i contatori con lei',
      () {
        // Percorso completo del documento pre-ADR-0018: causale sul livello
        // giornata, nessun campo `segments`. Senza il riporto della causale
        // sul segmento derivato, l'export scrive una riga di permesso senza
        // causale e il consumo annuo scende a zero al reimport.
        final legacy = DailyTimesheet.fromMap({
          'dateId': '2026-04-08',
          'startTime': DateTime(2026, 4, 8, 9).toIso8601String(),
          'endTime': DateTime(2026, 4, 8, 17).toIso8601String(),
          'leavePauseMins': 60,
          'netWorkedMins': 420,
          'extraMins': -36,
          'workType': WorkType.presence,
          'absenceKind': AbsenceKind.specialistVisit,
          'absenceUnit': AbsenceUnit.hourly,
          'absenceMins': 60,
        });

        int consumo(Iterable<DailyTimesheet> entries) =>
            computeAbsenceConsumption(
              year: 2026,
              entries: entries,
            ).specialistVisitMins;

        expect(consumo([legacy]), 60);

        final back = CsvImportService.parse(
          CsvExportService.buildSimpleCsv([legacy]),
        );
        expect(back.errors, isEmpty);
        expect(consumo(back.entries), 60);
      },
    );

    test('assenza multi-giorno: le date del periodo sopravvivono', () {
      // Il formato a 7 colonne non aveva posto per `absenceUnit.period`: il
      // reimport azzerava unita', minuti, giornate e date, e l'import
      // sovrascriveva il documento buono con `fullOverwrite`.
      final malattia = DailyTimesheet(
        dateId: '2026-03-02',
        startTime: DateTime(2026, 3, 2, 9),
        endTime: DateTime(2026, 3, 2, 9),
        standardPauseMins: 0,
        lunchPauseMins: 0,
        netWorkedMins: 0,
        extraMins: 0,
        workType: WorkType.leave,
        note: 'Malattia',
        absenceKind: AbsenceKind.sickness,
        absenceUnit: AbsenceUnit.period,
        periodStart: '2026-03-02',
        periodEnd: '2026-03-11',
        countsAsSicknessPeriod: true,
      );

      final csv = CsvExportService.buildSimpleCsv([malattia]);
      expect(
        _cells(_rows(csv)[1]),
        [
          '2026-03-02',
          'permesso_gg',
          '',
          '',
          '',
          AbsenceKind.sickness,
          '2026-03-02',
          '2026-03-11',
          'Malattia',
        ],
      );

      final back = CsvImportService.parse(csv);
      expect(back.errors, isEmpty);
      final e = back.entries.single;
      expect(e.workType, WorkType.leave);
      expect(e.absenceKind, AbsenceKind.sickness);
      expect(e.absenceUnit, AbsenceUnit.period);
      expect(e.periodStart, '2026-03-02');
      expect(e.periodEnd, '2026-03-11');
      // Derivato dalla causale, non da una colonna in piu'.
      expect(e.countsAsSicknessPeriod, isTrue);
    });

    test('una riga a 7 colonne resta leggibile: la nota non diventa periodo',
        () {
      // I CSV generati prima dell'aggiunta delle due colonne del periodo non
      // vanno rigenerati.
      final r = CsvImportService.parse(
        '2026-01-02;work;09:00;17:00;;;riunione',
      );
      expect(r.errors, isEmpty);
      expect(r.entries.single.note, 'riunione');
    });

    test('the empty export produces just the header', () {
      final csv = CsvExportService.buildSimpleCsv([]);

      expect(_rows(csv), hasLength(1));
      expect(CsvImportService.parse(csv).entries, isEmpty);
      expect(CsvImportService.parse(csv).errors, isEmpty);
    });
  });
}
