// Work types saved in Firestore under the `workType` field.
// 'presence'  = normal in-office day (default / null → backwards-compat)
// 'remote'    = smart-working day (full standard hours, meal auto-earned)
// 'leave'     = permesso orario / giornata permesso
// 'holiday'   = ferie
class WorkType {
  static const presence = 'presence';
  static const remote = 'remote';
  static const leave = 'leave';
  static const holiday = 'holiday';
}

// Slot in cui il BOE (Banca Ore come Esonero) è posizionato nella giornata.
// 'pre_entry'  = ore accreditate prima della timbratura di entrata
// 'pause'      = riduzione di una pausa (pranzo o breve)
// 'post_exit'  = completamento orario dopo la timbratura di uscita
class BoeSlot {
  static const preEntry = 'pre_entry';
  static const pause = 'pause';
  static const postExit = 'post_exit';
}

class DailyTimesheet {
  final String dateId;
  final DateTime startTime;
  final DateTime endTime;

  /// Short coffee/break pauses (not Art. 9)
  final int standardPauseMins;

  /// Art. 9 — permessi brevi (tracked separately for the monthly cap)
  final int leavePauseMins;
  final int lunchPauseMins;
  final int netWorkedMins;
  final int extraMins;

  /// Straordinario liquidato in busta paga (SLI) — default 0, backwards-compat
  final int sliMins;

  /// Straordinario messo in banca ore (SBO) — default 0, backwards-compat
  final int sboMins;
  // null means 'presence' for documents saved before this field was added
  final String? workType;
  final String? note;

  /// Minuti di banca ore usati come esonero (BOE) in questa giornata.
  /// La deduzione avviene prima su AP (anno precedente) poi su AC (anno corrente).
  final int bancaOreMins;

  /// Slot BOE: BoeSlot.preEntry | BoeSlot.pause | BoeSlot.postExit | null
  final String? boeSlot;

  // --- Dettaglio assenza personale (vedi AbsenceKind / docs/ccnl) ---
  /// Causale specifica quando workType == leave/holiday (vedi AbsenceKind).
  final String? absenceKind;

  /// AbsenceUnit.hourly | daily | period | null
  final String? absenceUnit;

  /// Consumo stimato in minuti (unita' hourly).
  final int absenceMins;

  /// Consumo stimato in giorni, anche frazionabile (unita' daily).
  final double absenceDays;

  /// Range data ISO (YYYY-MM-DD) per assenze multi-giorno (unita' period).
  final String? periodStart;
  final String? periodEnd;

  /// Anno di competenza dei contatori personali (default: anno di dateId).
  final int? quotaYear;

  /// Flag personale: questa assenza conta nel periodo di comporto malattia.
  final bool countsAsSicknessPeriod;

  /// Nasconde la causale dettagliata in viste social/export rapidi.
  final bool sensitive;

  /// Nota privata dell'utente (non mostrata nelle viste social).
  final String? personalNote;

  /// Promemoria personale: documentazione presente/non presente.
  final bool hasDocumentation;

  DailyTimesheet({
    required this.dateId,
    required this.startTime,
    required this.endTime,
    required this.standardPauseMins,
    this.leavePauseMins = 0,
    required this.lunchPauseMins,
    required this.netWorkedMins,
    required this.extraMins,
    this.sliMins = 0,
    this.sboMins = 0,
    this.workType,
    this.note,
    this.bancaOreMins = 0,
    this.boeSlot,
    this.absenceKind,
    this.absenceUnit,
    this.absenceMins = 0,
    this.absenceDays = 0,
    this.periodStart,
    this.periodEnd,
    this.quotaYear,
    this.countsAsSicknessPeriod = false,
    this.sensitive = false,
    this.personalNote,
    this.hasDocumentation = false,
  });

  bool get isRemote => workType == WorkType.remote;
  bool get isLeave => workType == WorkType.leave;
  bool get isHoliday => workType == WorkType.holiday;

