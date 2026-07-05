// Causale specifica di assenza, usata quando workType == WorkType.leave
// (o in generale per giornate/periodi non lavorati). Tassonomia derivata da
// docs/ccnl/permessi-assenze-congedi.md (CCNL PCM 2019-2021 + base 2016-2018
// per gli istituti non sostituiti). Vedi anche docs/ccnl/articoli-app.md.
class AbsenceKind {
  static const shortLeave = 'short_leave';
  static const personalFamilyHourly = 'personal_family_hourly';
  static const specialistVisit = 'specialist_visit';
  static const sickness = 'sickness';
  static const seriousPathologyTherapy = 'serious_pathology_therapy';
  static const workInjury = 'work_injury';
  static const paidExamCompetition = 'paid_exam_competition';
  static const bereavement = 'bereavement';
  static const marriage = 'marriage';
  static const law104 = 'law_104';
  static const bloodDonation = 'blood_donation';
  static const civicDuty = 'civic_duty';
  static const parentalLeave = 'parental_leave';
  static const childSickness = 'child_sickness';
  static const studyPermit = 'study_permit';
  static const trainingLeave = 'training_leave';
  static const trainingRecord = 'training_record';
  static const unpaidExpectation = 'unpaid_expectation';
  static const sensitiveLeave = 'sensitive_leave';
  static const militaryService = 'military_service';

  /// Etichette leggibili in italiano per l'UI (selettore causale, riepiloghi).
  static const Map<String, String> labels = {
    shortLeave: 'Permesso breve (Art. 35)',
    personalFamilyHourly: 'Motivi personali/familiari',
    specialistVisit: 'Visita specialistica',
    sickness: 'Malattia',
    seriousPathologyTherapy: 'Grave patologia / terapia salvavita',
    workInjury: 'Infortunio',
    paidExamCompetition: 'Concorso/esame',
    bereavement: 'Lutto',
    marriage: 'Matrimonio',
    law104: 'Legge 104',
    bloodDonation: 'Donazione sangue',
    civicDuty: 'Funzione pubblica/giudice popolare',
    parentalLeave: 'Congedo parentale',
    childSickness: 'Malattia figlio/a',
    studyPermit: 'Diritto allo studio',
    trainingLeave: 'Congedo per formazione',
    trainingRecord: 'Formazione/aggiornamento',
    unpaidExpectation: 'Aspettativa non retribuita',
    sensitiveLeave: 'Assenza riservata',
    militaryService: 'Servizio militare',
  };

  /// Raggruppamento per categoria, usato per organizzare il selettore in UI.
  static const Map<String, List<String>> groups = {
    'Permessi orari': [shortLeave, personalFamilyHourly, specialistVisit],
    'Malattia e salute': [sickness, seriousPathologyTherapy, workInjury],
    'Permessi giornalieri': [
      paidExamCompetition,
      bereavement,
      marriage,
      law104,
      bloodDonation,
      civicDuty,
    ],
    'Congedi e famiglia': [parentalLeave, childSickness, sensitiveLeave],
    'Studio e formazione': [studyPermit, trainingLeave, trainingRecord],
    'Altro': [unpaidExpectation, militaryService],
  };

  static String labelFor(String? kind) => labels[kind] ?? 'Assenza';
}

// Unita' di misura del consumo dell'assenza.
// 'hourly' = consumo in minuti (absenceMins)
// 'daily'  = consumo in giorni, anche frazionabili (absenceDays)
// 'period' = intervallo multi-giorno (periodStart/periodEnd)
class AbsenceUnit {
  static const hourly = 'hourly';
  static const daily = 'daily';
  static const period = 'period';
}
