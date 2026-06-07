import 'absence_kind.dart';

/// Plafond annuali personali per gli istituti orari piu' usati (CCNL PCM
/// 2019-2021). Riferimento: docs/ccnl/permessi-assenze-congedi.md (P1).
class AbsencePlafonds {
  static const int shortLeaveYearlyMins = 38 * 60;
  static const int personalFamilyHourlyYearlyMins = 18 * 60;
  static const int specialistVisitYearlyMins = 18 * 60;
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

/// Consumo personale annuo degli istituti orari piu' usati, calcolato dalle
/// entries `leave` con `absenceKind` valorizzato. Confrontato coi plafond
/// CCNL e coi residui del portale per dare un riscontro all'utente — il
/// portale resta sorgente di verita', l'app mostra solo un confronto.
class AbsenceConsumption {
  final int year;
  final int shortLeaveMins;
  final int personalFamilyHourlyMins;
  final int specialistVisitMins;
  final int specialistVisitCount;
  final int specialistVisitWithDocs;
  final List<SicknessPeriod> sicknessPeriods;

  const AbsenceConsumption({
    required this.year,
    required this.shortLeaveMins,
    required this.personalFamilyHourlyMins,
    required this.specialistVisitMins,
    required this.specialistVisitCount,
    required this.specialistVisitWithDocs,
    required this.sicknessPeriods,
  });

  int get sicknessDaysTotal =>
      sicknessPeriods.fold(0, (sum, p) => sum + p.days);

  bool get shortLeaveOverPlafond =>
      shortLeaveMins > AbsencePlafonds.shortLeaveYearlyMins;
  bool get personalFamilyHourlyOverPlafond =>
      personalFamilyHourlyMins > AbsencePlafonds.personalFamilyHourlyYearlyMins;
  bool get specialistVisitOverPlafond =>
      specialistVisitMins > AbsencePlafonds.specialistVisitYearlyMins;

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

const _kHourlyAbsenceKinds = [
  AbsenceKind.shortLeave,
  AbsenceKind.personalFamilyHourly,
  AbsenceKind.specialistVisit,
];

/// Calcola il consumo annuo dalle entries gia' caricate. Esposto come funzione
/// pura per essere testabile e riusabile dal provider.
AbsenceConsumption computeAbsenceConsumption({
  required int year,
  required Iterable<
    ({
      String dateId,
      String? absenceKind,
      int absenceMins,
      bool hasDocumentation,
    })
  >
  entries,
}) {
  var shortLeave = 0;
  var personalFamily = 0;
  var specialistVisit = 0;
  var specialistVisitCount = 0;
  var specialistVisitDocs = 0;
  final sicknessDates = <String>[];

  for (final e in entries) {
    final kind = e.absenceKind;
    final isTracked =
        kind != null &&
        (_kHourlyAbsenceKinds.contains(kind) || kind == AbsenceKind.sickness);
    if (!isTracked) continue;
    switch (e.absenceKind) {
      case AbsenceKind.shortLeave:
        shortLeave += e.absenceMins;
      case AbsenceKind.personalFamilyHourly:
        personalFamily += e.absenceMins;
      case AbsenceKind.specialistVisit:
        specialistVisit += e.absenceMins;
        specialistVisitCount++;
        if (e.hasDocumentation) specialistVisitDocs++;
      case AbsenceKind.sickness:
        sicknessDates.add(e.dateId);
    }
  }

  sicknessDates.sort();
  return AbsenceConsumption(
    year: year,
    shortLeaveMins: shortLeave,
    personalFamilyHourlyMins: personalFamily,
    specialistVisitMins: specialistVisit,
    specialistVisitCount: specialistVisitCount,
    specialistVisitWithDocs: specialistVisitDocs,
    sicknessPeriods: AbsenceConsumption.groupSicknessPeriods(sicknessDates),
  );
}
