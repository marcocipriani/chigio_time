/// ID giorno canonico `YYYY-MM-DD` (doc ID timesheet, statusDate, confronti
/// "è oggi?"). SEMPRE ora LOCALE, mai UTC: il cartellino segue il giorno
/// civile italiano (review 2026-07-05, M1 — statusDate in UTC sfasava la
/// vista colleghi tra la mezzanotte UTC e quella locale).
String dateIdOf(DateTime d) =>
    '${d.year}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String todayId() => dateIdOf(DateTime.now());
