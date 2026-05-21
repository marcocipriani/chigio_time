import 'package:flutter/material.dart';
import '../../app/theme/color_schemes.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark ? AppColors.darkGradient : AppColors.lightGradient;

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          // Radial overlay — top-left blue tint
          Positioned(
            top: -80,
            left: -60,
            child: IgnorePointer(
              child: Container(
                width: 340,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      isDark
                          ? const Color(0xFF0055A5).withValues(alpha: 0.45)
                          : const Color(0xFF0055A5).withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Radial overlay — bottom-right teal tint
          Positioned(
            bottom: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      isDark
                          ? const Color(0xFF00796B).withValues(alpha: 0.35)
                          : const Color(0xFF00796B).withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
