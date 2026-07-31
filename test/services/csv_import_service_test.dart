import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/features/timesheet/data/csv_import_service.dart';
import 'package:chigio_time/features/timesheet/domain/absence_kind.dart';
import 'package:chigio_time/features/timesheet/domain/daily_timesheet.dart';
import 'package:chigio_time/features/timesheet/domain/day_segment.dart';

void main() {
  group('CsvImportService.parse — formato a segmenti', () {
    test('piu\' righe compongono una sola giornata', () {
      final r = CsvImportService.parse(
        'data;segmento;da;a;minuti;causale;nota\n'
        '2026-07-23;work;10:25;12:52;;;Visita specialistica\n'
        '2026-07-23;leave;12:52;15:08;;specialist_visit;\n'
        '2026-07-23;work;15:08;18:02;;;',
      );
      expect(r.errors, isEmpty);
      expect(r.entries.length, 1);
      final e = r.entries.single;
      expect(e.workType, WorkType.presence);
      expect(e.segments.length, 3);
      expect(e.netWorkedMins, 321);
      expect(e.extraMins, 1);
      expect(e.note, 'Visita specialistica');
    });

    test('la nota e\' di giornata: vale la prima non vuota', () {
      final r = CsvImportService.parse(
        '2026-07-23;work;10:25;12:52;;;\n'
        '2026-07-23;work;15:08;18:02;;;seconda',
      );
      expect(r.entries.single.note, 'seconda');
    });

    test('segmento senza orari usa la colonna minuti', () {
      final r = CsvImportService.parse(
        '2026-03-04;banca_ore;08:40;10:23;;;\n'
        '2026-03-04;work;10:23;13:34;;;\n'
        '2026-03-04;work;13:41;16:23;;;\n'
        '2026-03-04;pause;;;0:07;;',
      );
      final e = r.entries.single;
      expect(e.standardPauseMins, 7);
      expect(e.bancaOreMins, 103);
      expect(e.extraMins, 0);
    });

    test('minuti accetta sia H:MM sia un intero', () {
      final r = CsvImportService.parse(
        '2026-03-04;work;09:00;16:36;;;\n'
        '2026-03-04;pause;;;7;;',
      );
      expect(r.entries.single.standardPauseMins, 7);
    });

    test('giornate intere: ferie, smart working, permesso a ore e a giornata', () {
      final r = CsvImportService.parse(
        '2026-07-14;ferie;;;;;\n'
        '2026-07-03;smart_working;;;;;\n'
        '2026-06-11;permesso;;;7:36;strike;\n'
        '2026-07-24;permesso_gg;;;;personal_family_hourly;',
      );
      expect(r.errors, isEmpty);
      expect(r.entries.length, 4);
      final byDate = {for (final e in r.entries) e.dateId: e};
      expect(byDate['2026-07-14']!.workType, WorkType.holiday);
      expect(byDate['2026-07-03']!.workType, WorkType.remote);
      expect(byDate['2026-06-11']!.workType, WorkType.leave);
      expect(byDate['2026-06-11']!.absenceKind, AbsenceKind.strike);
      expect(byDate['2026-06-11']!.absenceMins, 456);
      expect(byDate['2026-06-11']!.absenceUnit, AbsenceUnit.hourly);
      final gg = byDate['2026-07-24']!;
      expect(gg.absenceUnit, AbsenceUnit.daily);
      expect(gg.absenceDays, 1);
      expect(gg.absenceKind, AbsenceKind.personalFamilyHourly);
    });

    test('ferie con causale propria', () {
      final r = CsvImportService.parse(
        '2026-01-05;ferie;;;;suppressed_holiday;',
      );
      final e = r.entries.single;
      expect(e.workType, WorkType.holiday);
      expect(e.absenceKind, AbsenceKind.suppressedHoliday);
      expect(e.absenceDays, 1);
    });

    test('segmenti sovrapposti: errore, giornata scartata', () {
      final r = CsvImportService.parse(
        '2026-07-23;work;10:00;13:00;;;\n'
        '2026-07-23;leave;12:00;14:00;;specialist_visit;\n'
        '2026-07-24;ferie;;;;;',
      );
      expect(r.errors, hasLength(1));
      expect(r.errors.single, contains('2026-07-23'));
      expect(r.errors.single.toLowerCase(), contains('sovrappos'));
      expect(r.entries.map((e) => e.dateId), ['2026-07-24']);
    });

    test('segmenti fuori ordine vengono ordinati, non rifiutati', () {
      final r = CsvImportService.parse(
        '2026-07-23;work;15:08;18:02;;;\n'
        '2026-07-23;work;10:25;12:52;;;',
      );
      expect(r.errors, isEmpty);
      final e = r.entries.single;
      expect(e.segments.first.start!.hour, 10);
      expect(e.startTime.hour, 10);
      expect(e.endTime.hour, 18);
    });

    test('import robusto: riga rotta scartata, il resto passa', () {
      final r = CsvImportService.parse(
        '2026-07-23;work;10:25;12:52;;;\n'
        'data-rotta;work;09:00;17:00;;;\n'
        '2026-07-25;pippo;09:00;17:00;;;\n'
        '2026-07-26;work;09:00;17:00;;;\n'
        '2026-07-27;work;25:99;17:00;;;',
      );
      expect(r.errors, hasLength(3));
      expect(r.entries.map((e) => e.dateId), ['2026-07-23', '2026-07-26']);
    });

    test('causale sconosciuta segnalata ma la giornata resta', () {
      final r = CsvImportService.parse(
        '2026-07-23;work;10:25;12:00;;;\n'
        '2026-07-23;leave;12:00;13:00;;causale_inventata;\n'
        '2026-07-23;work;13:00;18:02;;;',
      );
      expect(r.errors, hasLength(1));
      final leave = r.entries.single.segments
          .singleWhere((s) => s.type == DaySegment.leave);
      expect(leave.absenceKind, isNull);
    });

    test('segmenti con lo stesso orario: sovrapposti anche se identici', () {
      final r = CsvImportService.parse(
        '2026-07-23;work;10:00;18:00;;;\n'
        '2026-07-23;leave;10:00;18:00;;specialist_visit;',
      );
      expect(r.errors, hasLength(1));
      expect(r.errors.single.toLowerCase(), contains('sovrappos'));
      expect(r.entries, isEmpty);
    });

    test('pausa fuori dallo span di lavoro: errore', () {
      final r = CsvImportService.parse(
        '2026-07-23;work;10:00;18:00;;;\n'
        '2026-07-23;pause;18:05;18:15;;;',
      );
      expect(r.errors, hasLength(1));
      expect(r.errors.single.toLowerCase(), contains('span'));
      expect(r.entries, isEmpty);
    });

    test('header riconosciuto e saltato', () {
      final r = CsvImportService.parse(
        'data;segmento;da;a;minuti;causale;nota\n'
        '2026-07-03;smart_working;;;;;',
      );
      expect(r.entries.length, 1);
    });

    test('giornata di soli segmenti orari senza work: errore', () {
      final r = CsvImportService.parse('2026-07-23;lunch;12:00;13:00;;;');
      expect(r.errors, hasLength(1));
      expect(r.entries, isEmpty);
    });

    test('intervallo rovesciato: riga rifiutata, nessuna giornata segnaposto',
        () {
      // L'import scrive con fullOverwrite: una giornata segnaposto
      // 09:00–09:00 con netto 0 cancellerebbe quella buona.
      final r = CsvImportService.parse('2026-01-02;work;18:00;09:00;;;');
      expect(r.errors, hasLength(1));
      expect(r.entries, isEmpty);

      final uguali = CsvImportService.parse('2026-01-02;work;09:00;09:00;;;');
      expect(uguali.errors, hasLength(1));
      expect(uguali.entries, isEmpty);
    });

    test('causale non oraria su un segmento leave: giornata scartata', () {
      // Lo sciopero non copre e non consuma (griglia ADR-0018): come segmento
      // `leave` coprirebbe l'orario dovuto e produrrebbe eccedenza.
      final r = CsvImportService.parse(
        '2026-01-02;work;09:00;13:00;;;\n'
        '2026-01-02;leave;13:00;17:00;;strike;\n'
        '2026-01-05;leave;13:00;14:00;;specialist_visit;\n'
        '2026-01-05;work;09:00;13:00;;;',
      );
      expect(r.errors, hasLength(1));
      expect(r.errors.single, contains('strike'));
      // La causale oraria resta ammessa.
      expect(r.entries.map((e) => e.dateId), ['2026-01-05']);
    });

    test('work con i soli minuti: errore, non un\'eccezione', () {
      // Prima questa riga passava la validazione e faceva morire l'intero
      // import dentro recomputedFromSegments (start nullo dereferenziato).
      late CsvImportResult r;
      expect(
        () => r = CsvImportService.parse(
          '2026-01-02;work;;;480;;\n'
          '2026-01-03;work;09:00;17:00;;;',
        ),
        returnsNormally,
      );
      expect(r.errors, hasLength(1));
      expect(r.entries.map((e) => e.dateId), ['2026-01-03']);
    });
  });
}
