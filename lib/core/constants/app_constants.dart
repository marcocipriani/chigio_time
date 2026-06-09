// Centralised numeric/domain constants for Chigio Time.
//
// Only values that appear in 2+ unrelated files belong here.
// Single-file magic numbers stay local to keep context.

abstract final class AppConstants {
  // ── Standard schedules (CCNL PCM) ────────────────────────────────────────
  /// Daily work minutes for "Ruolo" employees (7h 36m).
  static const stdDailyMinsRuolo = 456;

  /// Daily work minutes for "Comando" employees (7h 12m).
  static const stdDailyMinsComando = 432;

  // ── Meal voucher ──────────────────────────────────────────────────────────
  /// Default minutes worked required to earn a meal voucher (6h 20m).
  static const defaultMealVoucherThresholdMins = 380;
}
