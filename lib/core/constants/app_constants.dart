// Centralised numeric/domain constants for Chigio Time.
//
// Only values that appear in 2+ unrelated files belong here.
// Single-file magic numbers stay local to keep context.

abstract final class AppConstants {
  // ── Standard schedules (CCNL PCM) ────────────────────────────────────────
  /// Uniform: Ruolo 38h/week → 7h36/day
  static const stdDailyMinsRuolo = 456;

  /// Uniform: Comando 36h/week → 7h12/day
  static const stdDailyMinsComando = 432;

  /// Mixed short days: Ruolo → 6h40 (3 days/week)
  static const stdDailyMinsRuoloShort = 400;

  /// Mixed short days: Comando → 6h (3 days/week)
  static const stdDailyMinsComandoShort = 360;

  /// Mixed long days: 9h (2 days/week, both Ruolo and Comando)
  static const stdDailyMinsLong = 540;

  /// Weekly target: Ruolo 38h
  static const weeklyMinsRuolo = 2280;

  /// Weekly target: Comando 36h
  static const weeklyMinsComando = 2160;

  // ── Art. 9 monthly caps ───────────────────────────────────────────────────
  /// Ruolo: max 8h/month (CCNL PCM)
  static const art9MonthlyCapMinsRuolo = 480;

  /// Comando: max 17h/month (CCNL PCM)
  static const art9MonthlyCapMinsComando = 1020;

  // ── Meal voucher ──────────────────────────────────────────────────────────
  /// Minutes worked required to earn a meal voucher (6h 20m) — all types.
  static const defaultMealVoucherThresholdMins = 380;

  // ── Schedule variant identifiers ─────────────────────────────────────────
  static const scheduleUniform = 'uniform';
  static const scheduleMixed = 'mixed';

  // ── Per-day schedule helper ───────────────────────────────────────────────
  /// Returns expected work minutes for [date] based on the user's Firestore
  /// [profile]. Reads: scheduleVariant ('uniform'|'mixed'), employmentType,
  /// longWorkDays (List of weekday ints, 1=Mon…5=Fri),
  /// standardDailyMins (used as-is for uniform/Altro).
  static int stdMinsForDate(Map<String, dynamic> profile, DateTime date) {
    final variant = profile['scheduleVariant'] as String? ?? scheduleUniform;
    if (variant == scheduleMixed) {
      final type = profile['employmentType'] as String? ?? '';
      final rawDays = profile['longWorkDays'];
      final longDays = rawDays is List
          ? List<int>.from(rawDays.whereType<int>())
          : <int>[];
      if (longDays.contains(date.weekday)) return stdDailyMinsLong;
      if (date.weekday >= 6) return 0; // weekend
      return type == 'Comando' ? stdDailyMinsComandoShort : stdDailyMinsRuoloShort;
    }
    // Uniform or Altro: use stored value, fallback by type
    final stored = profile['standardDailyMins'] as int?;
    if (stored != null) return stored;
    final type = profile['employmentType'] as String? ?? '';
    return type == 'Comando' ? stdDailyMinsComando : stdDailyMinsRuolo;
  }
}
