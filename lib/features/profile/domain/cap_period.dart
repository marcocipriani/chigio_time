// An effective-dated snapshot of a user's inquadramento + caps.
//
// When the inquadramento (or any cap) changes, the current period is closed
// (toMonth set to the current month) and a new period is opened starting the
// following month. Past months therefore keep the caps that were in force at
// the time — see ADR-0009.
//
// Months are encoded as "YYYY-MM" strings so they sort and compare
// lexicographically (e.g. "2026-01" < "2026-02").
class CapPeriod {
  final String id;

  /// First month this period applies to, inclusive ("YYYY-MM").
  final String fromMonth;

  /// Last month this period applies to, inclusive ("YYYY-MM").
  /// `null` means the period is still open (current).
  final String? toMonth;

  final String inquadramento; // employmentType: 'Ruolo' | 'Comando' | 'Altro'
  final int standardDailyMins;
  final int mealVoucherThresholdMins;
  final int monthlyArt9Hours;
  final int monthlySliHours;
  final int monthlySboHours;
  final String scheduleVariant; // 'uniform' | 'mixed'
  final List<int> longWorkDays;

  const CapPeriod({
    required this.id,
    required this.fromMonth,
    required this.toMonth,
    required this.inquadramento,
    required this.standardDailyMins,
    required this.mealVoucherThresholdMins,
    required this.monthlyArt9Hours,
    required this.monthlySliHours,
    required this.monthlySboHours,
    required this.scheduleVariant,
    required this.longWorkDays,
  });

  bool get isOpen => toMonth == null;

  /// True when [month] ("YYYY-MM") falls within this period's range.
  bool covers(String month) =>
      fromMonth.compareTo(month) <= 0 &&
      (toMonth == null || month.compareTo(toMonth!) <= 0);

  int get monthlySauHours => monthlySliHours + monthlySboHours;

  /// Maggior-presenza cap = Art.9 + SLI + SBO (hours).
  int get tettoMaggiorPresenzaHours =>
      monthlyArt9Hours + monthlySliHours + monthlySboHours;

  factory CapPeriod.fromMap(String id, Map<String, dynamic> m) {
    final rawDays = m['longWorkDays'];
    return CapPeriod(
      id: id,
      fromMonth: m['fromMonth'] as String? ?? '',
      toMonth: m['toMonth'] as String?,
      inquadramento: m['inquadramento'] as String? ?? '',
      standardDailyMins: (m['standardDailyMins'] as num?)?.toInt() ?? 456,
      mealVoucherThresholdMins:
          (m['mealVoucherThresholdMins'] as num?)?.toInt() ?? 380,
      monthlyArt9Hours: (m['monthlyArt9Hours'] as num?)?.toInt() ?? 0,
      monthlySliHours: (m['monthlySliHours'] as num?)?.toInt() ?? 0,
      monthlySboHours: (m['monthlySboHours'] as num?)?.toInt() ?? 0,
      scheduleVariant: m['scheduleVariant'] as String? ?? 'uniform',
      longWorkDays: rawDays is List
          ? List<int>.from(rawDays.whereType<int>())
          : const [],
    );
  }

  Map<String, dynamic> toMap() => {
    'fromMonth': fromMonth,
    'toMonth': toMonth,
    'inquadramento': inquadramento,
    'standardDailyMins': standardDailyMins,
    'mealVoucherThresholdMins': mealVoucherThresholdMins,
    'monthlyArt9Hours': monthlyArt9Hours,
    'monthlySliHours': monthlySliHours,
    'monthlySboHours': monthlySboHours,
    'scheduleVariant': scheduleVariant,
    'longWorkDays': longWorkDays,
  };

  CapPeriod copyWith({String? id, String? fromMonth, String? toMonth}) =>
      CapPeriod(
        id: id ?? this.id,
        fromMonth: fromMonth ?? this.fromMonth,
        toMonth: toMonth ?? this.toMonth,
        inquadramento: inquadramento,
        standardDailyMins: standardDailyMins,
        mealVoucherThresholdMins: mealVoucherThresholdMins,
        monthlyArt9Hours: monthlyArt9Hours,
        monthlySliHours: monthlySliHours,
        monthlySboHours: monthlySboHours,
        scheduleVariant: scheduleVariant,
        longWorkDays: longWorkDays,
      );
}

/// Returns the period covering [month] ("YYYY-MM"), or null when none match.
/// When periods overlap (shouldn't happen) the latest `fromMonth` wins.
CapPeriod? capsForMonth(List<CapPeriod> periods, String month) {
  CapPeriod? best;
  for (final p in periods) {
    if (!p.covers(month)) continue;
    if (best == null || p.fromMonth.compareTo(best.fromMonth) > 0) best = p;
  }
  return best;
}
