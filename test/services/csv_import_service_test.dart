import 'package:flutter_test/flutter_test.dart';
import 'package:chigio_time/features/timesheet/data/csv_import_service.dart';
import 'package:chigio_time/features/timesheet/domain/daily_timesheet.dart';

void main() {
  group('CsvImportService.parse', () {
    test('riga presenza valida → 1 entry, 0 errori', () {
      final r = CsvImportService.parse(
        'data;tipo;entrata;uscita;nota\n'
        '2026-05-15;presenza;09:00;17:36;Meeting',
      );
      expect(r.entries.length, 1);
      expect(r.errors, isEmpty);
      expect(r.entries.first.workType, WorkType.presence);
    });

    test('header saltato', () {
      final r = CsvImportService.parse(
        'data;tipo;entrata;uscita\n2026-05-16;smart_working',
      );
      expect(r.entries.length, 1);
      expect(r.entries.first.workType, WorkType.remote);
    });

    test('ferie e permesso riconosciuti', () {
      final r = CsvImportService.parse(
        '2026-05-17;ferie\n2026-05-18;permesso;09:00;12:00;Visita',
      );
      expect(r.entries.length, 2);
      expect(r.entries[0].workType, WorkType.holiday);
      expect(r.entries[1].workType, WorkType.leave);
    });

    test('import robusto: riga malformata saltata, valide importate', () {
      final r = CsvImportService.parse(
        '2026-05-15;presenza;09:00;17:36\n'
        'data-rotta;presenza;09:00;17:00\n' // data non valida
        '2026-05-19;pippo;09:00;17:00\n' // tipo sconosciuto
        '2026-05-20;presenza;09:00;17:00',
      );
      expect(r.entries.length, 2); // solo le 2 presenze valide
      expect(r.errors.length, 2); // data rotta + tipo sconosciuto
      expect(r.hasErrors, isTrue);
    });

    test('presenza con uscita prima di entrata → errore', () {
      final r = CsvImportService.parse('2026-05-21;presenza;17:00;09:00');
      expect(r.entries, isEmpty);
      expect(r.errors.length, 1);
    });

    test('date duplicate: conserva la prima riga e segnala la seconda', () {
      final r = CsvImportService.parse(
        '2026-05-15;presenza;09:00;17:36\n'
        '2026-05-15;smart_working',
      );

      expect(r.entries, hasLength(1));
      expect(r.entries.single.workType, WorkType.presence);
      expect(r.errors, contains('Riga 2: data duplicata ("2026-05-15")'));
    });
  });
}
