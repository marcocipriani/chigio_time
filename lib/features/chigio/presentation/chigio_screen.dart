import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_strings.dart';
import '../../../app/theme/color_schemes.dart';
import '../../../shared/widgets/app_tappable.dart';

class ChigioScreen extends StatefulWidget {
  const ChigioScreen({super.key});

  @override
  State<ChigioScreen> createState() => _ChigioScreenState();
}

class _ChigioScreenState extends State<ChigioScreen>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  static const _images = AppStrings.chigioImages;
  static const _labels = AppStrings.chigioLabels;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _bounceAnim = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.14,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.14,
          end: 0.92,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.92,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_bounceCtrl);
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _next() {
    _bounceCtrl.forward(from: 0.0);
    setState(() => _index = (_index + 1) % _images.length);
  }

  void _prev() {
    _bounceCtrl.forward(from: 0.0);
    setState(() => _index = (_index - 1 + _images.length) % _images.length);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.92)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral400;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  AppTappable(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppColors.neutral700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppStrings.chigio,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textMain,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    AppStrings.chigioCounter(_index + 1, _images.length),
                    style: TextStyle(fontSize: 12, color: textSub),
                  ),
                ],
              ),
            ),

            // ── Chigio image + label ───────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: _next,
                onHorizontalDragEnd: (d) {
                  if ((d.primaryVelocity ?? 0) < -200) _next();
                  if ((d.primaryVelocity ?? 0) > 200) _prev();
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _bounceAnim,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: ScaleTransition(
                            scale: anim.drive(
                              Tween(
                                begin: 0.88,
                                end: 1.0,
                              ).chain(CurveTween(curve: Curves.easeOut)),
                            ),
                            child: child,
                          ),
                        ),
                        child: Image.asset(
                          _images[_index],
                          key: ValueKey(_index),
                          height: 240,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.flutter_dash_rounded,
                            size: 160,
                            color: AppColors.blue600.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        _labels[_index],
                        key: ValueKey(_index),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textMain,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.tapToChange,
                      style: TextStyle(fontSize: 12, color: textSub),
                    ),
                  ],
                ),
              ),
            ),

            // ── Dot indicator ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_images.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: active
                          ? AppColors.blue600
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.25)
                                : AppColors.neutral300),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
