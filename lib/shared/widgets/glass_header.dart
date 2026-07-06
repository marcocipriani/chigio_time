import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/color_schemes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/chigio_phrase_engine.dart';
import '../../features/dashboard/presentation/timer_provider.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/social/data/social_repository.dart';

class GlassHeader extends ConsumerStatefulWidget {
  final ChigioPage chigioPage;

  const GlassHeader({super.key, this.chigioPage = ChigioPage.dashboard});

  @override
  ConsumerState<GlassHeader> createState() => _GlassHeaderState();
}

class _GlassHeaderState extends ConsumerState<GlassHeader> {
  // Incremented on tap → forces a different phrase from the pool
  int _phraseOffset = 0;

  void _nextPhrase() => setState(() => _phraseOffset++);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final profileData = ref.watch(userProfileStreamProvider).asData?.value;
    final firebaseUser = FirebaseAuth.instance.currentUser;

    final displayName =
        (profileData?['name'] as String?)?.trim().isNotEmpty == true
        ? profileData!['name'] as String
        : (firebaseUser?.displayName ?? AppStrings.defaultUserName);
    final firstName = displayName.split(' ').first;

    final gender = (profileData?['gender'] as String?) ?? 'A';
    final department = (profileData?['dipartimento'] as String?) ?? '';
    final site = (profileData?['sede'] as String?) ?? '';
    final mealVoucherThresholdMins =
        profileData?['mealVoucherThresholdMins'] as int? ?? 380;
    final isPayDay = DateTime.now().day == 23;

    // Niente select: le frasi di Chigio consumano worked/remaining mins,
    // quindi l'header segue il tick del timer per necessità.
    final timerState = widget.chigioPage == ChigioPage.dashboard
        ? ref.watch(workTimerProvider)
        : null;
    final shiftState = _shiftStateFrom(timerState?.status);

    final now = DateTime.now();
    // Natural seed rotates every 5 min; offset bumped on each tap
    final seed = (now.hour * 12 + now.minute ~/ 5 + _phraseOffset);

    final chigioData = ChigioPhraseEngine.resolveContext(
      ChigioContext(
        page: widget.chigioPage,
        firstName: firstName,
        shiftState: shiftState,
        gender: gender,
        department: department,
        site: site,
        dayType: _dayTypeFrom(timerState),
        workedMins: _workedMinsFrom(timerState),
        remainingMins: timerState?.remainingTime?.inMinutes,
        standardWorkMins: timerState?.standardWorkMins,
        mealVoucherThresholdMins: mealVoucherThresholdMins,
        isPayDay: isPayDay,
        seed: seed,
        now: now,
      ),
    );

    final photoUrl = firebaseUser?.photoURL;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Left: Chigio avatar + phrase (tap to change) ──────────────
          Expanded(
            child: GestureDetector(
              onTap: _nextPhrase,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ChigioAvatar(data: chigioData, isDark: isDark),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status label chip — bold, accent-colored, theme-aware
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.blue400.withValues(alpha: 0.20)
                                : AppColors.blue600.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            chigioData.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.blue300
                                  : AppColors.blue700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Chigio phrase — readable contrast per theme
                        Text(
                          chigioData.phrase,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.72)
                                : AppColors.neutral800,
                            fontStyle: FontStyle.italic,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ── Right: bell + user avatar ─────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GlassCircleBtn(
                isDark: isDark,
                onTap: () => context.push('/notifications'),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      size: 20,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppColors.neutral600,
                    ),
                    if (ref.watch(hasUnreadProvider))
                      Positioned(
                        top: -1,
                        right: -1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.red700,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF10102A)
                                  : Colors.white,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.8),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0055A5).withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: photoUrl != null
                        ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _fallbackAvatar(firstName, isDark),
                          )
                        : _fallbackAvatar(firstName, isDark),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static ChigioShiftState _shiftStateFrom(WorkState? s) => switch (s) {
    WorkState.working => ChigioShiftState.working,
    WorkState.paused => ChigioShiftState.paused,
    WorkState.completed => ChigioShiftState.completed,
    WorkState.abandoned => ChigioShiftState.abandoned,
    _ => ChigioShiftState.notStarted,
  };

  static ChigioDayType _dayTypeFrom(TimerState? s) {
    if (s == null) return ChigioDayType.unknown;
    if (s.status == WorkState.working || s.status == WorkState.paused) {
      return ChigioDayType.presence;
    }
    if (s.status == WorkState.completed && s.lastCompletedShift != null) {
      return switch (s.lastCompletedShift!.workType) {
        'remote' => ChigioDayType.remote,
        'leave' => ChigioDayType.leave,
        'holiday' => ChigioDayType.holiday,
        'presence' || null => ChigioDayType.presence,
        _ => ChigioDayType.unknown,
      };
    }
    return ChigioDayType.unknown;
  }

  static int? _workedMinsFrom(TimerState? s) {
    if (s == null) return null;
    if (s.status == WorkState.completed && s.lastCompletedShift != null) {
      return s.lastCompletedShift!.netWorkedMins;
    }
    if (!s.isShiftActive || s.startTime == null) return null;

    final elapsed = s.currentTime.difference(s.startTime!).inMinutes;
    final ongoingPauseMins = s.currentPauseStart == null
        ? 0
        : s.currentTime.difference(s.currentPauseStart!).inMinutes;
    final worked =
        elapsed -
        s.totalStandardPauseMins -
        s.totalLeavePauseMins -
        s.totalLunchPauseMins -
        ongoingPauseMins;
    return worked < 0 ? 0 : worked;
  }

  Widget _fallbackAvatar(String name, bool isDark) {
    return Container(
      color: AppColors.blue600,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Chigio decorative avatar (non-interactive, pulse animation) ───────────────

class _ChigioAvatar extends StatefulWidget {
  final ChigioData data;
  final bool isDark;

  const _ChigioAvatar({required this.data, required this.isDark});

  @override
  State<_ChigioAvatar> createState() => _ChigioAvatarState();
}

class _ChigioAvatarState extends State<_ChigioAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Stesso stile dei widget Home (HomeWidgetHeader): riquadro arrotondato
    // con accent tinta, Chigio contenuto. Leggermente più grande delle card.
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.blue600.withValues(alpha: 0.10),
          border: Border.all(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.12)
                : AppColors.blue600.withValues(alpha: 0.18),
          ),
        ),
        child: Center(
          child: Image.asset(
            widget.data.image,
            width: 30,
            height: 30,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                const Text('🐢', style: TextStyle(fontSize: 24)),
          ),
        ),
      ),
    );
  }
}

class _GlassCircleBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isDark;

  const _GlassCircleBtn({
    required this.child,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? const Color(0xFF10102A).withValues(alpha: 0.58)
                  : Colors.white.withValues(alpha: 0.56),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.75),
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
