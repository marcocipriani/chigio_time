import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/color_schemes.dart';
import '../../core/constants/app_strings.dart';
import '../../features/profile/data/profile_repository.dart';
import 'floating_nav.dart';

// Chiavi delle viste della shell, in ordine di branch index — usate per
// nascondere/mostrare schede dal nav (vedi profilo → 'hiddenNavViews').
const _navViewKeys = ['home', 'timesheet', 'social'];

List<int> _visibleNavIndices(
  Map<String, dynamic>? profileData,
  int currentIndex,
) {
  final hidden =
      (profileData?['hiddenNavViews'] as List?)?.cast<String>() ?? const [];
  final visible = [
    for (var i = 0; i < _navViewKeys.length; i++)
      if (!hidden.contains(_navViewKeys[i])) i,
  ];
  // Garantisce che la scheda attiva sia sempre presente (es. deep link a una
  // vista nascosta), altrimenti l'highlight animato non avrebbe una posizione.
  if (!visible.contains(currentIndex)) {
    visible.add(currentIndex);
    visible.sort();
  }
  return visible;
}

class MainShellScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({super.key, required this.navigationShell});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      value: 1.0,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _switchBranch(int i) {
    final shell = widget.navigationShell;
    if (i == shell.currentIndex) {
      shell.goBranch(i, initialLocation: true);
      return;
    }
    _fadeCtrl.stop();
    _fadeCtrl.reverse().then((_) {
      if (!mounted) return;
      shell.goBranch(i, initialLocation: false);
      _fadeCtrl.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      isDark
          ? const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarBrightness: Brightness.dark,
              statusBarIconBrightness: Brightness.light,
            )
          : const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarBrightness: Brightness.light,
              statusBarIconBrightness: Brightness.dark,
            ),
    );

    final isWide = MediaQuery.sizeOf(context).width >= 600;
    return isWide ? _buildWide(isDark) : _buildMobile(context);
  }

  // ── Mobile: full-width + bottom floating pill ─────────────────────────

  Widget _buildMobile(BuildContext context) {
    const kNavClearance = 88.0;
    final sysPadBottom = MediaQuery.of(context).padding.bottom;
    final currentIndex = widget.navigationShell.currentIndex;
    final profileData = ref.watch(userProfileStreamProvider).value;
    final visibleIndices = _visibleNavIndices(profileData, currentIndex);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: MediaQuery.of(
                  context,
                ).padding.copyWith(bottom: sysPadBottom + kNavClearance),
              ),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: widget.navigationShell,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingNav(
              currentIndex: currentIndex,
              onTap: _switchBranch,
              visibleIndices: visibleIndices,
            ),
          ),
        ],
      ),
    );
  }

  // ── Wide (tablet/desktop): full-width content + nav pill in header bar ─

  Widget _buildWide(bool isDark) {
    final currentIndex = widget.navigationShell.currentIndex;
    final profileData = ref.watch(userProfileStreamProvider).value;
    final visibleIndices = _visibleNavIndices(profileData, currentIndex);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Full-width content — each screen renders its own GlassHeader
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: widget.navigationShell,
            ),
          ),
          // Compact nav pill overlaid at top-center, within GlassHeader's zone
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _HeaderNavPill(
                  currentIndex: currentIndex,
                  onTap: _switchBranch,
                  isDark: isDark,
                  visibleIndices: visibleIndices,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Compact nav pill for desktop header ────────────────────────────────────
// Fits in the empty center of GlassHeader (greeting left, avatar right).

class _HeaderNavPill extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;
  final List<int> visibleIndices;

  const _HeaderNavPill({
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
    required this.visibleIndices,
  });

  static const _items = [
    (icon: Icons.home_rounded, label: AppStrings.navHome),
    (icon: Icons.calendar_month_rounded, label: AppStrings.navTimesheet),
    (icon: Icons.group_rounded, label: AppStrings.navSocial),
  ];

  static const double _kW = 68.0;
  static const double _kH = 34.0;

  @override
  Widget build(BuildContext context) {
    final isDark = this.isDark;

    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.25 : 0.85),
            Colors.white.withValues(alpha: isDark ? 0.05 : 0.15),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: -3,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.40),
            blurRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(38.5),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        const Color(0xFF12142E).withValues(alpha: 0.80),
                        const Color(0xFF0A0C20).withValues(alpha: 0.76),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.72),
                        Colors.white.withValues(alpha: 0.52),
                      ],
              ),
              borderRadius: BorderRadius.circular(38.5),
            ),
            child: Builder(
              builder: (_) {
                final displayPos = visibleIndices
                    .indexOf(currentIndex)
                    .clamp(0, visibleIndices.length - 1);
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: displayPos.toDouble()),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (_, t, _) => SizedBox(
                    width: _kW * visibleIndices.length,
                    height: _kH,
                    child: Stack(
                      children: [
                        Positioned(
                          left: t * _kW,
                          top: 0,
                          bottom: 0,
                          width: _kW,
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
                                        AppColors.blue600.withValues(
                                          alpha: 0.13,
                                        ),
                                        AppColors.blue600.withValues(
                                          alpha: 0.07,
                                        ),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        Row(
                          children: visibleIndices.map((i) {
                            final tab = _items[i];
                            final active = currentIndex == i;
                            final color = active
                                ? AppColors.blue600
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.40)
                                      : AppColors.neutral400);
                            return GestureDetector(
                              onTap: () => onTap(i),
                              behavior: HitTestBehavior.opaque,
                              child: SizedBox(
                                width: _kW,
                                height: _kH,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(tab.icon, size: 16, color: color),
                                    const SizedBox(height: 2),
                                    Text(
                                      tab.label,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: active
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
