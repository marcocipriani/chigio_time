import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/color_schemes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../profile/data/profile_repository.dart';
import '../../social/data/social_repository.dart';
import '../../social/domain/colleague.dart';

class FavoriteColleaguesCard extends ConsumerWidget {
  const FavoriteColleaguesCard({super.key});

  static Color _avatarColor(String name) {
    const palette = [
      Color(0xFF7C4DFF),
      Color(0xFF00BCD4),
      Color(0xFFFF5722),
      Color(0xFF4CAF50),
      Color(0xFFFF9800),
      Color(0xFFE91E63),
      Color(0xFF009688),
      Color(0xFF795548),
      Color(0xFF607D8B),
      Color(0xFF3F51B5),
    ];
    if (name.isEmpty) return palette[0];
    return palette[name.codeUnitAt(0) % palette.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral600;

    final colleagues = ref.watch(colleaguesStreamProvider).asData?.value ?? [];
    final favorites = colleagues.where((c) => c.isFavorite).take(4).toList();

    if (favorites.isEmpty) return const SizedBox.shrink();

    return GlassTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 0, 10),
            child: Text(
              AppStrings.favoriteColleaguesUpper,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: textSub,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: favorites.map((c) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _FavoriteAvatar(
                  colleague: c,
                  color: _avatarColor(c.name),
                  isDark: isDark,
                  onTap: () => _showActions(context, ref, c),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showActions(BuildContext context, WidgetRef ref, ColleagueProfile c) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _ColleagueActionSheet(colleague: c, isDark: isDark, ref: ref),
    );
  }
}

// ── Avatar bubble ─────────────────────────────────────────────────────────────

class _FavoriteAvatar extends StatelessWidget {
  final ColleagueProfile colleague;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _FavoriteAvatar({
    required this.colleague,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral600;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
              border: Border.all(
                color: color.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                colleague.initials,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 52,
            child: Text(
              colleague.name.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: textSub),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action sheet ──────────────────────────────────────────────────────────────

class _ColleagueActionSheet extends StatefulWidget {
  final ColleagueProfile colleague;
  final bool isDark;
  final WidgetRef ref;

  const _ColleagueActionSheet({
    required this.colleague,
    required this.isDark,
    required this.ref,
  });

  @override
  State<_ColleagueActionSheet> createState() => _ColleagueActionSheetState();
}

class _ColleagueActionSheetState extends State<_ColleagueActionSheet> {
  bool _coffeeSent = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final c = widget.colleague;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral600;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF10102A).withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.82),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(24, 20, 24, bottomPad + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                c.name,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: textMain,
                ),
              ),
              if (c.sede != null && c.sede!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(c.sede!, style: TextStyle(fontSize: 12, color: textSub)),
              ],
              const SizedBox(height: 20),

              // Coffee button
              if (c.canReceiveCoffee) ...[
                _ActionTile(
                  icon: '☕',
                  label: _coffeeSent
                      ? AppStrings.coffeeSent
                      : AppStrings.sendCoffee,
                  isDark: isDark,
                  enabled: !_coffeeSent,
                  onTap: _coffeeSent
                      ? null
                      : () async {
                          final profileData = widget.ref
                              .read(userProfileStreamProvider)
                              .asData
                              ?.value;
                          final myName =
                              profileData?['name'] as String? ??
                              AppStrings.aColleague;
                          await widget.ref
                              .read(socialRepositoryProvider)
                              .sendCoffeeInvite(toUid: c.uid, fromName: myName);
                          if (mounted) setState(() => _coffeeSent = true);
                        },
                ),
                const SizedBox(height: 8),
              ],

              // Call button
              if (c.phoneNumber != null && c.phoneNumber!.isNotEmpty) ...[
                _ActionTile(
                  icon: '📞',
                  label: AppStrings.callPhoneNumber(c.phoneNumber!),
                  isDark: isDark,
                  onTap: () async {
                    final uri = Uri(scheme: 'tel', path: c.phoneNumber);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],

              // Internal extension
              if (c.interno != null && c.interno!.isNotEmpty) ...[
                _ActionTile(
                  icon: '☎️',
                  label: AppStrings.internalExtension(c.interno!),
                  isDark: isDark,
                  onTap: () async {
                    final uri = Uri(scheme: 'tel', path: c.interno);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String icon;
  final String label;
  final bool isDark;
  final bool enabled;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.isDark,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: enabled ? 0.9 : 0.4)
        : AppColors.neutral900.withValues(alpha: enabled ? 1.0 : 0.4);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
