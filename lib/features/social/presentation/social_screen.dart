import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/chigio_phrase_engine.dart';
import '../../../app/theme/color_schemes.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_header.dart';
import '../../profile/data/profile_repository.dart';
import '../data/social_repository.dart';
import '../domain/colleague.dart';
import '../domain/colleague_group.dart';
import '../../../core/constants/app_strings.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen> {
  final Set<String> _coffeesSent = {};
  String? _toastName;

  // ── Active filters ────────────────────────────────────────────────────
  String? _filterSede;
  String? _filterDip;
  String? _filterStatus;

  static const _statusLabel = {
    'working': 'In ufficio',
    'paused': 'In pausa',
    'remote': 'Da remoto',
    'completed': 'Uscito',
    'notStarted': 'Non in ufficio',
  };
  static const _statusIcon = {
    'working': '🏢',
    'paused': '☕',
    'remote': '🏠',
    'completed': '🌙',
    'notStarted': '—',
  };
  static const _statusColor = {
    'working': AppColors.green600,
    'paused': AppColors.orange500,
    'remote': AppColors.blue600,
    'completed': AppColors.neutral400,
    'notStarted': AppColors.neutral400,
  };

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
      Color(0xFFFF6F00),
      Color(0xFF00897B),
    ];
    if (name.isEmpty) return palette[0];
    return palette[name.codeUnitAt(0) % palette.length];
  }

  Future<void> _sendCoffee(ColleagueProfile c, {String? scheduledAt}) async {
    final profileData = ref.read(userProfileStreamProvider).asData?.value;
    final myName = profileData?['name'] as String? ?? 'Un collega';
    await ref
        .read(socialRepositoryProvider)
        .sendCoffeeInvite(
          toUid: c.uid,
          fromName: myName,
          scheduledAt: scheduledAt,
        );
    if (!mounted) return;
    setState(() {
      _coffeesSent.add(c.uid);
      _toastName = c.name.split(' ').first;
    });
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _toastName = null);
    });
  }

  Future<void> _showCoffeeOptions(ColleagueProfile c) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CoffeeScheduleSheet(isDark: isDark),
    );
    if (result == null || !mounted) return;
    await _sendCoffee(c, scheduledAt: result.isEmpty ? null : result);
  }

  Future<void> _toggleFavorite(ColleagueProfile c) async {
    await ref
        .read(socialRepositoryProvider)
        .setFavorite(c.uid, isFavorite: !c.isFavorite);
  }

  void _openGroupsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GroupsMobileSheet(isDark: isDark),
    );
  }

  Future<void> _remove(ColleagueProfile c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _RemoveDialog(name: c.name),
    );
    if (confirmed == true) {
      await ref.read(socialRepositoryProvider).removeColleague(c.uid);
    }
  }

  void _openAddSheet(List<ColleagueProfile> current) {
    final profileData = ref.read(userProfileStreamProvider).asData?.value;
    final admin = profileData?['administration'] as String? ?? '';
    final existing = current.map((c) => c.uid).toSet();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddColleagueSheet(
        administration: admin,
        existingUids: existing,
        onAdd: (uid) => ref.read(socialRepositoryProvider).addColleague(uid),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : AppColors.neutral400;

    final profileData = ref.watch(userProfileStreamProvider).asData?.value;
    final myAvailable = profileData?['coffeeAvailable'] as bool? ?? false;
    final stats = ref.watch(coffeeStatsProvider);

    final colleaguesAsync = ref.watch(colleaguesStreamProvider);
    final allColleagues = colleaguesAsync.asData?.value ?? [];

    // ── Filter options (unique non-null values from current list) ────────
    final sedeOptions =
        allColleagues
            .map((c) => c.sede)
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final dipOptions =
        allColleagues
            .map((c) => c.dipartimento)
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    const statusOptions = [
      'working',
      'paused',
      'remote',
      'completed',
      'notStarted',
    ];

    // Reset stale filter values when colleagues list changes.
    if (_filterSede != null && !sedeOptions.contains(_filterSede)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _filterSede = null);
      });
    }
    if (_filterDip != null && !dipOptions.contains(_filterDip)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _filterDip = null);
      });
    }

    // ── Apply filters ─────────────────────────────────────────────────────
    Iterable<ColleagueProfile> filtered = allColleagues;
    if (_filterSede != null) {
      filtered = filtered.where((c) => c.sede == _filterSede);
    }
    if (_filterDip != null) {
      filtered = filtered.where((c) => c.dipartimento == _filterDip);
    }
    if (_filterStatus != null) {
      filtered = filtered.where((c) => c.effectiveStatus == _filterStatus);
    }
    final colleagues = filtered.toList();
    final favorites = colleagues.where((c) => c.isFavorite).toList();
    final others = colleagues.where((c) => !c.isFavorite).toList();

    final working = allColleagues
        .where((c) => c.effectiveStatus == 'working')
        .toList();
    final remote = allColleagues
        .where((c) => c.effectiveStatus == 'remote')
        .length;
    final paused = allColleagues
        .where((c) => c.effectiveStatus == 'paused')
        .length;

    final isDesktop = MediaQuery.sizeOf(context).width >= 800.0;

    // ── Colleagues list (shared mobile/desktop) ───────────────────────
    Widget colleaguesList = RefreshIndicator(
      onRefresh: () {
        ref.invalidate(colleaguesStreamProvider);
        return Future.delayed(const Duration(milliseconds: 600));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          if (!isDesktop) ...[
            _SocialQuickBar(
              isDark: isDark,
              myAvailable: myAvailable,
              onGroupsTap: _openGroupsSheet,
              onCoffeeToggle: (v) =>
                  ref.read(socialRepositoryProvider).setCoffeeAvailable(v),
            ),
            const SizedBox(height: 10),
          ] else ...[
            _CoffeeToggleCard(
              isDark: isDark,
              myAvailable: myAvailable,
              stats: stats,
              onToggle: (v) =>
                  ref.read(socialRepositoryProvider).setCoffeeAvailable(v),
            ),
            const SizedBox(height: 12),
          ],
          if (allColleagues.isNotEmpty)
            _SummaryCard(
              working: working,
              remoteCount: remote,
              pausedCount: paused,
              avatarColor: _avatarColor,
            ),
          if (allColleagues.isNotEmpty) const SizedBox(height: 12),

          // ── Filter chips ─────────────────────────────────────────────
          if (allColleagues.isNotEmpty) ...[
            _ColleagueFilterBar(
              isDark: isDark,
              sedeOptions: sedeOptions,
              dipOptions: dipOptions,
              statusOptions: statusOptions,
              filterSede: _filterSede,
              filterDip: _filterDip,
              filterStatus: _filterStatus,
              statusLabel: _statusLabel,
              onSedeChanged: (v) => setState(() => _filterSede = v),
              onDipChanged: (v) => setState(() => _filterDip = v),
              onStatusChanged: (v) => setState(() => _filterStatus = v),
            ),
            const SizedBox(height: 12),
          ],

          if (favorites.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                AppStrings.favorites,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textSub,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...favorites.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ColleagueCard(
                  colleague: c,
                  avatarColor: _avatarColor(c.name),
                  coffeeSent: _coffeesSent.contains(c.uid),
                  isDark: isDark,
                  statusLabel: _statusLabel[c.effectiveStatus] ?? '',
                  statusIcon: _statusIcon[c.effectiveStatus] ?? '',
                  statusColor:
                      _statusColor[c.effectiveStatus] ?? AppColors.neutral400,
                  onCoffee:
                      (!c.showCoffeeButton || _coffeesSent.contains(c.uid))
                      ? null
                      : () => _showCoffeeOptions(c),
                  onToggleFavorite: () => _toggleFavorite(c),
                  onRemove: () => _remove(c),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (others.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                favorites.isEmpty
                    ? AppStrings.colleagues
                    : AppStrings.allColleagues,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textSub,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...others.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ColleagueCard(
                  colleague: c,
                  avatarColor: _avatarColor(c.name),
                  coffeeSent: _coffeesSent.contains(c.uid),
                  isDark: isDark,
                  statusLabel: _statusLabel[c.effectiveStatus] ?? '',
                  statusIcon: _statusIcon[c.effectiveStatus] ?? '',
                  statusColor:
                      _statusColor[c.effectiveStatus] ?? AppColors.neutral400,
                  onCoffee:
                      (!c.showCoffeeButton || _coffeesSent.contains(c.uid))
                      ? null
                      : () => _showCoffeeOptions(c),
                  onToggleFavorite: () => _toggleFavorite(c),
                  onRemove: () => _remove(c),
                ),
              ),
            ),
          ],
          if (colleaguesAsync.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (colleagues.isEmpty)
            _EmptyState(isDark: isDark, onAdd: () => _openAddSheet([])),
          if (colleaguesAsync.hasError)
            Center(
              child: Text(
                AppStrings.errorLoading,
                style: TextStyle(color: textSub),
              ),
            ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const GlassHeader(chigioPage: ChigioPage.social),
                Expanded(
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: groups panel
                            SizedBox(
                              width: 240,
                              child: _GroupsPanel(isDark: isDark),
                            ),
                            // Right: colleagues list
                            Expanded(child: colleaguesList),
                          ],
                        )
                      : colleaguesList,
                ),
              ],
            ),

            // ── Add FAB ────────────────────────────────────────
            if (!colleaguesAsync.isLoading)
              Positioned(
                bottom: 90,
                right: 16,
                child: GestureDetector(
                  onTap: () => _openAddSheet(colleagues),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xE60055A5), Color(0xF2003D8F)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0055A5).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),

            // ── Coffee toast ────────────────────────────────────
            if (_toastName != null)
              Positioned(
                bottom: 90,
                left: 0,
                right: 0,
                child: Center(
                  child: GlassCard(
                    radius: 20,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 11,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('☕', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Text(
                          AppStrings.coffeeToastSent(_toastName!),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.9)
                                : AppColors.neutral900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Desktop groups panel ──────────────────────────────────────────────

class _GroupsPanel extends ConsumerStatefulWidget {
  final bool isDark;
  const _GroupsPanel({required this.isDark});

  @override
  ConsumerState<_GroupsPanel> createState() => _GroupsPanelState();
}

class _GroupsPanelState extends ConsumerState<_GroupsPanel> {
  String? _selectedGroupId; // null = show all colleagues

  Future<void> _createGroup() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(AppStrings.newGroup),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(hintText: AppStrings.groupName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, ctrl.text.trim()),
            child: const Text(AppStrings.create),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(socialRepositoryProvider).createGroup(name);
    }
  }

  Future<void> _sendGroupCoffee(ColleagueGroup group) async {
    final profileData = ref.read(userProfileStreamProvider).asData?.value;
    final myName = profileData?['name'] as String? ?? 'Un collega';
    await ref
        .read(socialRepositoryProvider)
        .sendGroupCoffee(group.id, fromName: myName);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.coffeeGroupSent(group.name))),
    );
  }

  Future<void> _deleteGroup(ColleagueGroup group) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(AppStrings.deleteGroupConfirm(group.name)),
        content: Text(AppStrings.deleteGroupBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text(
              AppStrings.delete,
              style: TextStyle(color: AppColors.red700),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      if (_selectedGroupId == group.id) {
        setState(() => _selectedGroupId = null);
      }
      await ref.read(socialRepositoryProvider).deleteGroup(group.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.38)
        : AppColors.neutral400;

    final groupsAsync = ref.watch(groupsStreamProvider);
    final groups = groupsAsync.asData?.value ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              Text(
                AppStrings.groups,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textSub,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _createGroup,
                child: Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : AppColors.neutral600,
                ),
              ),
            ],
          ),
        ),

        // "Tutti" entry
        _GroupTile(
          label: 'Tutti i colleghi',
          memberCount: null,
          selected: _selectedGroupId == null,
          isDark: isDark,
          textMain: textMain,
          onTap: () => setState(() => _selectedGroupId = null),
          onDelete: null,
        ),

        // Group list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
            itemCount: groups.length,
            itemBuilder: (_, i) {
              final g = groups[i];
              final colleagues =
                  ref.watch(colleaguesStreamProvider).asData?.value ?? [];
              final inOffice = colleagues
                  .where(
                    (c) => g.memberUids.contains(c.uid) && c.canReceiveCoffee,
                  )
                  .length;
              return _GroupTile(
                label: g.name,
                memberCount: g.memberUids.length,
                inOfficeCount: inOffice,
                selected: _selectedGroupId == g.id,
                isDark: isDark,
                textMain: textMain,
                onTap: () => setState(() => _selectedGroupId = g.id),
                onDelete: () => _deleteGroup(g),
                onCoffee: g.memberUids.isEmpty
                    ? null
                    : () => _sendGroupCoffee(g),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GroupTile extends StatelessWidget {
  final String label;
  final int? memberCount;
  final int inOfficeCount;
  final bool selected;
  final bool isDark;
  final Color textMain;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onCoffee;

  const _GroupTile({
    required this.label,
    required this.memberCount,
    this.inOfficeCount = 0,
    required this.selected,
    required this.isDark,
    required this.textMain,
    required this.onTap,
    required this.onDelete,
    this.onCoffee,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.fromLTRB(16, 2, 8, 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.blue600.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.blue600.withValues(alpha: 0.35)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.blue600 : textMain,
                ),
              ),
            ),
            if (memberCount != null) ...[
              Text(
                inOfficeCount > 0
                    ? '$inOfficeCount/$memberCount 🏢'
                    : '$memberCount',
                style: TextStyle(
                  fontSize: 11,
                  color: inOfficeCount > 0
                      ? AppColors.green500
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.35)
                            : AppColors.neutral400),
                ),
              ),
              if (onCoffee != null) const SizedBox(width: 6),
            ],
            if (onCoffee != null)
              GestureDetector(
                onTap: onCoffee,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.orange500.withValues(alpha: 0.15),
                  ),
                  child: const Center(
                    child: Text('☕', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final List<ColleagueProfile> working;
  final int remoteCount;
  final int pausedCount;
  final Color Function(String) avatarColor;

  const _SummaryCard({
    required this.working,
    required this.remoteCount,
    required this.pausedCount,
    required this.avatarColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      overrideColor: isDark
          ? const Color(0xFF0055A5).withValues(alpha: 0.50)
          : const Color(0xFF0055A5).withValues(alpha: 0.82),
      overrideBorder: const Border.fromBorderSide(BorderSide.none),
      overrideShadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.presentToday,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xA6FFFFFF),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          // Stacked avatars of working colleagues
          if (working.isNotEmpty)
            SizedBox(
              height: 38,
              child: Stack(
                children: [
                  ...working
                      .take(5)
                      .toList()
                      .asMap()
                      .entries
                      .map(
                        (e) => Positioned(
                          left: e.key * 26.0,
                          child: _SocialAvatar(
                            initials: e.value.initials,
                            color: avatarColor(e.value.name),
                            size: 38,
                          ),
                        ),
                      ),
                  if (working.length > 5)
                    Positioned(
                      left: 5 * 26.0,
                      child: _SocialAvatar(
                        initials: '+${working.length - 5}',
                        color: Colors.white.withValues(alpha: 0.2),
                        size: 38,
                        textColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 10),
          Text(
            '${working.length} in ufficio',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _PresenceCount(
                icon: '🏢',
                count: working.length,
                label: 'In ufficio',
              ),
              const SizedBox(width: 16),
              _PresenceCount(
                icon: '🏠',
                count: remoteCount,
                label: 'Da remoto',
              ),
              const SizedBox(width: 16),
              _PresenceCount(icon: '☕', count: pausedCount, label: 'In pausa'),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Colleague card ────────────────────────────────────────────────────

class _ColleagueCard extends StatelessWidget {
  final ColleagueProfile colleague;
  final Color avatarColor;
  final bool coffeeSent;
  final bool isDark;
  final String statusLabel;
  final String statusIcon;
  final Color statusColor;
  final VoidCallback? onCoffee;
  final VoidCallback onToggleFavorite;
  final VoidCallback onRemove;

  const _ColleagueCard({
    required this.colleague,
    required this.avatarColor,
    required this.coffeeSent,
    required this.isDark,
    required this.statusLabel,
    required this.statusIcon,
    required this.statusColor,
    required this.onCoffee,
    required this.onToggleFavorite,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : AppColors.neutral400;

    return GestureDetector(
      onLongPress: onRemove,
      child: GlassTile(
        child: Row(
          children: [
            _SocialAvatar(
              initials: colleague.initials,
              color: avatarColor,
              size: 46,
              shadow: true,
            ),
            const SizedBox(width: 12),

            // Name + interno · sede · piano · stanza
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    colleague.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textMain,
                    ),
                  ),
                  Builder(
                    builder: (_) {
                      final parts = <String>[
                        if (colleague.interno != null &&
                            colleague.interno!.isNotEmpty)
                          'Int. ${colleague.interno}',
                        if (colleague.sede != null &&
                            colleague.sede!.isNotEmpty)
                          colleague.sede!,
                      ];
                      if (parts.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 10,
                              color: textSub,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                parts.join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 10, color: textSub),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Builder(
                    builder: (_) {
                      final parts = <String>[
                        if (colleague.piano != null &&
                            colleague.piano!.isNotEmpty)
                          'Piano ${colleague.piano}',
                        if (colleague.stanza != null &&
                            colleague.stanza!.isNotEmpty)
                          'St. ${colleague.stanza}',
                      ];
                      if (parts.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 10,
                              color: textSub,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                parts.join(' · '),
                                style: TextStyle(fontSize: 10, color: textSub),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Call button
                Builder(
                  builder: (_) {
                    final tel = (colleague.phoneNumber?.isNotEmpty ?? false)
                        ? colleague.phoneNumber!
                        : (colleague.interno?.isNotEmpty ?? false)
                        ? colleague.interno!
                        : null;
                    if (tel == null) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: () => launchUrl(Uri(scheme: 'tel', path: tel)),
                      child: Container(
                        width: 34,
                        height: 34,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.04),
                        ),
                        child: const Icon(
                          Icons.phone_outlined,
                          size: 16,
                          color: AppColors.green600,
                        ),
                      ),
                    );
                  },
                ),
                // Coffee button
                if (onCoffee != null || coffeeSent)
                  GestureDetector(
                    onTap: coffeeSent ? null : onCoffee,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 34,
                      height: 34,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: coffeeSent
                            ? AppColors.green500.withValues(alpha: 0.2)
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.05)),
                        boxShadow: coffeeSent
                            ? [
                                BoxShadow(
                                  color: AppColors.green500.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          coffeeSent ? '✅' : '☕',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),

                // Favorite star
                GestureDetector(
                  onTap: onToggleFavorite,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 34,
                    height: 34,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colleague.isFavorite
                          ? AppColors.orange500.withValues(alpha: 0.15)
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.04)),
                    ),
                    child: Center(
                      child: Icon(
                        colleague.isFavorite
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 18,
                        color: colleague.isFavorite
                            ? AppColors.orange500
                            : textSub,
                      ),
                    ),
                  ),
                ),

                // Status badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (statusIcon != '—') ...[
                            Text(
                              statusIcon,
                              style: const TextStyle(fontSize: 10),
                            ),
                            const SizedBox(width: 3),
                          ],
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add colleague bottom sheet ─────────────────────────────────────────

class _AddColleagueSheet extends ConsumerStatefulWidget {
  final String administration;
  final Set<String> existingUids;
  final Future<void> Function(String uid) onAdd;

  const _AddColleagueSheet({
    required this.administration,
    required this.existingUids,
    required this.onAdd,
  });

  @override
  ConsumerState<_AddColleagueSheet> createState() => _AddColleagueSheetState();
}

class _AddColleagueSheetState extends ConsumerState<_AddColleagueSheet> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  final Set<String> _adding = {};
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final users = await ref
        .read(socialRepositoryProvider)
        .getUsersInAdministration(widget.administration, widget.existingUids);
    if (mounted)
      setState(() {
        _users = users;
        _filtered = users;
        _loading = false;
      });
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _users
          : _users
                .where(
                  (u) => (u['name'] as String? ?? '').toLowerCase().contains(q),
                )
                .toList();
    });
  }

  Future<void> _add(Map<String, dynamic> user) async {
    final uid = user['uid'] as String;
    setState(() => _adding.add(uid));
    await widget.onAdd(uid);
    if (mounted) {
      setState(() {
        _adding.remove(uid);
        _users.removeWhere((u) => u['uid'] == uid);
        _filter();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : AppColors.neutral400;

    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          padding: EdgeInsets.only(bottom: bottomPad),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF10102A).withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Text(
                      AppStrings.addColleagues,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: textMain,
                      ),
                    ),
                    const Spacer(),
                    if (widget.administration.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blue600.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.administration,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blue600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Search field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: TextStyle(fontSize: 14, color: textMain),
                    decoration: InputDecoration(
                      hintText: AppStrings.searchByName,
                      hintStyle: TextStyle(fontSize: 14, color: textSub),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: textSub,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              // List
              Flexible(
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          _users.isEmpty
                              ? AppStrings.noOtherUsers
                              : 'Nessun risultato.',
                          style: TextStyle(fontSize: 13, color: textSub),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final u = _filtered[i];
                          final uid = u['uid'] as String;
                          final name = u['name'] as String? ?? '—';
                          final role = u['employmentType'] as String? ?? '';
                          final isAdding = _adding.contains(uid);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GlassTile(
                              child: Row(
                                children: [
                                  _SocialAvatar(
                                    initials: _initials(name),
                                    color: _colorFromName(name),
                                    size: 40,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: textMain,
                                          ),
                                        ),
                                        if (role.isNotEmpty)
                                          Text(
                                            role,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: textSub,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  isAdding
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.blue600,
                                          ),
                                        )
                                      : GestureDetector(
                                          onTap: () => _add(u),
                                          child: Container(
                                            width: 30,
                                            height: 30,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: [
                                                  Color(0xE60055A5),
                                                  Color(0xF2003D8F),
                                                ],
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.add_rounded,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                ],
                              ),
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

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  static Color _colorFromName(String name) {
    const palette = [
      Color(0xFF7C4DFF),
      Color(0xFF00BCD4),
      Color(0xFFFF5722),
      Color(0xFF4CAF50),
      Color(0xFFFF9800),
      Color(0xFFE91E63),
      Color(0xFF009688),
      Color(0xFF795548),
    ];
    if (name.isEmpty) return palette[0];
    return palette[name.codeUnitAt(0) % palette.length];
  }
}

// ── Remove confirmation dialog ─────────────────────────────────────────

class _RemoveDialog extends StatelessWidget {
  final String name;
  const _RemoveDialog({required this.name});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.removeColleague),
      content: Text(AppStrings.removeColleagueConfirm(name.split(' ').first)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(AppStrings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.red700),
          child: const Text(AppStrings.remove),
        ),
      ],
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAdd;

  const _EmptyState({required this.isDark, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : AppColors.neutral400;

    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          const Text('👥', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            AppStrings.noColleaguesYet,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.8)
                  : AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Aggiungi i tuoi colleghi della stessa\namministrazione con il tasto +',
            style: TextStyle(fontSize: 12, color: textSub),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xE60055A5), Color(0xF2003D8F)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_add_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.addColleague,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────

class _SocialAvatar extends StatelessWidget {
  final String initials;
  final Color color;
  final double size;
  final Color? textColor;
  final bool shadow;

  const _SocialAvatar({
    required this.initials,
    required this.color,
    required this.size,
    this.textColor,
    this.shadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.32,
            fontWeight: FontWeight.w700,
            color: textColor ?? Colors.white,
          ),
        ),
      ),
    );
  }
}

class _PresenceCount extends StatelessWidget {
  final String icon;
  final int count;
  final String label;

  const _PresenceCount({
    required this.icon,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Color(0x99FFFFFF),
          ),
        ),
      ],
    );
  }
}

// ── Coffee availability toggle + monthly stats ────────────────────────

class _CoffeeToggleCard extends StatelessWidget {
  final bool isDark;
  final bool myAvailable;
  final ({int sent, int received, int accepted}) stats;
  final ValueChanged<bool> onToggle;

  const _CoffeeToggleCard({
    required this.isDark,
    required this.myAvailable,
    required this.stats,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : AppColors.neutral400;
    final hasStats = stats.sent > 0 || stats.received > 0 || stats.accepted > 0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('☕', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.coffeeAvailableToggle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textMain,
                      ),
                    ),
                    Text(
                      AppStrings.coffeeVisibleHint,
                      style: TextStyle(fontSize: 10, color: textSub),
                    ),
                  ],
                ),
              ),
              Switch(
                value: myAvailable,
                onChanged: onToggle,
                activeThumbColor: AppColors.green500,
                activeTrackColor: AppColors.green500.withValues(alpha: 0.4),
              ),
            ],
          ),
          if (hasStats) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _StatChip(
                  label: '↑ ${stats.sent}',
                  sublabel: 'inviati',
                  color: AppColors.blue600,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: '↓ ${stats.received}',
                  sublabel: 'ricevuti',
                  color: AppColors.orange500,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: '✅ ${stats.accepted}',
                  sublabel: 'accettati',
                  color: AppColors.green600,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Mobile compact quick-bar: groups + coffee toggle ──────────────────────

class _SocialQuickBar extends ConsumerWidget {
  final bool isDark;
  final bool myAvailable;
  final VoidCallback onGroupsTap;
  final ValueChanged<bool> onCoffeeToggle;

  const _SocialQuickBar({
    required this.isDark,
    required this.myAvailable,
    required this.onGroupsTap,
    required this.onCoffeeToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsStreamProvider).asData?.value ?? [];
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : AppColors.neutral400;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.7);
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.6);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Groups side
          Expanded(
            child: GestureDetector(
              onTap: onGroupsTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Text('👥', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        groups.isEmpty
                            ? 'Nessun gruppo'
                            : '${groups.length} ${groups.length == 1 ? "gruppo" : "gruppi"}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textMain,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 16, color: textSub),
                  ],
                ),
              ),
            ),
          ),
          // Divider
          Container(width: 1, height: 24, color: borderColor),
          // Coffee toggle side
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Text('☕', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 6),
                Text(
                  'Caffè',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textMain,
                  ),
                ),
                const SizedBox(width: 6),
                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: myAvailable,
                    onChanged: onCoffeeToggle,
                    activeThumbColor: AppColors.green500,
                    activeTrackColor: AppColors.green500.withValues(alpha: 0.4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;

  const _StatChip({
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            sublabel,
            style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }
}

// ── Coffee schedule bottom sheet ──────────────────────────────────────

class _CoffeeScheduleSheet extends StatelessWidget {
  final bool isDark;
  const _CoffeeScheduleSheet({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF10102A).withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
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
                      : Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                AppStrings.coffeeInvite,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: textMain,
                ),
              ),
              const SizedBox(height: 20),
              _CoffeeOptionBtn(
                icon: '☕',
                label: 'Adesso',
                subtitle: "Invia l'invito subito",
                isDark: isDark,
                onTap: () => Navigator.pop(context, ''),
              ),
              const SizedBox(height: 10),
              _CoffeeOptionBtn(
                icon: '🗓',
                label: 'Pianifica',
                subtitle: 'Scegli un orario',
                isDark: isDark,
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (t != null && context.mounted) {
                    final formatted =
                        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                    Navigator.pop(context, formatted);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoffeeOptionBtn extends StatelessWidget {
  final String icon;
  final String label;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _CoffeeOptionBtn({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : AppColors.neutral400;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textMain,
                  ),
                ),
                Text(subtitle, style: TextStyle(fontSize: 11, color: textSub)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mobile groups bottom sheet ─────────────────────────────────────────────

class _GroupsMobileSheet extends ConsumerStatefulWidget {
  final bool isDark;
  const _GroupsMobileSheet({required this.isDark});

  @override
  ConsumerState<_GroupsMobileSheet> createState() => _GroupsMobileSheetState();
}

class _GroupsMobileSheetState extends ConsumerState<_GroupsMobileSheet> {
  Future<void> _createGroup() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.newGroup),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(hintText: AppStrings.groupName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text(AppStrings.create),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(socialRepositoryProvider).createGroup(name);
    }
  }

  Future<void> _deleteGroup(ColleagueGroup group) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.deleteGroupConfirm(group.name)),
        content: Text(AppStrings.deleteGroupBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              AppStrings.delete,
              style: TextStyle(color: AppColors.red700),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(socialRepositoryProvider).deleteGroup(group.id);
    }
  }

  Future<void> _sendGroupCoffee(ColleagueGroup group) async {
    final profileData = ref.read(userProfileStreamProvider).asData?.value;
    final myName = profileData?['name'] as String? ?? 'Un collega';
    await ref
        .read(socialRepositoryProvider)
        .sendGroupCoffee(group.id, fromName: myName);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.coffeeGroupSent(group.name))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.38)
        : AppColors.neutral400;

    final groups = ref.watch(groupsStreamProvider).asData?.value ?? [];
    final colleagues = ref.watch(colleaguesStreamProvider).asData?.value ?? [];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF10102A).withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle + header
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    AppStrings.groups,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: textMain,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _createGroup,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blue600.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: AppColors.blue600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppStrings.newGroup,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.blue600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Groups list
              if (groups.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    AppStrings.noGroups,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textSub, fontSize: 13),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: groups.length,
                    itemBuilder: (_, i) {
                      final g = groups[i];
                      final inOffice = colleagues
                          .where(
                            (c) =>
                                g.memberUids.contains(c.uid) &&
                                c.canReceiveCoffee,
                          )
                          .length;
                      return _GroupTile(
                        label: g.name,
                        memberCount: g.memberUids.length,
                        inOfficeCount: inOffice,
                        selected: false,
                        isDark: isDark,
                        textMain: textMain,
                        onTap: () {},
                        onDelete: () => _deleteGroup(g),
                        onCoffee: g.memberUids.isEmpty
                            ? null
                            : () => _sendGroupCoffee(g),
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

// ── Colleague filter bar ──────────────────────────────────────────────────────

class _ColleagueFilterBar extends StatelessWidget {
  final bool isDark;
  final List<String> sedeOptions;
  final List<String> dipOptions;
  final List<String> statusOptions;
  final String? filterSede;
  final String? filterDip;
  final String? filterStatus;
  final Map<String, String> statusLabel;
  final ValueChanged<String?> onSedeChanged;
  final ValueChanged<String?> onDipChanged;
  final ValueChanged<String?> onStatusChanged;

  const _ColleagueFilterBar({
    required this.isDark,
    required this.sedeOptions,
    required this.dipOptions,
    required this.statusOptions,
    required this.filterSede,
    required this.filterDip,
    required this.filterStatus,
    required this.statusLabel,
    required this.onSedeChanged,
    required this.onDipChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : AppColors.neutral400;
    const activeColor = AppColors.blue600;

    Widget chip(String label, bool active, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: active
                ? activeColor.withValues(alpha: 0.15)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.7)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? activeColor.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? activeColor : textSub,
            ),
          ),
        ),
      );
    }

    final chips = <Widget>[];

    if (sedeOptions.length > 1) {
      for (final s in sedeOptions) {
        chips.add(
          chip(
            s,
            filterSede == s,
            () => onSedeChanged(filterSede == s ? null : s),
          ),
        );
      }
      chips.add(const SizedBox(width: 4));
    }

    if (dipOptions.length > 1) {
      for (final d in dipOptions) {
        final short = d.length > 18 ? '${d.substring(0, 16)}…' : d;
        chips.add(
          chip(
            short,
            filterDip == d,
            () => onDipChanged(filterDip == d ? null : d),
          ),
        );
      }
      chips.add(const SizedBox(width: 4));
    }

    for (final s in statusOptions) {
      final lbl = statusLabel[s];
      if (lbl == null) continue;
      chips.add(
        chip(
          lbl,
          filterStatus == s,
          () => onStatusChanged(filterStatus == s ? null : s),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.expand((w) => [w, const SizedBox(width: 6)]).toList(),
      ),
    );
  }
}
