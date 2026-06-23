import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/color_schemes.dart';
import '../../../core/services/chigio_phrase_engine.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_header.dart';
import '../../social/data/social_repository.dart';
import '../data/pomodoro_repository.dart';
import '../domain/project.dart';
import '../domain/pomodoro_session.dart';

/// Preset durata pomodoro (focus / pausa) — ADR-0011.
const _presets = [(focus: 25, brk: 5), (focus: 45, brk: 15)];

String _fmtClock(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  final m = (s ~/ 60).toString().padLeft(2, '0');
  final sec = (s % 60).toString().padLeft(2, '0');
  return '$m:$sec';
}

DateTime _weekStart(DateTime d) {
  final monday = d.subtract(Duration(days: d.weekday - 1));
  return DateTime(monday.year, monday.month, monday.day);
}

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  Timer? _ticker;
  bool _finalizing = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _maybeAutoComplete();
      setState(() {}); // refresh countdown
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // Auto-completa il pomodoro quando il tempo di focus è scaduto.
  Future<void> _maybeAutoComplete() async {
    if (_finalizing) return;
    final timer = ref.read(activeTimerStreamProvider).value;
    if (timer == null) return;
    final end = timer.startedAt.add(Duration(minutes: timer.focusMins));
    if (DateTime.now().isBefore(end)) return;
    _finalizing = true;
    final repo = ref.read(pomodoroRepositoryProvider);
    await repo.addPomodoro(
      projectId: timer.projectId,
      focusMins: timer.focusMins,
      breakMins: timer.breakMins,
      startedAt: timer.startedAt,
      confirmed: true,
    );
    await repo.clearActiveTimer();
    _finalizing = false;
  }

  Future<void> _stopTimer({required bool save}) async {
    final timer = ref.read(activeTimerStreamProvider).value;
    final repo = ref.read(pomodoroRepositoryProvider);
    if (save && timer != null) {
      await repo.addPomodoro(
        projectId: timer.projectId,
        focusMins: timer.focusMins,
        breakMins: timer.breakMins,
        startedAt: timer.startedAt,
        confirmed: true,
      );
    }
    await repo.clearActiveTimer();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navClearance = MediaQuery.of(context).padding.bottom;
    final projects =
        ref.watch(myProjectsStreamProvider).asData?.value ??
        const <Project>[];
    final activeTimer = ref.watch(activeTimerStreamProvider).asData?.value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const GlassHeader(chigioPage: ChigioPage.other),
          Expanded(
            child: Stack(
              children: [
                ListView(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, navClearance + 90),
                  children: [
                    if (activeTimer != null)
                      _ActiveTimerCard(
                        timer: activeTimer,
                        onStop: () => _stopTimer(save: true),
                        onCancel: () => _stopTimer(save: false),
                      ),
                    if (activeTimer != null) const SizedBox(height: 14),
                    const _SectionLabel('I MIEI PROGETTI'),
                    const SizedBox(height: 8),
                    if (projects.isEmpty)
                      _EmptyProjects(isDark: isDark)
                    else
                      ...projects.map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ProjectCard(
                            project: p,
                            isDark: isDark,
                            onTap: () => _openDetail(p),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _DiscoverButton(onTap: _openDiscover),
                  ],
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: _openCreate,
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
                            color: const Color(0xFF0055A5).withValues(
                              alpha: 0.4,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(Project p) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProjectDetailSheet(
        project: p,
        timerRunning: ref.read(activeTimerStreamProvider).value != null,
      ),
    );
  }

  Future<void> _openCreate() async {
    final nameCtrl = TextEditingController();
    bool shared = false;
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Nuovo progetto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Nome del progetto',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Condividi con i Collegati'),
                subtitle: const Text(
                  'Visibile ai Collegati che potranno unirsi',
                  style: TextStyle(fontSize: 11),
                ),
                value: shared,
                onChanged: (v) => setLocal(() => shared = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Crea'),
            ),
          ],
        ),
      ),
    );
    if (created == true && nameCtrl.text.trim().isNotEmpty) {
      await ref
          .read(pomodoroRepositoryProvider)
          .createProject(name: nameCtrl.text.trim(), shared: shared);
    }
  }

  void _openDiscover() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DiscoverSheet(),
    );
  }
}

// ── Active timer card ────────────────────────────────────────────────────────