  Map<String, dynamic> toMap() => {
    'dateId': dateId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'standardPauseMins': standardPauseMins,
    'leavePauseMins': leavePauseMins,
    'lunchPauseMins': lunchPauseMins,
    'netWorkedMins': netWorkedMins,
    'extraMins': extraMins,
    'sliMins': sliMins,
    'sboMins': sboMins,
    'workType': workType ?? WorkType.presence,
    if (note != null && note!.isNotEmpty) 'note': note,
    if (bancaOreMins > 0) 'bancaOreMins': bancaOreMins,
    if (boeSlot != null) 'boeSlot': boeSlot,
    if (absenceKind != null) 'absenceKind': absenceKind,
    if (absenceUnit != null) 'absenceUnit': absenceUnit,
    if (absenceMins > 0) 'absenceMins': absenceMins,
    if (absenceDays > 0) 'absenceDays': absenceDays,
    if (periodStart != null) 'periodStart': periodStart,
    if (periodEnd != null) 'periodEnd': periodEnd,
    if (quotaYear != null) 'quotaYear': quotaYear,
    if (countsAsSicknessPeriod)
      'countsAsSicknessPeriod': countsAsSicknessPeriod,
    if (sensitive) 'sensitive': sensitive,
    if (personalNote != null && personalNote!.isNotEmpty)
      'personalNote': personalNote,
    if (hasDocumentation) 'hasDocumentation': hasDocumentation,
    'updatedAt': DateTime.now().toUtc().toIso8601String(),
  };

  // Tolerant parse: a single legacy/corrupt doc (missing or unparseable
  // start/end time) must not throw and kill the whole timesheet stream.
  // Falls back to the day's midnight (from dateId), then to the epoch — every
  // other field in fromMap is likewise null-safe.
  static DateTime _parseDt(Object? value, String dateId) {
    if (value is String) {
      final dt = DateTime.tryParse(value);
      if (dt != null) return dt;
    }
    return DateTime.tryParse(dateId) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  factory DailyTimesheet.fromMap(Map<String, dynamic> map) {
    final dateId = map['dateId'] as String? ?? '';
    return DailyTimesheet(
      dateId: dateId,
      startTime: _parseDt(map['startTime'], dateId),
      endTime: _parseDt(map['endTime'], dateId),
      standardPauseMins: (map['standardPauseMins'] as num?)?.toInt() ?? 0,
      leavePauseMins: (map['leavePauseMins'] as num?)?.toInt() ?? 0,
      lunchPauseMins: (map['lunchPauseMins'] as num?)?.toInt() ?? 0,
      netWorkedMins: (map['netWorkedMins'] as num?)?.toInt() ?? 0,
      extraMins: (map['extraMins'] as num?)?.toInt() ?? 0,
      sliMins: (map['sliMins'] as num?)?.toInt() ?? 0,
      sboMins: (map['sboMins'] as num?)?.toInt() ?? 0,
      workType: map['workType'] as String?,
      note: map['note'] as String?,
      bancaOreMins: (map['bancaOreMins'] as num?)?.toInt() ?? 0,
      boeSlot: map['boeSlot'] as String?,
      absenceKind: map['absenceKind'] as String?,
      absenceUnit: map['absenceUnit'] as String?,
      absenceMins: (map['absenceMins'] as num?)?.toInt() ?? 0,
      absenceDays: (map['absenceDays'] as num?)?.toDouble() ?? 0,
      periodStart: map['periodStart'] as String?,
      periodEnd: map['periodEnd'] as String?,
      quotaYear: (map['quotaYear'] as num?)?.toInt(),
      countsAsSicknessPeriod: map['countsAsSicknessPeriod'] as bool? ?? false,
      sensitive: map['sensitive'] as bool? ?? false,
      personalNote: map['personalNote'] as String?,
      hasDocumentation: map['hasDocumentation'] as bool? ?? false,
    );
  }
}
