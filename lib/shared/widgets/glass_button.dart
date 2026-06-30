import 'package:flutter/material.dart';
import '../../app/theme/color_schemes.dart';
import 'app_tappable.dart';

enum GlassBtnVariant { primary, secondary }

class GlassBtn extends StatelessWidget {
  final String label;
  final Widget? icon;
  final VoidCallback? onPressed;
  final GlassBtnVariant variant;
  final bool fullWidth;
  final EdgeInsetsGeometry? padding;

  const GlassBtn({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = GlassBtnVariant.primary,
    this.fullWidth = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPrimary = variant == GlassBtnVariant.primary;

    final decoration = isPrimary
        ? BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xE60055A5), Color(0xF2003D8F)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0055A5).withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          )
        : BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          );

    final textColor = isPrimary
        ? AppColors.white
        : (isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.neutral800);

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (icon != null) ...[
          IconTheme(
            data: IconThemeData(color: textColor, size: 18),
            child: icon!,
          ),
          const SizedBox(width: 9),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    return AppTappable(
      onTap: onPressed,
      semanticLabel: label,
      pressedScale: 0.97,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        decoration: decoration,
        child: content,
      ),
    );
  }
}