class _ActiveTimerCard extends StatelessWidget {
  final ActivePomodoro timer;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  const _ActiveTimerCard({
    required this.timer,
    required this.onStop,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(timer.startedAt).inSeconds;
    final remaining = timer.focusMins * 60 - elapsed;
    return GlassCard(
      overrideColor: AppColors.green600.withValues(alpha: 0.14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🍅', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  timer.projectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _fmtClock(remaining),
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                color: AppColors.green600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Annulla'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onStop,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Concludi'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Project card ──────────────────────────────────────────────────────────────

class _ProjectCard extends ConsumerWidget {
  final Project project;
  final bool isDark;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions =
        ref.watch(pomodorosStreamProvider(project.id)).asData?.value ??
        const <PomodoroSession>[];
    final today = sessions.where((s) => s.dateId == _todayId()).length;
    final color = Color(project.colorValue);

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        child: Row(
          children: [
            Container(
              width: 10,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (project.shared) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.group_rounded,
                          size: 14,
                          color: AppColors.blue600,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$today 🍅 oggi · ${sessions.length} totali',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.neutral400),
          ],
        ),
      ),
    );
  }
}

// ── Project detail sheet ───────────────────────────────────────────────────────

class _ProjectDetailSheet extends ConsumerWidget {
  final Project project;
  final bool timerRunning;

  const _ProjectDetailSheet({required this.project, required this.timerRunning});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF131830) : Colors.white;
    final uid = ref.watch(pomodoroRepositoryProvider).currentUid;
    final isOwner = uid != null && project.isOwner(uid);
    final sessions =
        ref.watch(pomodorosStreamProvider(project.id)).asData?.value ??
        const <PomodoroSession>[];

    final now = DateTime.now();
    final wStart = _weekStart(now);
    int countWhere(bool Function(PomodoroSession) f) => sessions.where(f).length;
    final today = countWhere((s) => s.dateId == _todayId());
    final week = countWhere((s) => !s.startedAt.isBefore(wStart));
    final month = countWhere(
      (s) => s.startedAt.year == now.year && s.startedAt.month == now.month,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (project.shared)
                  const Icon(Icons.group_rounded, color: AppColors.blue600),
              ],
            ),
            Text(
              project.shared
                  ? 'Condiviso · capo: ${project.ownerName}'
                  : 'Personale',
              style: const TextStyle(fontSize: 12, color: AppColors.neutral400),
            ),
            const SizedBox(height: 16),

            // Counters
            Row(
              children: [
                _Counter(label: 'Oggi', value: today),
                _Counter(label: 'Settimana', value: week),
                _Counter(label: 'Mese', value: month),
                _Counter(label: 'Sempre', value: sessions.length),
              ],
            ),
            const SizedBox(height: 18),

            // Start timer
            Text(
              timerRunning ? 'Timer già in corso' : 'Avvia un pomodoro',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final p in _presets) ...[
                  Expanded(
                    child: FilledButton(
                      onPressed: timerRunning
                          ? null
                          : () async {
                              await ref
                                  .read(pomodoroRepositoryProvider)
                                  .startTimer(
                                    ActivePomodoro(
                                      projectId: project.id,
                                      projectName: project.name,
                                      focusMins: p.focus,
                                      breakMins: p.brk,
                                      startedAt: DateTime.now(),
                                    ),
                                  );
                              if (context.mounted) Navigator.pop(context);
                            },
                      child: Text('${p.focus}/${p.brk}'),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref
                        .read(pomodoroRepositoryProvider)
                        .addPomodoro(
                          projectId: project.id,
                          focusMins: 25,
                          breakMins: 5,
                        ),
                    child: const Text('+ manuale'),
                  ),
                ),
              ],
            ),

