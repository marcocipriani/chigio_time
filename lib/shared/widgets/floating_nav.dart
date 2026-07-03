import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/app_motion.dart';
import '../../app/theme/color_schemes.dart';
import '../../core/constants/app_strings.dart';

// Tab definitions ──────────────────────────────────────────────────────────

class _NavTab {
  final IconData icon;
  final String label;
  const _NavTab({required this.icon, required this.label});
}

const _tabs = [
  _NavTab(icon: Icons.home_rounded, label: AppStrings.navHome),
  _NavTab(icon: Icons.calendar_month_rounded, label: AppStrings.navTimesheet),
  _NavTab(icon: Icons.timer_rounded, label: AppStrings.navProjects),
  _NavTab(icon: Icons.group_rounded, label: AppStrings.navSocial),
  _NavTab(icon: Icons.payments_rounded, label: AppStrings.navSalary),
];

// Dimensions ───────────────────────────────────────────────────────────────

// Horizontal (mobile bottom pill)
// 64 px keeps a 5-tab pill within ~360 px-wide phones (5×64 = 320 + chrome).
const double _kTabW = 64.0;
const double _kTabH = 48.0;

// Vertical (desktop side rail)
const double _kVTabW = 60.0;
const double _kVTabH = 64.0;

// FloatingNav ──────────────────────────────────────────────────────────────

class FloatingNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isVertical;

  /// Branch indices (into [_tabs]) to display, in order. Defaults to all
  /// tabs. The caller must ensure [currentIndex] is included, otherwise the
  /// sliding highlight has no valid position to animate to.
  final List<int>? visibleIndices;

  const FloatingNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isVertical = false,
    this.visibleIndices,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isVertical
        ? _buildVertical(context, isDark)
        : _buildHorizontal(context, isDark);
  }

  // ── Bottom floating pill (mobile) ─────────────────────────────────────

  Widget _buildHorizontal(BuildContext context, bool isDark) {
    final indices = visibleIndices ?? List.generate(_tabs.length, (i) => i);
    final displayPos = indices
        .indexOf(currentIndex)
        .clamp(0, indices.length - 1);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        left: 12,
        right: 12,
      ),
      child: Center(
        child: _GlassPill(
          isDark: isDark,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: displayPos.toDouble()),
            duration: context.motion(300),
            curve: Curves.easeOutCubic,
            builder: (_, t, _) => SizedBox(
              width: _kTabW * indices.length,
              height: _kTabH,
              child: Stack(
                children: [
                  _SlidingPill(
                    offset: t * _kTabW,
                    width: _kTabW,
                    height: null,
                    isDark: isDark,
                  ),
                  Row(
                    children: List.generate(indices.length, (pos) {
                      final i = indices[pos];
                      return _PressableTab(
                        tab: _tabs[i],
                        active: currentIndex == i,
                        isVertical: false,
                        width: _kTabW,
                        height: _kTabH,
                        isDark: isDark,
                        onTap: () => onTap(i),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Side floating rail (desktop / wide) ──────────────────────────────

  Widget _buildVertical(BuildContext context, bool isDark) {
    final indices = visibleIndices ?? List.generate(_tabs.length, (i) => i);
    final displayPos = indices
        .indexOf(currentIndex)
        .clamp(0, indices.length - 1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: _GlassPill(
        isDark: isDark,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: displayPos.toDouble()),
          duration: context.motion(300),
          curve: Curves.easeOutCubic,
          builder: (_, t, _) => SizedBox(
            width: _kVTabW,
            height: _kVTabH * indices.length,
            child: Stack(
              children: [
                _SlidingPill(
                  offset: t * _kVTabH,
                  width: null,
                  height: _kVTabH,
                  isDark: isDark,
                  isVertical: true,
                ),
                Column(
                  children: List.generate(indices.length, (pos) {
                    final i = indices[pos];
                    return _PressableTab(
                      tab: _tabs[i],
                      active: currentIndex == i,
                      isVertical: true,
                      width: _kVTabW,
                      height: _kVTabH,
                      isDark: isDark,
                      onTap: () => onTap(i),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// _GlassPill — 3D glass container with gradient border ─────────────────────

class _GlassPill extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _GlassPill({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const radius = 40.0;
    const innerRadius = radius - 1.5;

    return Container(
      // 1.5 px gradient "border" via padding + gradient background
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.25 : 0.85),
            Colors.white.withValues(alpha: isDark ? 0.05 : 0.15),
          ],
        ),
        boxShadow: [
          // Drop shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.50 : 0.13),
            blurRadius: 32,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
          // Subtle upper rim highlight (3D glass edge)
          BoxShadow(
            color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.45),
            blurRadius: 0,
            offset: const Offset(0, -1),
            spreadRadius: 0,
          ),
          // Inner bottom shadow for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              // Subtle inner gradient for glass depth
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        const Color(0xFF12142E).withValues(alpha: 0.82),
                        const Color(0xFF0A0C20).withValues(alpha: 0.78),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.75),
                        Colors.white.withValues(alpha: 0.55),
                      ],
              ),
              borderRadius: BorderRadius.circular(innerRadius),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// _SlidingPill — animated highlight behind active tab ──────────────────────

class _SlidingPill extends StatelessWidget {
  final double offset;
  final double? width; // null in vertical mode (fills horizontal)
  final double? height; // null in horizontal mode (fills vertical)
  final bool isDark;
  final bool isVertical;

  const _SlidingPill({
    required this.offset,
    required this.width,
    required this.height,
    required this.isDark,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: isVertical ? 0 : offset,
      top: isVertical ? offset : 0,
      right: isVertical ? 0 : null,
      bottom: isVertical ? null : 0,
      width: isVertical ? null : width,
      height: isVertical ? height : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0.10),
                  ]
                : [
                    AppColors.blue600.withValues(alpha: 0.13),
                    AppColors.blue600.withValues(alpha: 0.07),
                  ],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue600.withValues(alpha: isDark ? 0.10 : 0.08),
              blurRadius: 10,
              spreadRadius: -2,
            ),
          ],
        ),
      ),
    );
  }
}

// _PressableTab — tab item with scale micro-interaction ────────────────────

class _PressableTab extends StatefulWidget {
  final _NavTab tab;
  final bool active;
  final bool isVertical;
  final double width;
  final double height;
  final bool isDark;
  final VoidCallback onTap;

  const _PressableTab({
    required this.tab,
    required this.active,
    required this.isVertical,
    required this.width,
    required this.height,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_PressableTab> createState() => _PressableTabState();
}

class _PressableTabState extends State<_PressableTab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final isDark = widget.isDark;
    final iconColor = active
        ? AppColors.blue600
        : (isDark ? Colors.white.withValues(alpha: 0.6) : AppColors.neutral600);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.84 : 1.0,
        duration: context.motion(110),
        curve: Curves.easeOutBack,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: context.motion(200),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  widget.tab.icon,
                  key: ValueKey(active),
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: context.motion(200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: iconColor,
                ),
                child: Text(widget.tab.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
