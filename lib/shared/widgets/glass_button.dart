import 'package:flutter/material.dart';
import '../../app/theme/color_schemes.dart';

enum GlassBtnVariant { primary, secondary }

class GlassBtn extends StatefulWidget {
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
  State<GlassBtn> createState() => _GlassBtnState();
}

class _GlassBtnState extends State<GlassBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPrimary = widget.variant == GlassBtnVariant.primary;

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
            boxShadow: _pressed
                ? []
                : [
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
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          IconTheme(
            data: IconThemeData(color: textColor, size: 18),
            child: widget.icon!,
          ),
          const SizedBox(width: 9),
        ],
        Flexible(
          child: Text(
            widget.label,
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

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: widget.fullWidth ? double.infinity : null,
          padding:
              widget.padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          decoration: decoration,
          child: content,
        ),
      ),
    );
  }
}
