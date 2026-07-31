import 'absence_kind.dart';
import 'daily_timesheet.dart';
import 'day_segment.dart';

/// Tipo di limite di un istituto.
/// `hourly` = plafond annuo in minuti; `daily` = quota annua in giorni;
/// `credit` = credito il cui saldo vive nel portale; `none` = nessun limite.
class AbsenceLimit {
  static const hourly = 'hourly';
  static const daily = 'daily';
  static const credit = 'credit';
  static const none = 'none';
}

/// Limiti annuali personali per gli istituti che l'app conta.
/// Riferimenti: docs/ccnl/permessi-assenze-congedi.md.
class AbsencePlafonds {
  // Usati da totalizzatori_section.dart per mostrare il plafond a schermo:
  // derivano dalla tabella, cosi' il valore vive in un posto solo.
  static int get shortLeaveYearlyMins => _limits[AbsenceKind.shortLeave]!.amount;
  static int get personalFamilyHourlyYearlyMins =>
      _limits[AbsenceKind.personalFamilyHourly]!.amount;
  static int get specialistVisitYearlyMins =>
      _limits[AbsenceKind.specialistVisit]!.amount;

  static const _limits = <String, ({String type, int amount})>{
    AbsenceKind.shortLeave: (type: AbsenceLimit.hourly, amount: 38 * 60),
    AbsenceKind.personalFamilyHourly:
        (type: AbsenceLimit.hourly, amount: 18 * 60),
    AbsenceKind.specialistVisit: (type: AbsenceLimit.hourly, amount: 18 * 60),
    AbsenceKind.assembly: (type: AbsenceLimit.hourly, amount: 12 * 60),
    AbsenceKind.suppressedHoliday: (type: AbsenceLimit.daily, amount: 4),
    AbsenceKind.strike: (type: AbsenceLimit.none, amount: 0),
    AbsenceKind.workedHolidayComp: (type: AbsenceLimit.credit, amount: 0),
    AbsenceKind.compensatoryRest: (type: AbsenceLimit.credit, amount: 0),
  };

  static ({String type, int amount})? limitFor(String kind) => _limits[kind];

  /// Minuti della giornata convenzionale, per le causali che ne hanno una.
  static const _dayEquivalent = <String, int>{
    AbsenceKind.personalFamilyHourly: 6 * 60,
  };

  static int? dayEquivalentMins(String kind) => _dayEquivalent[kind];
}

/// Periodo continuativo di malattia (giorni consecutivi con
/// `absenceKind == AbsenceKind.sickness`).
class SicknessPeriod {
  final String startDateId;
  final String endDateId;
  final int days;
  const SicknessPeriod({
    required this.startDateId,
    required this.endDateId,
    required this.days,
  });
}

/// Consumo personale annuo degli istituti che l'app conta, calcolato dalle
/// entries `leave` con `absenceKind` valorizzato (a livello di giornata o di
/// segmento). Confrontato coi plafond CCNL e coi residui del portale per dare
/// un riscontro all'utente — il portale resta sorgente di verita', l'app
/// mostra solo un confronto.
class AbsenceConsumption {
  final int year;
  final Map<String, int> mins;
  final Map<String, double> days;
  final int specialistVisitCount;
  final int specialistVisitWithDocs;
  final List<SicknessPeriod> sicknessPeriods;

  const AbsenceConsumption({
    required this.year,
    required this.mins,
    required this.days,
    required this.specialistVisitCount,
    required this.specialistVisitWithDocs,
    required this.sicknessPeriods,
  });

  int minsFor(String kind) => mins[kind] ?? 0;
  double daysFor(String kind) => days[kind] ?? 0;

  int get shortLeaveMins => minsFor(AbsenceKind.shortLeave);
  int get personalFamilyHourlyMins => minsFor(AbsenceKind.personalFamilyHourly);
  int get specialistVisitMins => minsFor(AbsenceKind.specialistVisit);

  int get sicknessDaysTotal =>
      sicknessPeriods.fold(0, (sum, p) => sum + p.days);

  /// True quando il consumo supera il limite dichiarato dall'istituto.
  bool overLimit(String kind) {
    final limit = AbsencePlafonds.limitFor(kind);
    if (limit == null) return false;
    return switch (limit.type) {
      AbsenceLimit.hourly => minsFor(kind) > limit.amount,
      AbsenceLimit.daily => daysFor(kind) > limit.amount,
      _ => false,
    };
  }