            // Shared: contributors breakdown
            if (project.shared && sessions.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text(
                'Contributi',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              ..._contributors(sessions).map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(c.name)),
                      Text(
                        '${c.count} 🍅 · ${c.pct}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 18),
            const Text(
              'Pomodori recenti',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            if (sessions.isEmpty)
              const Text(
                'Nessun pomodoro ancora.',
                style: TextStyle(fontSize: 12, color: AppColors.neutral400),
              )
            else
              ...sessions
                  .take(15)
                  .map(
                    (s) => _SessionRow(
                      session: s,
                      canDelete: isOwner || s.uid == uid,
                      onDelete: () => ref
                          .read(pomodoroRepositoryProvider)
                          .removePomodoro(project.id, s.id),
                    ),
                  ),

            const SizedBox(height: 18),
            // Actions
            if (isOwner) ...[
              _ActionTile(
                icon: Icons.edit_rounded,
                label: 'Rinomina progetto',
                onTap: () => _rename(context, ref),
              ),
              _ActionTile(
                icon: project.shared
                    ? Icons.lock_rounded
                    : Icons.group_add_rounded,
                label: project.shared
                    ? 'Rendi personale'
                    : 'Condividi con i Collegati',
                onTap: () => ref
                    .read(pomodoroRepositoryProvider)
                    .setShared(project.id, !project.shared),
              ),
              _ActionTile(
                icon: Icons.delete_outline_rounded,
                label: 'Elimina progetto',
                danger: true,
                onTap: () => _confirmDelete(context, ref),
              ),
            ] else
              _ActionTile(
                icon: Icons.logout_rounded,
                label: 'Abbandona progetto',
                onTap: () async {
                  await ref
                      .read(pomodoroRepositoryProvider)
                      .leaveProject(project.id);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(text: project.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rinomina progetto'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await ref
          .read(pomodoroRepositoryProvider)
          .renameProject(project.id, ctrl.text.trim());
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina progetto'),
        content: Text('Eliminare "${project.name}" e tutti i suoi pomodori?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red700),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(pomodoroRepositoryProvider).deleteProject(project.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  List<({String name, int count, int pct})> _contributors(
    List<PomodoroSession> sessions,
  ) {
    final byUser = <String, int>{};
    for (final s in sessions) {
      byUser[s.userName] = (byUser[s.userName] ?? 0) + 1;
    }
    final total = sessions.length;
    final list = byUser.entries
        .map(
          (e) => (
            name: e.key,
            count: e.value,
            pct: total == 0 ? 0 : ((e.value / total) * 100).round(),
          ),
        )
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return list;
  }
}

// ── Discover shared projects sheet ─────────────────────────────────────────────

class _DiscoverSheet extends ConsumerWidget {
  const _DiscoverSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF131830) : Colors.white;
    final colleagues =
        ref.watch(colleaguesStreamProvider).asData?.value ?? const [];
    final uids = colleagues.map((c) => c.uid).toList();
    final repo = ref.watch(pomodoroRepositoryProvider);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: FutureBuilder<List<Project>>(
        future: repo.discoverSharedFromColleagues(uids),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final projects = snap.data ?? const <Project>[];
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Progetti condivisi dai Collegati',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (projects.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Nessun progetto condiviso disponibile.',
                    style: TextStyle(color: AppColors.neutral400),
                  ),
                )
              else
                ...projects.map(
                  (p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(p.name),
                    subtitle: Text('Capo: ${p.ownerName}'),
                    trailing: FilledButton(
                      onPressed: () async {
                        await repo.joinProject(p.id);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Unisciti'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Small widgets ──────────────────────────────────────────────────────────────

String _todayId() {
  final d = DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class _Counter extends StatelessWidget {
  final String label;
  final int value;
  const _Counter({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.blue600,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.neutral400),
          ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final PomodoroSession session;
  final bool canDelete;
  final VoidCallback onDelete;

  const _SessionRow({
    required this.session,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(session.confirmed ? '🍅' : '⚠️'),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${session.dateId} · ${session.focusMins}m'
              '${session.userName.isNotEmpty ? ' · ${session.userName}' : ''}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 16),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.red700 : AppColors.blue600;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 20),
      title: Text(label, style: TextStyle(color: color, fontSize: 14)),
      onTap: onTap,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: isDark ? Colors.white.withValues(alpha: 0.4) : AppColors.neutral400,
      ),
    );
  }
}

class _DiscoverButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DiscoverButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.travel_explore_rounded, size: 18),
      label: const Text('Scopri progetti condivisi'),
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  final bool isDark;
  const _EmptyProjects({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          const Text('🍅', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 10),
          Text(
            'Nessun progetto ancora',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.8)
                  : AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Crea un progetto e avvia il tuo primo pomodoro.',
            style: TextStyle(fontSize: 12, color: AppColors.neutral400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
