import 'package:chigio_time/core/services/italian_holidays.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ItalianHolidays.forYear', () {
    test('includes the 10 national fixed holidays', () {
      final holidays = ItalianHolidays.forYear(2026, includeRome: false);

      for (final date in [
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 6),
        DateTime(2026, 4, 25),
        DateTime(2026, 5, 1),
        DateTime(2026, 6, 2),
        DateTime(2026, 8, 15),
        DateTime(2026, 11, 1),
        DateTime(2026, 12, 8),
        DateTime(2026, 12, 25),
        DateTime(2026, 12, 26),
      ]) {
        expect(holidays, contains(date), reason: '$date');
      }
    });

    test('adds Natale di Roma only when requested', () {
      expect(
        ItalianHolidays.forYear(2026),
        contains(DateTime(2026, 4, 21)),
      );
      expect(
        ItalianHolidays.forYear(2026, includeRome: false),
        isNot(contains(DateTime(2026, 4, 21))),
      );
    });

    test('counts 12 national + 1 Rome day when Easter does not overlap', () {
      // 2026: Pasqua 05/04, Lunedì dell'Angelo 06/04 — nessuna sovrapposizione
      // con le festività fisse, quindi il conteggio è pieno.
      expect(ItalianHolidays.forYear(2026, includeRome: false), hasLength(12));
      expect(ItalianHolidays.forYear(2026), hasLength(13));
    });

    test('computes Easter Sunday with the Gregorian algorithm', () {
      // Date ufficiali di Pasqua, verificabili sul calendario liturgico.
      const easters = {
        2013: (3, 31),
        2016: (3, 27),
        2020: (4, 12),
        2021: (4, 4),
        2022: (4, 17),
        2023: (4, 9),
        2024: (3, 31),
        2025: (4, 20),
        2026: (4, 5),
        2027: (3, 28),
        2030: (4, 21),
      };

      easters.forEach((year, md) {
        final (month, day) = md;
        expect(
          ItalianHolidays.forYear(year),
          contains(DateTime(year, month, day)),
          reason: 'Pasqua $year',
        );
      });
    });

    test(
      'keeps Easter Monday at local midnight even on the DST switch day',
      () {
        // Regressione: `sunday.add(const Duration(days: 1))` somma tempo
        // assoluto, quindi in Europe/Rome negli anni in cui Pasqua cade
        // nell'ultima domenica di marzo restituiva il lunedì alle 01:00 —
        // una chiave che non corrisponde mai alla mezzanotte confrontata da
        // `isHoliday`/`label`. Sotto TZ=UTC il test passa comunque: la
        // regressione si osserva con TZ=Europe/Rome (vedi job CI dedicato).
        const dstYears = {
          2013: (4, 1),
          2016: (3, 28),
          2024: (4, 1),
          2027: (3, 29),
          2032: (3, 29),
          2035: (3, 26),
        };

        dstYears.forEach((year, md) {
          final (month, day) = md;
          final easterMonday = DateTime(year, month, day);
          expect(
            ItalianHolidays.forYear(year),
            contains(easterMonday),
            reason: 'Lunedì dell\'Angelo $year',
          );
          expect(
            ItalianHolidays.isHoliday(easterMonday),
            isTrue,
            reason: 'isHoliday $year',
          );
          expect(
            ItalianHolidays.label(easterMonday),
            'Lunedì dell\'Angelo',
            reason: 'label $year',
          );
        });
      },
    );

    test('every returned date is a bare local midnight', () {
      for (var year = 2024; year <= 2035; year++) {
        for (final date in ItalianHolidays.forYear(year)) {
          expect(date.hour, 0, reason: '$date');
          expect(date.minute, 0, reason: '$date');
          expect(date.second, 0, reason: '$date');
        }
      }
    });
  });

  group('ItalianHolidays.isHoliday', () {
    test('ignores the time of day', () {
      expect(ItalianHolidays.isHoliday(DateTime(2026, 12, 25, 18, 42)), isTrue);
    });

    test('is false on a plain working day', () {
      expect(ItalianHolidays.isHoliday(DateTime(2026, 3, 17)), isFalse);
    });

    test('follows the Rome flag', () {
      expect(ItalianHolidays.isHoliday(DateTime(2026, 4, 21)), isTrue);
      expect(
        ItalianHolidays.isHoliday(DateTime(2026, 4, 21), includeRome: false),
        isFalse,
      );
    });
  });

  group('ItalianHolidays.label', () {
    test('returns the Italian name of the holiday', () {
      expect(ItalianHolidays.label(DateTime(2026, 1, 1)), 'Capodanno');
      expect(ItalianHolidays.label(DateTime(2026, 6, 2)), 'Festa della Repubblica');
      expect(ItalianHolidays.label(DateTime(2026, 4, 5)), 'Pasqua');
      expect(ItalianHolidays.label(DateTime(2026, 4, 6)), 'Lunedì dell\'Angelo');
      expect(ItalianHolidays.label(DateTime(2026, 12, 26)), 'Santo Stefano');
    });

    test('returns null outside holidays and honours the Rome flag', () {
      expect(ItalianHolidays.label(DateTime(2026, 3, 17)), isNull);
      expect(ItalianHolidays.label(DateTime(2026, 4, 21)), 'Natale di Roma');
      expect(
        ItalianHolidays.label(DateTime(2026, 4, 21), includeRome: false),
        isNull,
      );
    });

    test('ignores the time of day', () {
      expect(ItalianHolidays.label(DateTime(2026, 8, 15, 23, 59)), 'Ferragosto');
    });
  });
}
