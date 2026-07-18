import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/color_schemes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/notification_routing.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/skeleton_tile.dart';
import '../data/social_repository.dart';
import '../domain/app_notification.dart';
import '../../../shared/widgets/app_tappable.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(socialRepositoryProvider).markAllRead().ignore();
    });
  }

  Future<void> _respond(
    AppNotification n,
    String responseType,
    String? message, {
    int? etaMinutes,
  }) async {
    await ref
        .read(socialRepositoryProvider)
        .respondToInvite(
          n.id,
          responseType: responseType,
          message: message,
          etaMinutes: etaMinutes,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.92)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppColors.neutral600;

    final notifsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : AppColors.lightGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: Row(
                  children: [
                    AppTappable(
                      onTap: () => context.pop(),
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? const Color(
                                      0xFF10102A,
                                    ).withValues(alpha: 0.58)
                                  : Colors.white.withValues(alpha: 0.56),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.white.withValues(alpha: 0.75),
                              ),
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
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppStrings.notifications,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textMain,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: notifsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: SkeletonList(count: 4),
                  ),
                  error: (e, _) => ErrorRetry(
                    error: e,
                    onRetry: () => ref.invalidate(notificationsStreamProvider),
                  ),
                  data: (notifs) {
                    if (notifs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔔', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              AppStrings.noNotifications,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textMain,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppStrings.notificationsHint,
                              style: TextStyle(fontSize: 12, color: textSub),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: notifs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _NotifCard(
                        n: notifs[i],
                        onRespond: (n, rt, msg, {int? etaMinutes}) =>
                            _respond(n, rt, msg, etaMinutes: etaMinutes),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotifCard extends StatefulWidget {
  final AppNotification n;
  final Future<void> Function(
    AppNotification,
    String,
    String?, {
    int? etaMinutes,
  })
  onRespond;

  const _NotifCard({required this.n, required this.onRespond});

  @override
  State<_NotifCard> createState() => _NotifCardState();
}

class _NotifCardState extends State<_NotifCard> {
  bool _loading = false;
  final _msgCtrl = TextEditingController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _tap(String responseType, {int? etaMinutes}) async {
    setState(() => _loading = true);
    final msg = _msgCtrl.text.trim();
    await widget.onRespond(
      widget.n,
      responseType,
      msg.isEmpty ? null : msg,
      etaMinutes: etaMinutes,
    );
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _tapArriving() async {
    final eta = await _showEtaDialog();
    if (eta == null || !mounted) return;
    await _tap('arriving', etaMinutes: eta);
  }

  Future<int?> _showEtaDialog() {
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.etaQuestion),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [5, 10, 15]
              .map(
                (m) => AppTappable(
                  onTap: () => Navigator.pop(ctx, m),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blue600.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppStrings.etaMinutes(m),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue600,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return AppStrings.timeAgoNow;
    if (diff.inMinutes < 60) return AppStrings.timeAgoMins(diff.inMinutes);
    if (diff.inHours < 24) return AppStrings.timeAgoHours(diff.inHours);
    return AppStrings.timeAgoDays(diff.inDays);
  }

  // Response metadata
  static const _responseEmoji = {
    'accepted': '✅',
    'declined': '❌',
    'maybe': '🤔',
    'arriving': '🚶',
  };
  static const _responseLabel = {
    'accepted': AppStrings.respAccepted,
    'declined': AppStrings.respDeclined,
    'maybe': AppStrings.respMaybe,
    'arriving': AppStrings.respArriving,
  };
  static const _responseColor = {
    'accepted': AppColors.green600,
    'declined': AppColors.neutral400,
    'maybe': AppColors.orange500,
    'arriving': AppColors.blue600,
  };

  String _inviteTitle(AppNotification n) {
    if (n.type == 'colleague_added') {
      return AppStrings.notifColleagueAdded(n.fromName);
    }
    if (n.type == 'coffee_accepted') {
      final rt = n.responseType ?? 'accepted';
      return switch (rt) {
        'arriving' => AppStrings.notifArrivingEta(
          n.fromName,
          n.etaMinutes ?? '?',
        ),
        'declined' => AppStrings.notifDeclined(n.fromName),
        'maybe' => AppStrings.notifMaybe(n.fromName),
        _ => AppStrings.notifAccepted(n.fromName),
      };
    }
    if (n.scheduledAt != null) {
      return AppStrings.notifCoffeeScheduled(n.fromName, n.scheduledAt!);
    }
    return AppStrings.notifCoffeeInvite(n.fromName);
  }

  bool _isAutomatic(AppNotification n) => switch (n.type) {
    'exit_reminder' ||
    'morning_colleagues' ||
    'weekly_recap' ||
    'overtime_threshold' ||
    'payday' ||
    'test' => true,
    _ => n.title != null || n.body != null || n.route != null,
  };

  String _notificationTitle(AppNotification n) {
    final title = n.title?.trim();
    return title == null || title.isEmpty ? _inviteTitle(n) : title;
  }

  IconData _notificationIcon(String type) => switch (type) {
    'coffee_invite' || 'coffee_accepted' => Icons.local_cafe_outlined,
    'colleague_added' => Icons.person_add_alt_1_outlined,
    'exit_reminder' => Icons.schedule_outlined,
    'morning_colleagues' => Icons.groups_outlined,
    'weekly_recap' => Icons.assessment_outlined,
    'overtime_threshold' => Icons.trending_up_outlined,
    'payday' => Icons.payments_outlined,
    'test' => Icons.notifications_active_outlined,
    _ => Icons.notifications_none_outlined,
  };

  static const _visiblePushStatuses = {
    'sent',
    'suppressed',
    'no-token',
    'failed',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.92)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppColors.neutral600;
    final n = widget.n;
    final isAutomatic = _isAutomatic(n);

    final card = GlassCard(
      padding: const EdgeInsets.all(16),
      radius: 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.blue600,
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue600.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              _notificationIcon(n.type),
              size: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _notificationTitle(n),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textMain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeAgo(n.sentAt),
                      style: TextStyle(fontSize: 10, color: textSub),
                    ),
                  ],
                ),

                if (n.body?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 5),
                  Text(
                    n.body!.trim(),
                    style: TextStyle(fontSize: 12, color: textSub),
                  ),
                ],

                if (n.type == 'coffee_accepted' ||
                    n.type == 'coffee_invite' ||
                    (n.type == 'test' &&
                        _visiblePushStatuses.contains(n.pushStatus)))
                  const SizedBox(height: 10),

                // ── coffee_accepted: show response chip + message ──
                if (n.type == 'coffee_accepted') ...[
                  _ResponseChip(
                    responseType: n.responseType ?? 'accepted',
                    responseEmoji: _responseEmoji,
                    responseLabel: _responseLabel,
                    responseColor: _responseColor,
                    suffix: n.responseType == 'arriving' && n.etaMinutes != null
                        ? AppStrings.etaMinutesValue(n.etaMinutes!)
                        : null,
                  ),
                  if (n.message != null && n.message!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Text(
                        AppStrings.quotedMessage(n.message!),
                        style: TextStyle(
                          fontSize: 12,
                          color: textMain,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ]
                // ── coffee_invite pending: 3+1 buttons + optional msg ──
                else if (n.isPending && !_loading) ...[
                  _MessageField(
                    ctrl: _msgCtrl,
                    isDark: isDark,
                    textSub: textSub,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _RespBtn(
                        emoji: '✅',
                        label: AppStrings.respImThere,
                        color: AppColors.green600,
                        bgColor: AppColors.green500.withValues(alpha: 0.15),
                        onTap: () => _tap('accepted'),
                      ),
                      const SizedBox(width: 6),
                      _RespBtn(
                        emoji: '🤔',
                        label: AppStrings.respMaybeShort,
                        color: AppColors.orange500,
                        bgColor: AppColors.orange500.withValues(alpha: 0.13),
                        onTap: () => _tap('maybe'),
                      ),
                      const SizedBox(width: 6),
                      _RespBtn(
                        emoji: '❌',
                        label: AppStrings.respCannot,
                        color: textSub,
                        bgColor: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                        onTap: () => _tap('declined'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AppTappable(
                    onTap: _tapArriving,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.blue600.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🚶', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 6),
                          Text(
                            AppStrings.arriving,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.blue600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]
                // ── loading ──
                else if (n.type == 'coffee_invite' && _loading)
                  const SizedBox(
                    height: 32,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.blue600,
                        ),
                      ),
                    ),
                  )
                // ── coffee invite already responded ──
                else if (n.type == 'coffee_invite') ...[
                  _ResponseChip(
                    responseType: n.status,
                    responseEmoji: _responseEmoji,
                    responseLabel: _responseLabel,
                    responseColor: _responseColor,
                  ),
                ] else if (n.type == 'test' &&
                    _visiblePushStatuses.contains(n.pushStatus)) ...[
                  _PushStatusBadge(status: n.pushStatus!),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (!isAutomatic) return card;
    final route = notificationTapRoute({
      'type': n.type,
      'route': n.route,
    }, currentPath: GoRouterState.of(context).uri.path);
    if (route == null) return card;
    return AppTappable(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(20),
      child: card,
    );
  }
}

class _PushStatusBadge extends StatelessWidget {
  final String status;

  const _PushStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (status) {
      'sent' => (
        AppStrings.pushSent,
        Icons.check_circle_outline,
        AppColors.green600,
      ),
      'suppressed' => (
        AppStrings.pushSuppressed,
        Icons.notifications_off_outlined,
        AppColors.orange500,
      ),
      'no-token' => (
        AppStrings.pushNoDevice,
        Icons.phonelink_erase_outlined,
        AppColors.neutral400,
      ),
      _ => (AppStrings.pushFailed, Icons.error_outline, AppColors.red700),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared response chip ───────────────────────────────────────────────

class _ResponseChip extends StatelessWidget {
  final String responseType;
  final Map<String, String> responseEmoji;
  final Map<String, String> responseLabel;
  final Map<String, Color> responseColor;
  final String? suffix;

  const _ResponseChip({
    required this.responseType,
    required this.responseEmoji,
    required this.responseLabel,
    required this.responseColor,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final color = responseColor[responseType] ?? AppColors.neutral400;
    final emoji = responseEmoji[responseType] ?? '☕';
    final baseLabel = responseLabel[responseType] ?? responseType;
    final label = suffix != null ? '$baseLabel $suffix' : baseLabel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$emoji $label',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── Optional message text field ────────────────────────────────────────

class _MessageField extends StatelessWidget {
  final TextEditingController ctrl;
  final bool isDark;
  final Color textSub;

  const _MessageField({
    required this.ctrl,
    required this.isDark,
    required this.textSub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.7),
        ),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: 2,
        maxLength: 160,
        style: TextStyle(
          fontSize: 12,
          color: isDark
              ? Colors.white.withValues(alpha: 0.9)
              : AppColors.neutral900,
        ),
        decoration: InputDecoration(
          hintText: AppStrings.msgOptional,
          hintStyle: TextStyle(fontSize: 12, color: textSub),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          counterText: '',
        ),
      ),
    );
  }
}

// ── Response button ────────────────────────────────────────────────────

class _RespBtn extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _RespBtn({
    required this.emoji,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppTappable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
