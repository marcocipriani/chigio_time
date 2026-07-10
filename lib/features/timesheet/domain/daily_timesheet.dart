import '../../../core/constants/app_constants.dart';
import 'day_segment.dart';

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

  /// Day slices (work intervals + hourly leaves). Empty for full-day
  /// leave/holiday and for legacy docs whose fields couldn't be derived.
  final List<DaySegment> segments;

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
    this.segments = const [],
  });

  bool get isRemote => workType == WorkType.remote;
  bool get isLeave => workType == WorkType.leave;
  bool get isHoliday => workType == WorkType.holiday;

  DailyTimesheet copyWith({
    String? dateId,
    DateTime? startTime,
    DateTime? endTime,
    int? standardPauseMins,
    int? leavePauseMins,
    int? lunchPauseMins,
    int? netWorkedMins,
    int? extraMins,
    int? sliMins,
    int? sboMins,
    String? workType,
    String? note,
    int? bancaOreMins,
    String? boeSlot,
    String? absenceKind,
    String? absenceUnit,
    int? absenceMins,
    double? absenceDays,
    String? periodStart,
    String? periodEnd,
    int? quotaYear,
    bool? countsAsSicknessPeriod,
    bool? sensitive,
    String? personalNote,
    bool? hasDocumentation,
    List<DaySegment>? segments,
  }) => DailyTimesheet(
    dateId: dateId ?? this.dateId,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    standardPauseMins: standardPauseMins ?? this.standardPauseMins,
    leavePauseMins: leavePauseMins ?? this.leavePauseMins,
    lunchPauseMins: lunchPauseMins ?? this.lunchPauseMins,
    netWorkedMins: netWorkedMins ?? this.netWorkedMins,
    extraMins: extraMins ?? this.extraMins,
    sliMins: sliMins ?? this.sliMins,
    sboMins: sboMins ?? this.sboMins,
    workType: workType ?? this.workType,
    note: note ?? this.note,
    bancaOreMins: bancaOreMins ?? this.bancaOreMins,
    boeSlot: boeSlot ?? this.boeSlot,
    absenceKind: absenceKind ?? this.absenceKind,
    absenceUnit: absenceUnit ?? this.absenceUnit,
    absenceMins: absenceMins ?? this.absenceMins,
    absenceDays: absenceDays ?? this.absenceDays,
    periodStart: periodStart ?? this.periodStart,
    periodEnd: periodEnd ?? this.periodEnd,
    quotaYear: quotaYear ?? this.quotaYear,
    countsAsSicknessPeriod:
        countsAsSicknessPeriod ?? this.countsAsSicknessPeriod,
    sensitive: sensitive ?? this.sensitive,
    personalNote: personalNote ?? this.personalNote,
    hasDocumentation: hasDocumentation ?? this.hasDocumentation,
    segments: segments ?? this.segments,
  );

  /// Recomputes day totals from [segments]: start/end = min/max of work
  /// segments, leavePauseMins = sum of leave segments, lunch via the 9h
  /// 3-zone rule (never below what was already taken), extra may be
  /// negative (deficit). No-op copy when segments is empty.
  DailyTimesheet recomputedFromSegments({required int stdMins}) {
    if (segments.isEmpty) return this;

    final workSegs = segments.where((s) => s.workMins > 0).toList();
    final workSum = workSegs.fold<int>(0, (t, s) => t + s.workMins);
    final leaveSum = segments.fold<int>(0, (t, s) => t + s.leaveMins);

    // 9h rule applies to effective worked time (pauses already excluded
    // because gaps between work segments are simply not counted).
    final effective = workSum - standardPauseMins;
    final lunch = AppConstants.forcedLunchMins(
      effective,
      alreadyTakenMins: lunchPauseMins,
    );
    final net = (workSum - standardPauseMins - lunch).clamp(0, 9999).toInt();

    DateTime? minStart, maxEnd;
    for (final s in workSegs) {
      if (minStart == null || s.start!.isBefore(minStart)) minStart = s.start;
      if (maxEnd == null || s.end!.isAfter(maxEnd)) maxEnd = s.end;
    }

    return copyWith(
      startTime: minStart ?? startTime,
      endTime: maxEnd ?? endTime,
      leavePauseMins: leaveSum,
      lunchPauseMins: lunch,
      netWorkedMins: net,
      extraMins: net + bancaOreMins - stdMins,
    );
  }

  /// Deficit minutes NOT covered by hourly leave (permessi). 0 when the
  /// day is at/over schedule or fully covered.
  static int uncoveredDeficitMins(DailyTimesheet e) {
    if (e.extraMins >= 0) return 0;
    return (-e.extraMins - e.leavePauseMins).clamp(0, 9999);
  }

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
    if (segments.isNotEmpty)
      'segments': segments.map((s) => s.toMap()).toList(),
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
    final startTime = _parseDt(map['startTime'], dateId);
    final endTime = _parseDt(map['endTime'], dateId);
    final workType = map['workType'] as String?;
    final leavePauseMins = (map['leavePauseMins'] as num?)?.toInt() ?? 0;

    // Parse segments; legacy docs (no field) derive them lazily so the
    // whole app can assume segments exist for presence/remote days.
    // Tolerant: a non-list `segments` value degrades to the derive path.
    final rawSegments = map['segments'];
    var segments = rawSegments is List
        ? rawSegments
              .whereType<Map>()
              .map((m) => DaySegment.fromMap(Map<String, dynamic>.from(m)))
              .toList()
        : const <DaySegment>[];
    final isFullDayAbsence =
        workType == WorkType.leave || workType == WorkType.holiday;
    if (segments.isEmpty && !isFullDayAbsence && endTime.isAfter(startTime)) {
      segments = [
        DaySegment(type: DaySegment.work, start: startTime, end: endTime),
        if (leavePauseMins > 0)
          DaySegment(type: DaySegment.leave, mins: leavePauseMins),
      ];
    }

    return DailyTimesheet(
      dateId: dateId,
      startTime: startTime,
      endTime: endTime,
      standardPauseMins: (map['standardPauseMins'] as num?)?.toInt() ?? 0,
      leavePauseMins: leavePauseMins,
      lunchPauseMins: (map['lunchPauseMins'] as num?)?.toInt() ?? 0,
      netWorkedMins: (map['netWorkedMins'] as num?)?.toInt() ?? 0,
      extraMins: (map['extraMins'] as num?)?.toInt() ?? 0,
      sliMins: (map['sliMins'] as num?)?.toInt() ?? 0,
      sboMins: (map['sboMins'] as num?)?.toInt() ?? 0,
      workType: workType,
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
      segments: segments,
    );
  }
}
