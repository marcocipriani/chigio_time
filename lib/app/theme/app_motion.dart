import 'package:flutter/widgets.dart';

/// Reduced-motion helpers.
///
/// Honors the OS "reduce motion" preference (iOS Reduce Motion, Android
/// "Remove animations", `prefers-reduced-motion` on web — all surfaced by
/// Flutter as [MediaQueryData.disableAnimations]). When enabled, animation
/// durations collapse to [Duration.zero] so `AnimatedX` widgets and
/// transitions settle instantly: the UI still reaches the same end state,
/// it just doesn't move. WCAG 2.3.3 / Apple HIG / Material.
extension MotionContext on BuildContext {
  /// `true` when the user asked the OS to minimize motion.
  bool get reduceMotion => MediaQuery.maybeOf(this)?.disableAnimations ?? false;

  /// [ms] milliseconds normally, [Duration.zero] under reduced motion.
  Duration motion(int ms) =>
      reduceMotion ? Duration.zero : Duration(milliseconds: ms);
}
