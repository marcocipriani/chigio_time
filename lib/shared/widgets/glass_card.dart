import 'package:flutter/material.dart';

/// Full glass card — gc() equivalent from the design.
/// [radius] defaults to 28, [padding] defaults to 20.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? overrideColor;
  final BoxBorder? overrideBorder;
  final List<BoxShadow>? overrideShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.radius = 28,
    this.padding = const EdgeInsets.all(20),
    this.overrideColor,
    this.overrideBorder,
    this.overrideShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ponytail: niente BackdropFilter — le card stanno su sfondo statico,
    // il blur era costo raster puro (8+ saveLayer per schermata su web).
    // Alpha alzata per compensare la trasparenza persa.
    final bg =
        overrideColor ??
        (isDark
            ? const Color(0xFF10102A).withValues(alpha: 0.82)
            : Colors.white.withValues(alpha: 0.80));

    final border =
        overrideBorder ??
        Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.75),
        );

    final shadows =
        overrideShadow ??
        [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : const Color(0xFF002878).withValues(alpha: 0.10),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ];

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: shadows,
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Compact glass tile — gs() equivalent.  radius=20, padding=14.
class GlassTile extends StatelessWidget {
  final Widget child;
  final Color? overrideColor;
  final BoxBorder? overrideBorder;

  const GlassTile({
    super.key,
    required this.child,
    this.overrideColor,
    this.overrideBorder,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      overrideColor: overrideColor,
      overrideBorder: overrideBorder,
      child: child,
    );
  }
}
