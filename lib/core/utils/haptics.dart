import 'package:flutter/services.dart';

/// Thin wrapper over Flutter's built-in [HapticFeedback].
///
/// No dependency required: the platform's haptic engine is driven directly.
/// No-op where there is none (desktop/web) and honors the OS-level haptics
/// setting automatically — so no extra accessibility gating is needed.
class Haptics {
  Haptics._();

  /// Crisp tick for navigation/selection changes (screen switch, list pick).
  static void selection() => HapticFeedback.selectionClick();

  /// Soft tap for a minor confirmation (menu/button tap).
  static void light() => HapticFeedback.lightImpact();

  /// Firmer thud for a completed action (e.g. timbratura salvata).
  static void success() => HapticFeedback.mediumImpact();
}
