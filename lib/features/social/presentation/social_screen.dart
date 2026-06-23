import 'dart:math' show Random;
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
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
import '../../../core/constants/chigio_quotes.dart';

Color _colleagueAvatarColor(String name) {
  const palette = [
    Color(0xFF7C4DFF), Color(0xFF00BCD4), Color(0xFFFF5722),
    Color(0xFF4CAF50), Color(0xFFFF9800), Color(0xFFE91E63),
    Color(0xFF009688), Color(0xFF795548), Color(0xFF607D8B),
    Color(0xFF3F51B5), Color(0xFFFF6F00), Color(0xFF00897B),
  ];
  if (name.isEmpty) return palette[0];
  return palette[name.codeUnitAt(0) % palette.length];
}

/// Colore dell'anello avatar per lo stato di timbratura (B5).
/// Verde=in sede, blu=smart, giallo=pausa, nero=uscito/assenza.
Color statusRingColor(String effectiveStatus) => switch (effectiveStatus) {
  'working' => AppColors.green600,
  'paused' => AppColors.orange500,
  'remote' => AppColors.blue600,
  'completed' || 'notStarted' => AppColors.neutral900,
  _ => AppColors.neutral400,
};

/// Spiegazione testuale dello stato di timbratura del collega (B5), mostrata
/// nel profilo collega accanto all'anello colorato dell'avatar.
String statusExplanation(String effectiveStatus) => switch (effectiveStatus) {
  'working' => AppStrings.statusExplainWorking,
  'paused' => AppStrings.statusExplainPaused,
  'remote' => AppStrings.statusExplainRemote,
  'completed' => AppStrings.statusExplainCompleted,
  _ => AppStrings.statusExplainAbsent,
};

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
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  static const _statusLabel = {
    'working': AppStrings.statusWorking,
    'paused': AppStrings.statusPaused,
    'remote': AppStrings.statusRemote,
    'completed': AppStrings.statusExited,
    'notStarted': AppStrings.statusOutOfOffice,
  };
  static const _statusIcon = {
    'working': '🏢',
    'paused': '☕',
    'remote': '🏠',
    'completed': '🌙',
    'notStarted': '—',
  };
  // B5: stato "uscito" (completed) e "assenza" (notStarted) uniti in un
  // unico stato nero. Verde=in sede, blu=smart, giallo=pausa.
  static const _statusColor = {
    'working': AppColors.green600,
    'paused': AppColors.orange500,
    'remote': AppColors.blue600,
    'completed': AppColors.neutral900,
    'notStarted': AppColors.neutral900,
  };

  static Color _avatarColor(String name) => _colleagueAvatarColor(name);


  Future<void> _sendCoffee(ColleagueProfile c, {String? scheduledAt}) async {
    final profileData = ref.read(userProfileStreamProvider).asData?.value;
    final myName = profileData?['name'] as String? ?? AppStrings.aColleague;
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

  void _showColleagueDetail(ColleagueProfile c) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ColleagueDetailSheet(
        colleague: c,
        avatarColor: _avatarColor(c.name),
        statusLabel: _statusLabel[c.effectiveStatus] ?? '',
        statusIcon: _statusIcon[c.effectiveStatus] ?? '',
        statusColor: _statusColor[c.effectiveStatus] ?? AppColors.neutral400,
        isDark: isDark,
      ),
    );
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
        userName: profileData?['name'] as String? ?? '',
        existingUids: existing,
        onAdd: (uid) => ref.read(socialRepositoryProvider).addColleague(uid),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
    final groups = ref.watch(groupsStreamProvider).asData?.value ?? [];

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
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where(
        (c) =>
            c.name.toLowerCase().contains(q) ||
            (c.dipartimento?.toLowerCase().contains(q) ?? false) ||
            (c.sede?.toLowerCase().contains(q) ?? false),
      );
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

          // ── Search ───────────────────────────────────────────────────
          if (allColleagues.isNotEmpty) ...[
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : AppColors.neutral900,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  hintText: AppStrings.searchColleagues,
                  hintStyle: TextStyle(fontSize: 13, color: textSub),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: textSub,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: textSub,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

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
                      (c.canReceiveCoffee && !_coffeesSent.contains(c.uid))
                      ? () => _showCoffeeOptions(c)
                      : null,
                  onToggleFavorite: () => _toggleFavorite(c),
                  onRemove: () => _remove(c),
                  onTap: () => _showColleagueDetail(c),
                  groupLabels: groups
                      .where((g) => g.memberUids.contains(c.uid))
                      .map((g) => g.name)
                      .toList(),
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
                      (c.canReceiveCoffee && !_coffeesSent.contains(c.uid))
                      ? () => _showCoffeeOptions(c)
                      : null,
                  onToggleFavorite: () => _toggleFavorite(c),
                  onRemove: () => _remove(c),
                  onTap: () => _showColleagueDetail(c),
                  groupLabels: groups
                      .where((g) => g.memberUids.contains(c.uid))
                      .map((g) => g.name)
                      .toList(),
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
    final myName = profileData?['name'] as String? ?? AppStrings.aColleague;
    await ref
        .read(socialRepositoryProvider)
        .sendGroupCoffee(group.id, fromName: myName);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.coffeeGroupSent(group.name))),
    );
  }

  Future<void> _renameGroup(ColleagueGroup group) async {
    final ctrl = TextEditingController(text: group.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(AppStrings.renameGroup),
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
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name != null && name.isNotEmpty) {
      await ref.read(socialRepositoryProvider).renameGroup(group.id, name);
    }
  }

  Future<void> _manageGroupMembers(ColleagueGroup group) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GroupMembersSheet(group: group, isDark: widget.isDark),
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
          label: AppStrings.allColleaguesSection,
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
                onRename: () => _renameGroup(g),
                onManageMembers: () => _manageGroupMembers(g),
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
  final VoidCallback? onRename;
  final VoidCallback? onManageMembers;

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
    this.onRename,
    this.onManageMembers,
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
              const SizedBox(width: 4),
            ],
            if (onRename != null)
              GestureDetector(
                onTap: onRename,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.edit_outlined,
                      size: 13,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : AppColors.neutral400,
                    ),
                  ),
                ),
              ),
            if (onRename != null && onCoffee != null) const SizedBox(width: 4),
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
            if (onManageMembers != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onManageMembers,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.blue600.withValues(alpha: 0.12),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.group_rounded,
                      size: 13,
                      color: AppColors.blue600,
                    ),
                  ),
                ),
              ),
            ],
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
                            photoURL: e.value.photoURL,
                            ringColor: AppColors.green600,
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
            AppStrings.peopleInOffice(working.length),
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
                label: AppStrings.statusWorking,
              ),
              const SizedBox(width: 16),
              _PresenceCount(
                icon: '🏠',
                count: remoteCount,
                label: AppStrings.statusRemote,
              ),
              const SizedBox(width: 16),
              _PresenceCount(icon: '☕', count: pausedCount, label: AppStrings.statusPaused),
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
  final VoidCallback onTap;
  final List<String> groupLabels;

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
    required this.onTap,
    this.groupLabels = const [],
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : AppColors.neutral400;

    final hasInterno = colleague.interno?.isNotEmpty ?? false;
    final hasCell = colleague.phoneNumber?.isNotEmpty ?? false;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onRemove,
      child: GlassTile(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _SocialAvatar(
                initials: colleague.initials,
                color: avatarColor,
                size: 46,
                shadow: true,
                photoURL: colleague.photoURL,
                ringColor: statusColor,
              ),
            ),
            const SizedBox(width: 12),

            // Name + group chips + info rows
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row with inline group chips
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 5,
                    runSpacing: 3,
                    children: [
                      Text(
                        colleague.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textMain,
                        ),
                      ),
                      for (final g in groupLabels)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blue600.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            g,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.blue600,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Dipartimento
                  if (colleague.dipartimento?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        colleague.dipartimento!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: textSub),
                      ),
                    ),

                  // Status message
                  if (colleague.statusMessage?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 10,
                            color: AppColors.blue600.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              colleague.statusMessage!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                color: AppColors.blue600.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Sede · Piano · Stanza
                  Builder(builder: (_) {
                    final parts = <String>[
                      if (colleague.sede?.isNotEmpty ?? false)
                        colleague.sede!,
                      if (colleague.piano?.isNotEmpty ?? false)
                        AppStrings.pianoValue(colleague.piano!),
                      if (colleague.stanza?.isNotEmpty ?? false)
                        AppStrings.stanzaShort(colleague.stanza!),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10, color: textSub),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Action row: interno + cellulare + coffee + star + status
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Interno button
                      if (hasInterno)
                        _ActionBtn(
                          isDark: isDark,
                          size: 30,
                          onTap: () => launchUrl(
                            Uri(scheme: 'tel', path: colleague.interno!),
                          ),
                          child: const Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: AppColors.green600,
                          ),
                        ),
                      if (hasInterno) const SizedBox(width: 5),

                      // Cellulare button
                      if (hasCell)
                        _ActionBtn(
                          isDark: isDark,
                          size: 30,
                          onTap: () => launchUrl(
                            Uri(
                              scheme: 'tel',
                              path: colleague.phoneNumber!,
                            ),
                          ),
                          child: const Icon(
                            Icons.smartphone_rounded,
                            size: 14,
                            color: AppColors.blue600,
                          ),
                        ),
                      if (hasCell) const SizedBox(width: 5),

                      // Coffee button — always shown
                      GestureDetector(
                        onTap: coffeeSent ? null : onCoffee,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: coffeeSent
                                ? AppColors.green500.withValues(alpha: 0.2)
                                : onCoffee != null
                                ? (isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.black.withValues(alpha: 0.05))
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.black.withValues(alpha: 0.02)),
                            boxShadow: coffeeSent
                                ? [
                                    BoxShadow(
                                      color: AppColors.green500.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              coffeeSent ? '✅' : '☕',
                              style: TextStyle(
                                fontSize: 13,
                                color: (!coffeeSent && onCoffee == null)
                                    ? null
                                    : null,
                              ).copyWith(
                                color: (!coffeeSent && onCoffee == null)
                                    ? textSub
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),

                      // Favorite star
                      GestureDetector(
                        onTap: onToggleFavorite,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 30,
                          height: 30,
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
                              size: 16,
                              color: colleague.isFavorite
                                  ? AppColors.orange500
                                  : textSub,
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Status badge
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
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final bool isDark;
  final double size;
  final VoidCallback onTap;
  final Widget child;

  const _ActionBtn({
    required this.isDark,
    required this.size,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ── Add colleague bottom sheet ─────────────────────────────────────────

class _AddColleagueSheet extends ConsumerStatefulWidget {
  final String administration;
  final String userName;
  final Set<String> existingUids;
  final Future<void> Function(String uid) onAdd;

  const _AddColleagueSheet({
    required this.administration,
    required this.userName,
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
  final _linkCtrl = TextEditingController();
  bool _addingFromLink = false;

  static const _baseUrl = 'https://chigiotime.web.app/add';

  String get _myInviteLink {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return '$_baseUrl?uid=$uid';
  }

  String? _uidFromInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    // Try to parse as URL
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.queryParameters.containsKey('uid')) {
      final uid = uri.queryParameters['uid']!;
      return uid.isNotEmpty ? uid : null;
    }
    // Firebase UID: exactly 28 alphanumeric chars
    if (RegExp(r'^[A-Za-z0-9]{28}$').hasMatch(trimmed)) return trimmed;
    return null;
  }

  Future<void> _addFromLink() async {
    final uid = _uidFromInput(_linkCtrl.text);
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.inviteLinkInvalidUid)),
      );
      return;
    }
    setState(() => _addingFromLink = true);
    await widget.onAdd(uid);
    if (mounted) {
      _linkCtrl.clear();
      setState(() => _addingFromLink = false);
      Navigator.of(context).pop();
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _linkCtrl.dispose();
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

              // Link share + paste section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // My invite link row
                    Row(
                      children: [
                        Icon(Icons.link_rounded, size: 15, color: AppColors.blue600),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            AppStrings.shareInviteLink,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textMain,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            await Clipboard.setData(
                              ClipboardData(text: _myInviteLink),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(AppStrings.inviteLinkCopied),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.copy_rounded, size: 16, color: textSub),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            final phrase = ChigioQuotes.invite[
                              Random().nextInt(ChigioQuotes.invite.length)
                            ];
                            final name = widget.userName.isNotEmpty ? widget.userName : 'un collega';
                            final admin = widget.administration.isNotEmpty
                                ? ' di ${widget.administration}'
                                : '';
                            final text = 'Ciao! Sono $name$admin.\n'
                                'Ti invito a usare Chigio Time per gestire i tuoi cartellini 🐢\n\n'
                                '"$phrase"\n\n'
                                '$_myInviteLink';
                            Share.share(text, subject: AppStrings.shareInviteLink);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.share_rounded, size: 16, color: AppColors.blue600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Paste link to add
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            child: TextField(
                              controller: _linkCtrl,
                              style: TextStyle(fontSize: 13, color: textMain),
                              decoration: InputDecoration(
                                hintText: AppStrings.pasteColleagueLink,
                                hintStyle: TextStyle(fontSize: 13, color: textSub),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _addingFromLink ? null : _addFromLink,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.blue600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _addingFromLink
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    AppStrings.addFromLinkBtn,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
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
                              : AppStrings.noResults,
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
            AppStrings.addColleaguesHint,
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
  final String? photoURL;

  /// Anello colorato per lo stato di timbratura del collega (B5). Quando
  /// valorizzato sostituisce il sottile bordo bianco con un ring più marcato.
  final Color? ringColor;

  const _SocialAvatar({
    required this.initials,
    required this.color,
    required this.size,
    this.textColor,
    this.shadow = false,
    this.photoURL,
    this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      border: Border.all(
        color: ringColor ?? Colors.white.withValues(alpha: 0.3),
        width: ringColor != null ? 3 : 1.5,
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
    );

    if (photoURL != null && photoURL!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: decoration,
        child: ClipOval(
          child: Image.network(
            photoURL!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _initialsWidget(size),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: decoration,
      child: Center(child: _initialsWidget(size)),
    );
  }

  Widget _initialsWidget(double size) => Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.32,
          fontWeight: FontWeight.w700,
          color: textColor ?? Colors.white,
        ),
      );
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
                  sublabel: AppStrings.sentSublabel,
                  color: AppColors.blue600,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: '↓ ${stats.received}',
                  sublabel: AppStrings.receivedSublabel,
                  color: AppColors.orange500,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: '✅ ${stats.accepted}',
                  sublabel: AppStrings.acceptedSublabel,
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
                            ? AppStrings.noGroup
                            : AppStrings.groupCount(groups.length),
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
                  AppStrings.coffeeLabel,
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
                label: AppStrings.sendNow,
                subtitle: AppStrings.sendInviteNow,
                isDark: isDark,
                onTap: () => Navigator.pop(context, ''),
              ),
              const SizedBox(height: 10),
              _CoffeeOptionBtn(
                icon: '🗓',
                label: AppStrings.planLabel,
                subtitle: AppStrings.chooseTime,
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

  Future<void> _renameGroup(ColleagueGroup group) async {
    final ctrl = TextEditingController(text: group.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.renameGroup),
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
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name != null && name.isNotEmpty) {
      await ref.read(socialRepositoryProvider).renameGroup(group.id, name);
    }
  }

  Future<void> _manageGroupMembers(ColleagueGroup group) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GroupMembersSheet(group: group, isDark: widget.isDark),
    );
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
    final myName = profileData?['name'] as String? ?? AppStrings.aColleague;
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
                        onRename: () => _renameGroup(g),
                        onManageMembers: () => _manageGroupMembers(g),
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

// ── Group members management sheet ───────────────────────────────────────────

class _GroupMembersSheet extends ConsumerStatefulWidget {
  final ColleagueGroup group;
  final bool isDark;
  const _GroupMembersSheet({required this.group, required this.isDark});

  @override
  ConsumerState<_GroupMembersSheet> createState() => _GroupMembersSheetState();
}

class _GroupMembersSheetState extends ConsumerState<_GroupMembersSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final group = widget.group;
    final colleagues =
        ref.watch(colleaguesStreamProvider).asData?.value ?? [];
    final members = colleagues.where((c) => group.memberUids.contains(c.uid)).toList();
    final nonMembers = colleagues
        .where((c) =>
            !group.memberUids.contains(c.uid) &&
            (_search.isEmpty ||
                c.name.toLowerCase().contains(_search.toLowerCase())))
        .toList();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.80,
          ),
          padding: EdgeInsets.fromLTRB(
            20, 16, 20,
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
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                '${AppStrings.groups}: ${group.name}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 12),
              if (members.isNotEmpty) ...[
                Text(
                  'Membri (${members.length})',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white.withValues(alpha: 0.4) : AppColors.neutral400,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                ...members.map((c) => _MemberRow(
                  colleague: c,
                  isDark: isDark,
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: AppColors.red700),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => ref
                        .read(socialRepositoryProvider)
                        .removeMemberFromGroup(group.id, c.uid),
                  ),
                )),
                const SizedBox(height: 10),
              ],
              Text(
                'Aggiungi colleghi',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white.withValues(alpha: 0.4) : AppColors.neutral400,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: AppStrings.searchColleagues,
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: nonMembers.map((c) => _MemberRow(
                    colleague: c,
                    isDark: isDark,
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.blue600),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () => ref
                          .read(socialRepositoryProvider)
                          .addMemberToGroup(group.id, c.uid),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (dCtx) => AlertDialog(
                        title: Text(AppStrings.deleteGroupConfirm(group.name)),
                        content: Text(AppStrings.deleteGroupBody),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dCtx, false),
                            child: const Text(AppStrings.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(dCtx, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.red700,
                            ),
                            child: const Text(AppStrings.delete),
                          ),
                        ],
                      ),
                    );
                    if (ok != true) return;
                    await ref
                        .read(socialRepositoryProvider)
                        .deleteGroup(group.id);
                    if (nav.mounted) nav.pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.red700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text(
                    'Elimina gruppo',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final ColleagueProfile colleague;
  final bool isDark;
  final Widget trailing;
  const _MemberRow({required this.colleague, required this.isDark, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _SocialAvatar(
            initials: colleague.initials,
            color: _colleagueAvatarColor(colleague.name),
            size: 32,
            photoURL: colleague.photoURL,
            ringColor: statusRingColor(colleague.effectiveStatus),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              colleague.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white.withValues(alpha: 0.85) : AppColors.neutral900,
              ),
            ),
          ),
          trailing,
        ],
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

// ── Colleague detail sheet ───────────────────────────────────────────────────

class _ColleagueDetailSheet extends ConsumerWidget {
  final ColleagueProfile colleague;
  final Color avatarColor;
  final String statusLabel;
  final String statusIcon;
  final Color statusColor;
  final bool isDark;

  const _ColleagueDetailSheet({
    required this.colleague,
    required this.avatarColor,
    required this.statusLabel,
    required this.statusIcon,
    required this.statusColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral600;
    final bg = isDark ? const Color(0xFF131830) : Colors.white;

    final coffeeLog = ref.watch(coffeeLogStreamProvider).asData?.value ?? [];
    final history = coffeeLog
        .where((e) => e['withUid'] == colleague.uid)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Avatar + name + status
            Row(
              children: [
                _SocialAvatar(
                  initials: colleague.initials,
                  color: avatarColor,
                  size: 56,
                  shadow: true,
                  photoURL: colleague.photoURL,
                  ringColor: statusColor,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        colleague.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textMain,
                        ),
                      ),
                      if (colleague.statusMessage?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            colleague.statusMessage!,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: AppColors.blue600.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$statusIcon $statusLabel',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                      // B5: spiegazione del significato dell'anello/stato.
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          statusExplanation(colleague.effectiveStatus),
                          style: TextStyle(fontSize: 11, color: textSub),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Divider(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            const SizedBox(height: 12),

            // Info rows
            _DetailRow(
              icon: Icons.business_outlined,
              label: AppStrings.dipartimento,
              value: colleague.dipartimento,
              textMain: textMain,
              textSub: textSub,
            ),
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: AppStrings.sede,
              value: colleague.sede,
              textMain: textMain,
              textSub: textSub,
            ),
            _DetailRow(
              icon: Icons.stairs_outlined,
              label: AppStrings.piano,
              value: colleague.piano,
              textMain: textMain,
              textSub: textSub,
            ),
            _DetailRow(
              icon: Icons.door_sliding_outlined,
              label: AppStrings.stanzaUfficio,
              value: colleague.stanza,
              textMain: textMain,
              textSub: textSub,
            ),
            _DetailRow(
              icon: Icons.phone_outlined,
              label: AppStrings.interno,
              value: colleague.interno,
              textMain: textMain,
              textSub: textSub,
              onTap: colleague.interno?.isNotEmpty ?? false
                  ? () => launchUrl(Uri(scheme: 'tel', path: colleague.interno!))
                  : null,
            ),
            _DetailRow(
              icon: Icons.smartphone_outlined,
              label: AppStrings.phoneNumber,
              value: colleague.phoneNumber,
              textMain: textMain,
              textSub: textSub,
              onTap: colleague.phoneNumber?.isNotEmpty ?? false
                  ? () =>
                      launchUrl(Uri(scheme: 'tel', path: colleague.phoneNumber!))
                  : null,
            ),
            _DetailRow(
              icon: Icons.badge_outlined,
              label: AppStrings.employmentType,
              value: colleague.employmentType.isEmpty
                  ? null
                  : colleague.employmentType,
              textMain: textMain,
              textSub: textSub,
            ),

            if (history.isNotEmpty) ...[
              const SizedBox(height: 16),
              Divider(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.coffeeHistoryLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textSub,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              ...history.take(10).map((e) {
                final ts = e['sentAt'];
                String dateStr = '—';
                if (ts != null) {
                  final dt = (ts as dynamic).toDate() as DateTime;
                  dateStr =
                      '${dt.day.toString().padLeft(2, '0')}/'
                      '${dt.month.toString().padLeft(2, '0')}/'
                      '${dt.year}';
                }
                final resp = e['responseType'] as String? ?? '';
                final respIcon = switch (resp) {
                  'accepted' => '✅',
                  'maybe' => '🤔',
                  'declined' => '❌',
                  _ => '☕',
                };
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text(respIcon, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 12, color: textSub),
                      ),
                      if (e['scheduledAt'] != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '· ${e['scheduledAt']}',
                          style: TextStyle(fontSize: 12, color: textSub),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color textMain;
  final Color textSub;
  final VoidCallback? onTap;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textMain,
    required this.textSub,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: AppColors.neutral400),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 10, color: AppColors.neutral400),
                  ),
                  Text(
                    value!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: onTap != null ? AppColors.blue600 : textMain,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
