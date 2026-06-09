import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/theme/color_schemes.dart';
import '../../core/constants/app_constants.dart';

const double _kStdMins = AppConstants.stdDailyMinsRuolo + 0.0;
const double _kMealMins = AppConstants.defaultMealVoucherThresholdMins + 0.0;
const double _kMealFrac = _kMealMins / _kStdMins; // ≈ 0.8333
const double _kOtCapMins = 90.0;

/// Dual-arc progress ring.
///
/// - Blue arc: 0 → meal threshold (83.3 %)
/// - Green arc: meal threshold → end of standard hours
/// - Orange outer ring appears once overtime begins (fills over 90 min)
/// - Meal marker dot glows green with ✓ when earned
/// - Live progress dot at the arc's leading edge
///
/// [workedMins] is net worked time (already deducting pauses).
class ShiftRing extends StatelessWidget {
  final int workedMins;
  final double size;
  final Widget child;

  const ShiftRing({
    super.key,
    required this.workedMins,
    required this.child,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = (workedMins / _kStdMins).clamp(0.0, 1.0);
    final mealEarned = workedMins >= _kMealMins;
    final isOT = workedMins > _kStdMins;
    final otMins = max(0, workedMins - _kStdMins.toInt()).toDouble();
    final otPct = (otMins / _kOtCapMins).clamp(0.0, 1.0);

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
              mealEarned: mealEarned,
              isOT: isOT,
              otPct: otPct,
              isDark: isDark,
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
  final bool mealEarned;
  final bool isOT;
  final double otPct;
  final bool isDark;

  static const double _mS = 13.0;
  static const double _otS = 7.0;

  const _ShiftRingPainter({
    required this.pct,
    required this.mealEarned,
    required this.isOT,
    required this.otPct,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);

    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.09)
        : Colors.black.withValues(alpha: 0.06);

    // Ring radius shrinks inward if OT ring is shown to leave room
    final mR = isOT
        ? (size.width - _mS - _otS * 2 - 6) / 2
        : (size.width - _mS) / 2;
    final otR = mR + _mS / 2 + _otS / 2 + 4;

    // ── Overtime outer ring ──────────────────────────────
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
    }

    // ── Main ring track ──────────────────────────────────
    canvas.drawCircle(
      center,
      mR,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _mS,
    );

    final mainRect = Rect.fromCircle(center: center, radius: mR);

    // ── Blue arc (0 → mealFrac) ──────────────────────────
    final blueLen = min(pct, _kMealFrac);
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

    // ── Green arc (mealFrac → pct, max 1.0) ─────────────
    final greenLen = max(0.0, min(pct, 1.0) - _kMealFrac);
    if (greenLen > 0.005) {
      canvas.drawArc(
        mainRect,
        -pi / 2 + _kMealFrac * 2 * pi,
        greenLen * 2 * pi,
        false,
        Paint()
          ..color = AppColors.green500
          ..style = PaintingStyle.stroke
          ..strokeWidth = _mS
          ..strokeCap = StrokeCap.butt,
      );
    }

    // ── Meal marker dot ──────────────────────────────────
    final mealAngle = _kMealFrac * 2 * pi - pi / 2;
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
            fontSize: 9,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, mealDot - Offset(tp.width / 2, tp.height / 2));
    }

    // ── Live progress dot (only mid-progress) ───────────
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
          ..color = pct > _kMealFrac ? AppColors.green500 : AppColors.blue600
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_ShiftRingPainter old) =>
      old.pct != pct ||
      old.mealEarned != mealEarned ||
      old.isOT != isOT ||
      old.otPct != otPct ||
      old.isDark != isDark;
}