  bool get shortLeaveOverPlafond => overLimit(AbsenceKind.shortLeave);
  bool get personalFamilyHourlyOverPlafond =>
      overLimit(AbsenceKind.personalFamilyHourly);
  bool get specialistVisitOverPlafond => overLimit(AbsenceKind.specialistVisit);

  static List<SicknessPeriod> groupSicknessPeriods(List<String> sortedDateIds) {
    if (sortedDateIds.isEmpty) return const [];
    final periods = <SicknessPeriod>[];
    var periodStart = sortedDateIds.first;
    var prev = _parseDateId(sortedDateIds.first);
    var count = 1;

    for (var i = 1; i < sortedDateIds.length; i++) {
      final cur = _parseDateId(sortedDateIds[i]);
      if (cur.difference(prev).inDays == 1) {
        count++;
      } else {
        periods.add(
          SicknessPeriod(
            startDateId: periodStart,
            endDateId: sortedDateIds[i - 1],
            days: count,
          ),
        );
        periodStart = sortedDateIds[i];
        count = 1;
      }
      prev = cur;
    }
    periods.add(
      SicknessPeriod(
        startDateId: periodStart,
        endDateId: sortedDateIds.last,
        days: count,
      ),
    );
    return periods;
  }

  static DateTime _parseDateId(String dateId) {
    final p = dateId.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }
}

/// Quota di assenza estratta da una giornata: causale piu' consumo.
typedef _Quota = ({String kind, int mins, double days, bool hasDocs});

Iterable<_Quota> _quotasOf(DailyTimesheet e) sync* {
  final leaveSegments = e.segments.where(
    (s) => s.type == DaySegment.leave && s.absenceKind != null,
  );
  // I due livelli sono mutuamente esclusivi per costruzione (ADR-0018): una
  // giornata di assenza intera ha zero segmenti, un permesso orario dentro
  // una giornata di presenza porta la causale sui segmenti. Se entrambi sono
  // valorizzati il documento e' incoerente; i segmenti vincono per non
  // sommare due volte lo stesso consumo.
  if (leaveSegments.isNotEmpty) {
    for (final s in leaveSegments) {
      yield (
        kind: s.absenceKind!,
        mins: s.durationMins,
        days: 0,
        hasDocs: e.hasDocumentation,
      );
    }
    return;
  }
  final kind = e.absenceKind;
  if (kind != null) {
    final dayEq = AbsencePlafonds.dayEquivalentMins(kind);
    // Giornata convenzionale: il consumo lo decide la causale, non l'orario.
    final mins = e.absenceUnit == AbsenceUnit.daily && dayEq != null
        ? (e.absenceDays * dayEq).round()
        : e.absenceMins;
    yield (kind: kind, mins: mins, days: e.absenceDays, hasDocs: e.hasDocumentation);
  }
}

/// Calcola il consumo annuo dalle entries gia' caricate. Legge sia i campi
/// di giornata sia i segmenti `leave`, cosi' un permesso fruito dentro una
/// giornata di presenza scala il plafond. Vedi ADR-0018.
AbsenceConsumption computeAbsenceConsumption({
  required int year,
  required Iterable<DailyTimesheet> entries,
}) {
  final mins = <String, int>{};
  final days = <String, double>{};
  var specialistCount = 0;
  var specialistDocs = 0;
  final sicknessDates = <String>[];

  for (final e in entries) {
    for (final q in _quotasOf(e)) {
      mins[q.kind] = (mins[q.kind] ?? 0) + q.mins;
      days[q.kind] = (days[q.kind] ?? 0) + q.days;
      if (q.kind == AbsenceKind.specialistVisit) {
        specialistCount++;
        if (q.hasDocs) specialistDocs++;
      }
      if (q.kind == AbsenceKind.sickness) sicknessDates.add(e.dateId);
    }
  }

  sicknessDates.sort();
  return AbsenceConsumption(
    year: year,
    mins: mins,
    days: days,
    specialistVisitCount: specialistCount,
    specialistVisitWithDocs: specialistDocs,
    sicknessPeriods: AbsenceConsumption.groupSicknessPeriods(sicknessDates),
  );
}
