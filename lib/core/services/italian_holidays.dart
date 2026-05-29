/// Italian national public holidays + Rome municipal feast day.
///
/// Fixed holidays (same date every year):
///   01/01 Capodanno, 06/01 Epifania, 25/04 Liberazione, 01/05 Lavoro,
///   02/06 Repubblica, 15/08 Ferragosto, 01/11 Ognissanti, 08/12 Immacolata,
///   25/12 Natale, 26/12 Santo Stefano.
///
/// Moveable:
///   Pasqua (Easter Sunday) — Gregorian algorithm.
///   Lunedì dell'Angelo (Easter Monday) — Easter + 1.
///
/// Rome municipal:
///   21/04 Natale di Roma.
abstract final class ItalianHolidays {
  // Returns all holiday dates for [year] (national + Rome).
  static Set<DateTime> forYear(int year, {bool includeRome = true}) {
    final fixed = _fixed(year);
    final (easter, easterMonday) = _easter(year);
    return {
      ...fixed,
      easter,
      easterMonday,
      if (includeRome) DateTime(year, 4, 21), // Natale di Roma
    };
  }

  // Returns the holiday label for a date, or null if not a holiday.
  static String? label(DateTime date, {bool includeRome = true}) {
    final d = DateTime(date.year, date.month, date.day);
    final labels = _labels(date.year, includeRome: includeRome);
    return labels[d];
  }

  static bool isHoliday(DateTime date, {bool includeRome = true}) => forYear(
    date.year,
    includeRome: includeRome,
  ).contains(DateTime(date.year, date.month, date.day));

  // ── Internals ──────────────────────────────────────────────────────────────

  static Set<DateTime> _fixed(int y) => {
    DateTime(y, 1, 1),
    DateTime(y, 1, 6),
    DateTime(y, 4, 25),
    DateTime(y, 5, 1),
    DateTime(y, 6, 2),
    DateTime(y, 8, 15),
    DateTime(y, 11, 1),
    DateTime(y, 12, 8),
    DateTime(y, 12, 25),
    DateTime(y, 12, 26),
  };

  // Anonymous Gregorian algorithm for Easter Sunday.
  static (DateTime, DateTime) _easter(int y) {
    final a = y % 19;
    final b = y ~/ 100;
    final c = y % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    final sunday = DateTime(y, month, day);
    final monday = sunday.add(const Duration(days: 1));
    return (sunday, monday);
  }

  static Map<DateTime, String> _labels(int y, {required bool includeRome}) {
    final (easter, easterMonday) = _easter(y);
    return {
      DateTime(y, 1, 1): 'Capodanno',
      DateTime(y, 1, 6): 'Epifania',
      if (includeRome) DateTime(y, 4, 21): 'Natale di Roma',
      DateTime(y, 4, 25): 'Liberazione',
      easter: 'Pasqua',
      easterMonday: 'Lunedì dell\'Angelo',
      DateTime(y, 5, 1): 'Festa del Lavoro',
      DateTime(y, 6, 2): 'Festa della Repubblica',
      DateTime(y, 8, 15): 'Ferragosto',
      DateTime(y, 11, 1): 'Ognissanti',
      DateTime(y, 12, 8): 'Immacolata Concezione',
      DateTime(y, 12, 25): 'Natale',
      DateTime(y, 12, 26): 'Santo Stefano',
    };
  }
}
