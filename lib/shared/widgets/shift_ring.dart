import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/theme/color_schemes.dart';
import '../../core/constants/app_constants.dart';

/// Dual-arc progress ring with time labels and OT checkpoint markers.
///
/// - Blue arc: 0 → meal threshold
/// - Green arc: meal threshold → end of standard hours (100%)
/// - Orange outer ring appears once overtime begins (fills over [otCapMins])
/// - Meal marker dot glows green with ✓ when earned
/// - OT tick marks at 30, 60, [otCapMins] min to indicate 9h cap
/// - Time labels (entry / exit) drawn outside ring at arc endpoints
/// - Live progress dot at the arc's leading edge
///
/// [workedMins] is net worked time (already deducting pauses).
/// [stdMins] is the user's standard daily work minutes (profile-driven).
class ShiftRing extends StatelessWidget {
  final int workedMins;
  final double size;
  final Widget child;
  final double stdMins;
  final double mealThresholdMins;

  /// Text label drawn outside ring at the arc start (12 o'clock). Pass HH:MM.
  final String? entryTimeStr;

  /// Text label drawn outside ring near the progress tip. Pass HH:MM.
  final String? exitTimeStr;

  const ShiftRing({
    super.key,
    required this.workedMins,
    required this.child,
    this.size = 200,
    this.stdMins = AppConstants.stdDailyMinsRuolo + 0.0,
    this.mealThresholdMins = AppConstants.defaultMealVoucherThresholdMins + 0.0,
    this.entryTimeStr,
    this.exitTimeStr,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mealFrac = mealThresholdMins / stdMins;
    final pct = (workedMins / stdMins).clamp(0.0, 1.0);
    final mealEarned = workedMins >= mealThresholdMins;
    final isOT = workedMins > stdMins;
    final otMins = max(0, workedMins - stdMins.toInt()).toDouble();
    const otCapMins = 90.0;
    final otPct = (otMins / otCapMins).clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ShiftRingPainter(
              pct: pct,
              mealFrac: mealFrac,
              mealEarned: mealEarned,
              isOT: isOT,
              otPct: otPct,
              otCapMins: otCapMins,
              isDark: isDark,
              entryTimeStr: entryTimeStr,
              exitTimeStr: exitTimeStr,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _ShiftRingPainter extends CustomPainter {
  final double pct;
  final double mealFrac;
  final bool mealEarned;
  final bool isOT;
  final double otPct;
  final double otCapMins;
  final bool isDark;
  final String? entryTimeStr;
  final String? exitTimeStr;

  static const double _mS = 13.0;
  static const double _otS = 7.0;

  const _ShiftRingPainter({
    required this.pct,
    required this.mealFrac,
    required this.mealEarned,
    required this.isOT,
    required this.otPct,
    required this.otCapMins,
    required this.isDark,
    this.entryTimeStr,
    this.exitTimeStr,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);

    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.09)
        : Colors.black.withValues(alpha: 0.06);

    final mR = isOT
        ? (size.width - _mS - _otS * 2 - 6) / 2
        : (size.width - _mS) / 2;
    final otR = mR + _mS / 2 + _otS / 2 + 4;

    // ── Overtime outer ring ──────────────────────────────────────────────
    if (isOT) {
      canvas.drawCircle(
        center,
        otR,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = _otS,
      );
      if (otPct > 0) {
        final otRect = Rect.fromCircle(center: center, radius: otR);
        canvas.drawArc(
          otRect,
          -pi / 2,
          otPct * 2 * pi,
          false,
          Paint()
            ..color = AppColors.orange500
            ..style = PaintingStyle.stroke
            ..strokeWidth = _otS
            ..strokeCap = StrokeCap.round,
        );
      }

      // OT checkpoint ticks at 30, 60, 90 min (counter-clockwise from cap)
      final tickMins = [30.0, 60.0, otCapMins];
      for (final tm in tickMins) {
        final tickFrac = (tm / otCapMins).clamp(0.0, 1.0);
        final tickAngle = tickFrac * 2 * pi - pi / 2;
        final inner = Offset(
          cx + (otR - _otS / 2 - 1) * cos(tickAngle),
          cy + (otR - _otS / 2 - 1) * sin(tickAngle),
        );
        final outer = Offset(
          cx + (otR + _otS / 2 + 1) * cos(tickAngle),
          cy + (otR + _otS / 2 + 1) * sin(tickAngle),
        );
        final tickReached = otPct >= tickFrac;
        canvas.drawLine(
          inner,
          outer,
          Paint()
            ..color = tickReached
                ? Colors.white.withValues(alpha: 0.9)
                : AppColors.orange500.withValues(alpha: 0.45)
            ..strokeWidth = tm == otCapMins ? 2.5 : 1.5,
        );
      }
    }

    // ── Main ring track ──────────────────────────────────────────────────
    canvas.drawCircle(
      center,
      mR,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _mS,
    );

    final mainRect = Rect.fromCircle(center: center, radius: mR);

    // ── Blue arc (0 → mealFrac) ──────────────────────────────────────────
    final blueLen = min(pct, mealFrac);
    if (blueLen > 0.005) {
      canvas.drawArc(
        mainRect,
        -pi / 2,
        blueLen * 2 * pi,
        false,
        Paint()
          ..color = AppColors.blue600
          ..style = PaintingStyle.stroke
          ..strokeWidth = _mS
          ..strokeCap = StrokeCap.butt,
      );
    }

    // ── Green arc (mealFrac → pct, max 1.0) ─────────────────────────────
    final greenLen = max(0.0, min(pct, 1.0) - mealFrac);
    if (greenLen > 0.005) {
      canvas.drawArc(
        mainRect,
        -pi / 2 + mealFrac * 2 * pi,
        greenLen * 2 * pi,
        false,
        Paint()
          ..color = AppColors.green500
          ..style = PaintingStyle.stroke
          ..strokeWidth = _mS
          ..strokeCap = StrokeCap.butt,
      );
    }

    // ── Meal marker dot ──────────────────────────────────────────────────
    final mealAngle = mealFrac * 2 * pi - pi / 2;
    final mealDot = Offset(cx + mR * cos(mealAngle), cy + mR * sin(mealAngle));

    canvas.drawCircle(
      mealDot,
      7,
      Paint()
        ..color = mealEarned
            ? AppColors.green500
            : (isDark
                  ? const Color(0xFF3D3D5C)
                  : Colors.white.withValues(alpha: 0.9))
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      mealDot,
      7,
      Paint()
        ..color = isDark
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    if (mealEarned) {
      final tp = TextPainter(
        text: const TextSpan(
          text: '✓',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, mealDot - Offset(tp.width / 2, tp.height / 2));
    }

    // ── Live progress dot (only mid-progress) ───────────────────────────
    if (pct > 0.02 && pct < 0.99) {
      final progAngle = pct * 2 * pi - pi / 2;
      final progDot = Offset(
        cx + mR * cos(progAngle),
        cy + mR * sin(progAngle),
      );
      canvas.drawCircle(
        progDot,
        _mS / 2,
        Paint()
          ..color = pct > mealFrac ? AppColors.green500 : AppColors.blue600
          ..style = PaintingStyle.fill,
      );
    }

    // ── Time labels outside ring ─────────────────────────────────────────
    if (entryTimeStr != null || exitTimeStr != null) {
      final timeColor = isDark
          ? Colors.white.withValues(alpha: 0.55)
          : Colors.black.withValues(alpha: 0.45);
      final timeStyle = TextStyle(
        color: timeColor,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        height: 1.0,
      );
      final labelR = mR + _mS / 2 + 11;

      void drawLabel(String text, double angle) {
        final tp = TextPainter(
          text: TextSpan(text: text, style: timeStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        final dx = cx + labelR * cos(angle) - tp.width / 2;
        final dy = cy + labelR * sin(angle) - tp.height / 2;
        tp.paint(canvas, Offset(dx, dy));
      }

      // Entry: always at 12 o'clock (top, angle = -π/2)
      if (entryTimeStr != null) {
        drawLabel(entryTimeStr!, -pi / 2);
      }

      // Exit: at progress tip angle (or 100% if completed / pct ~= 1)
      if (exitTimeStr != null) {
        final exitAngle = (pct >= 0.98 ? 1.0 : pct) * 2 * pi - pi / 2;
        // Offset slightly to avoid overlap with entry label at top
        final shifted = exitAngle + (pct >= 0.95 ? 0.25 : 0.0);
        drawLabel(exitTimeStr!, shifted);
      }
    }
  }

  @override
  bool shouldRepaint(_ShiftRingPainter old) =>
      old.pct != pct ||
      old.mealFrac != mealFrac ||
      old.mealEarned != mealEarned ||
      old.isOT != isOT ||
      old.otPct != otPct ||
      old.isDark != isDark ||
      old.entryTimeStr != entryTimeStr ||
      old.exitTimeStr != exitTimeStr;
}
