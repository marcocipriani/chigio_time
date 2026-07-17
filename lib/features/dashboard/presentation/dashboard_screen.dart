import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import 'timer_provider.dart';
import 'totalizzatori_provider.dart';
import 'personal_absence_consumption_provider.dart';
import '../../../core/services/geofencing_service.dart';
import '../../timesheet/data/timesheet_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/cap_period.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/color_schemes.dart';
import 'custom_counters_provider.dart';
import '../domain/custom_counter.dart';
import '../widgets/favorite_colleagues_card.dart';
import '../widgets/orari_table_card.dart';
import '../widgets/pcm_route_planner_card.dart';
import '../widgets/pomodoro_card.dart';
import '../widgets/salary_card.dart';
import '../widgets/timbratura_hero.dart';
import '../widgets/totalizzatori_section.dart';
import '../../profile/presentation/profile_screen.dart'
    show showPortaleEdit, showHomeWidgetsPanel;
import '../../../core/constants/chigio_quotes.dart';
import '../../../shared/widgets/app_tappable.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/home_widget_header.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // select: la Home usa solo status e standardWorkMins — senza select
    // l'intera dashboard si ricostruirebbe a ogni tick del timer (1/s).
    final timerStatus = ref.watch(workTimerProvider.select((s) => s.status));
    final standardWorkMins = ref.watch(
      workTimerProvider.select((s) => s.standardWorkMins),
    );
    final notifier = ref.read(workTimerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Monthly stats from Firestore ─────────────────────
    final now2 = DateTime.now();
    final monthlyAsync = ref.watch(
      monthlyTimesheetsProvider((year: now2.year, month: now2.month)),
    );
    final profileData = ref.watch(userProfileStreamProvider).asData?.value;
    final hiddenWidgets = Set<String>.from(
      (profileData?['hiddenHomeWidgets'] as List?)?.cast<String>() ?? const [],
    );
    const defaultWidgetOrder = [
      'favorites',
      'maggiorPresenza',
      'counters',
      'bancaOre',
      'totalizzatori',
      'routePlanner',
      'orariTable',
      'pomodoro',
      'salary',
    ];
    final savedOrder =
        (profileData?['homeWidgetsOrder'] as List?)?.cast<String>() ?? const [];
    final widgetOrder = [
      ...savedOrder.where(defaultWidgetOrder.contains),
      ...defaultWidgetOrder.where((id) => !savedOrder.contains(id)),
    ];
    final featuredWidgets = Set<String>.from(
      (profileData?['featuredHomeWidgets'] as List?)?.cast<String>() ??
          const [],
    );
    final totData = ref.watch(totalizzatoriProvider);
    final absenceConsumption = ref
        .watch(personalAbsenceConsumptionProvider)
        .asData
        ?.value;
    final entries = monthlyAsync.asData?.value ?? [];

    // ── Today's shift auto-detection ─────────────────────
    // After an app restart the timer is in notStarted state, but today's
    // shift might already be saved in Firestore. Detect and show it.
    final todayId =
        '${now2.year}-'
        '${now2.month.toString().padLeft(2, '0')}-'
        '${now2.day.toString().padLeft(2, '0')}';
    final todayMatches = entries.where((e) => e.dateId == todayId);
    final todayEntry = todayMatches.isEmpty ? null : todayMatches.first;

    // Effective flags — the fine-grained shift state lives in TimbraturaHero;
    // here we only need "fresh day" vs "shift touched" for GPS card and note.
    final rawNotStarted = timerStatus == WorkState.notStarted;
    final isNotStarted = rawNotStarted && todayEntry == null;
    final isStarted = !isNotStarted;

    // ── Monthly OT alert ─────────────────────────────────
    final totalMonthOtMins = entries.fold<int>(
      0,
      (s, e) => s + (e.extraMins > 0 ? e.extraMins : 0),
    );
    final otAlertThresholdMins =
        (profileData?['monthlyOtAlertHours'] as int? ?? 0) * 60;
    final otAlertActive =
        otAlertThresholdMins > 0 && totalMonthOtMins >= otAlertThresholdMins;

    // Monthly deficit for SmartExit scenario 3
    // Count Mon–Fri working days in the month up to (not including) today
    int businessDaysBefore = 0;
    for (var d = 1; d < now2.day; d++) {
      final wd = DateTime(now2.year, now2.month, d).weekday;
      if (wd < 6) businessDaysBefore++;
    }
    final netBeforeToday = entries
        .where((e) => e.dateId != todayId)
        .fold<int>(0, (s, e) => s + e.netWorkedMins);
    final monthlyTargetBefore = businessDaysBefore * standardWorkMins;
    final monthlyDeficitMins = (monthlyTargetBefore - netBeforeToday).clamp(
      0,
      99999,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (_, cs) {
            final isDesktop = cs.maxWidth >= 800.0;

            final hero = TimbraturaHero(
              todayEntry: todayEntry,
              monthlyDeficitMins: monthlyDeficitMins,
              totData: totData,
              profileData: profileData,
              // Su desktop campanella+avatar stanno in alto a destra della
              // pagina (overlay sotto), non dentro la card.
              showHeaderActions: !isDesktop,
            );

            // GPS auto clock-in prompt — standalone card, fresh day only.
            final gpsCard = isNotStarted
                ? _GpsPromptCard(
                    profileData: profileData,
                    isDark: isDark,
                    onClockIn: () => notifier.startTurn(DateTime.now()),
                  )
                : null;

            final statsSection = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Alert banner (portal) ─────────────────────────
                if (totData != null && totData.activeAlerts.isNotEmpty) ...[
                  TotAlertBanner(alerts: totData.activeAlerts),
                  const SizedBox(height: 11),
                ],
                // ── OT monthly alert banner ───────────────────────
                if (otAlertActive) ...[
                  _OtAlertBanner(
                    thresholdHours: otAlertThresholdMins ~/ 60,
                    totalHours: totalMonthOtMins ~/ 60,
                  ),
                  const SizedBox(height: 11),
                ],

                // ── Ordered, hideable widgets ─────────────────────
                // ★ evidenza: sfondo gradiente blu + tema scuro forzato.
                for (final wid in widgetOrder)
                  if (!hiddenWidgets.contains(wid))
                    ...switch (wid) {
                      'favorites' => [
                        _featureWrap(
                          featuredWidgets.contains(wid),
                          const FavoriteColleaguesCard(),
                        ),
                        const SizedBox(height: 11),
                      ],
                      'maggiorPresenza' => [
                        _featureWrap(
                          featuredWidgets.contains(wid),
                          const _MaggiorPresenzaCard(),
                        ),
                        const SizedBox(height: 11),
                      ],
                      'counters' => [
                        _featureWrap(
                          featuredWidgets.contains(wid),
                          const _HomeCountersRow(),
                        ),
                        const SizedBox(height: 11),
                      ],
                      // Flaggato visibile ma senza dati portale → empty
                      // state con CTA, mai widget sparito silenziosamente.
                      'bancaOre' => [
                        _featureWrap(
                          featuredWidgets.contains(wid),
                          totData != null
                              ? BancaOreTile(data: totData)
                              : _PortaleMissingCard(
                                  title: AppStrings.bankHoursUpper,
                                  pose: ChigioQuotes.festeggia,
                                  accent: AppColors.green600,
                                  onCta: () => showPortaleEdit(
                                    context,
                                    ref,
                                    profileData ?? {},
                                  ),
                                ),
                        ),
                        const SizedBox(height: 11),
                      ],
                      'totalizzatori' => [
                        const SizedBox(height: 7),
                        _featureWrap(
                          featuredWidgets.contains(wid),
                          totData != null
                              ? TotalizzatoriSection(
                                  data: totData,
                                  consumption: absenceConsumption,
                                  onEdit: () => showPortaleEdit(
                                    context,
                                    ref,
                                    profileData ?? {},
                                  ),
                                  onChipEdit: (updates) async {
                                    final map = Map<String, dynamic>.from(
                                      ref.read(portaleRawProvider) ?? {},
                                    );
                                    map.addAll(updates);
                                    await ref
                                        .read(profileRepositoryProvider)
                                        .savePortaleData(map);
                                  },
                                )
                              : _PortaleMissingCard(
                                  title: AppStrings.totalizatori,
                                  pose: ChigioQuotes.lista,
                                  accent: AppColors.blue600,
                                  onCta: () => showPortaleEdit(
                                    context,
                                    ref,
                                    profileData ?? {},
                                  ),
                                ),
                        ),
                        if (totData != null) ...[
                          const SizedBox(height: 4),
                          const CustomCountersSection(),
                          const SizedBox(height: 4),
                        ] else
                          const SizedBox(height: 11),
                      ],
                      'routePlanner' => [
                        _featureWrap(
                          featuredWidgets.contains(wid),
                          const PcmRoutePlannerCard(),
                        ),
                        const SizedBox(height: 11),
                      ],
                      'orariTable' => [
                        _featureWrap(
                          featuredWidgets.contains(wid),
                          OrariTableCard(profileData: profileData),
                        ),
                        const SizedBox(height: 11),
                      ],
                      'pomodoro' => [
                        _featureWrap(
                          featuredWidgets.contains(wid),
                          const PomodoroCard(),
                        ),
                        const SizedBox(height: 11),
                      ],
                      'salary' => [
                        _featureWrap(
                          featuredWidgets.contains(wid),
                          const SalaryCard(),
                        ),
                        const SizedBox(height: 11),
                      ],
                      _ => const <Widget>[],
                    },

                // Home "vuota" (default nuovi account): CTA per scegliere
                // i widget da mostrare sotto la timbratura.
                if (!widgetOrder.any((w) => !hiddenWidgets.contains(w)))
                  _AddWidgetsCta(profileData: profileData ?? const {}),
              ],
            );

            final noteSection = isStarted
                ? _NoteSection(dateId: todayId, initialNote: todayEntry?.note)
                : null;

            // Link centrale "modifica widget" in fondo alla Home, solo se è
            // visibile più di un widget (con 0/1 basta la CTA/empty state).
            final visibleWidgetCount = widgetOrder
                .where((w) => !hiddenWidgets.contains(w))
                .length;
            final editWidgetsLink = visibleWidgetCount > 1
                ? Center(
                    child: AppTappable(
                      onTap: () => showHomeWidgetsPanel(
                        context,
                        ref,
                        profileData ?? const {},
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 14,
                              color: AppColors.blue600.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              AppStrings.editWidgetsLink,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.blue600.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : null;

            if (isDesktop) {
              final firebaseUser = FirebaseAuth.instance.currentUser;
              final displayName =
                  (profileData?['name'] as String?)?.trim().isNotEmpty == true
                  ? profileData!['name'] as String
                  : (firebaseUser?.displayName ?? AppStrings.defaultUserName);
              return Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          // Top padding clears the desktop nav pill (top-center
                          // overlay) now that Home no longer mounts GlassHeader.
                          padding: const EdgeInsets.fromLTRB(16, 64, 8, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              hero,
                              if (gpsCard != null) ...[
                                const SizedBox(height: 11),
                                gpsCard,
                              ],
                              if (noteSection != null) ...[
                                const SizedBox(height: 11),
                                noteSection,
                              ],
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(8, 64, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [statsSection, ?editWidgetsLink],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Campanella + avatar in alto a destra (in mobile vivono
                  // nell'header dell'hero).
                  Positioned(
                    top: 14,
                    right: 16,
                    child: HomeHeaderActions(
                      photoUrl: firebaseUser?.photoURL,
                      firstName: displayName.split(' ').first,
                      onHeroGradient: false,
                    ),
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              children: [
                hero,
                const SizedBox(height: 11),
                ?gpsCard,
                if (noteSection != null) ...[
                  noteSection,
                  const SizedBox(height: 11),
                ],
                statsSection,
                ?editWidgetsLink,
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Empty state per widget che dipendono dai dati portale ───────────────────

class _PortaleMissingCard extends StatelessWidget {
  final String title;
  final String pose;
  final Color accent;
  final VoidCallback onCta;

  const _PortaleMissingCard({
    required this.title,
    required this.pose,
    required this.accent,
    required this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeWidgetHeader(pose: pose, title: title, accent: accent),
          HomeWidgetEmpty(
            message: AppStrings.portaleDataMissing,
            ctaLabel: AppStrings.portaleDataMissingCta,
            onCta: onCta,
          ),
        ],
      ),
    );
  }
}

// ── CTA "aggiungi widget" (Home vuota, default nuovi account) ────────────────

class _AddWidgetsCta extends ConsumerWidget {
  final Map<String, dynamic> profileData;

  const _AddWidgetsCta({required this.profileData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : AppColors.neutral600;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeWidgetHeader(
            pose: ChigioQuotes.ciao,
            title: AppStrings.addWidgetsCtaTitle,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.addWidgetsCtaBody,
            style: TextStyle(fontSize: 12, color: textSub),
          ),
          const SizedBox(height: 12),
          GlassBtn(
            label: AppStrings.addWidgetsCtaBtn,
            icon: const Icon(Icons.dashboard_customize_rounded, size: 16),
            onPressed: () => showHomeWidgetsPanel(context, ref, profileData),
          ),
        ],
      ),
    );
  }
}

// ── Widget in evidenza (★ dalle impostazioni) ───────────────────────────────
// «Aurora»: base blu notte con blob luminosi blu/verde/viola che derivano
// lentamente sotto un velo glass + riflesso periodico, bordo conico
// iridescente rotante e alone scuro. La card interna renderizza la propria
// variante dark (tema forzato, superfici translucide) come in precedenza.
Widget _featureWrap(bool featured, Widget child) =>
    featured ? _FeaturedWidget(child: child) : child;

class _FeaturedWidget extends StatefulWidget {
  final Widget child;

  const _FeaturedWidget({required this.child});

  @override
  State<_FeaturedWidget> createState() => _FeaturedWidgetState();
}

class _FeaturedWidgetState extends State<_FeaturedWidget>
    with SingleTickerProviderStateMixin {
  // Ciclo unico: blob 1 oscillazione, shine 2 passaggi, anello 2 giri.
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion: aurora statica.
    if (MediaQuery.of(context).disableAnimations) {
      _t.stop();
    } else if (!_t.isAnimating) {
      _t.repeat();
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue900.withValues(alpha: 0.50),
            blurRadius: 34,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: CustomPaint(
          painter: _AuroraPainter(_t),
          foregroundPainter: _FeaturedRingPainter(_t),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Theme(data: AppTheme.darkTheme, child: widget.child),
          ),
        ),
      ),
    );
  }
}

/// Sfondo aurora: base notte, 3 blob radiali in deriva, velo glass, shine.
class _AuroraPainter extends CustomPainter {
  final Animation<double> t;

  _AuroraPainter(this.t) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xFF0A1226));

    void blob(Color color, Offset center, double radius, double alpha) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    // Blob morbidi via falloff radiale (niente ImageFilter.blur: più leggero).
    final a = t.value * 2 * math.pi;
    blob(
      AppColors.blue600,
      Offset(size.width * 0.18 + 24 * math.sin(a), 14 * math.cos(a)),
      120,
      0.55,
    );
    blob(
      AppColors.green600,
      Offset(
        size.width * 0.88 - 20 * math.sin(a),
        size.height - 12 * math.cos(a),
      ),
      100,
      0.50,
    );
    blob(
      AppColors.purple600,
      Offset(size.width * 0.62 + 16 * math.cos(a), 10 * math.sin(a) - 10),
      85,
      0.40,
    );

    // Velo glass.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.07),
            Colors.white.withValues(alpha: 0.02),
          ],
        ).createShader(rect),
    );

    // Shine: striscia di luce che attraversa la card 2 volte per ciclo (~6s).
    final x = size.width * (-0.6 + 2.2 * ((t.value * 2) % 1));
    final shineRect = Rect.fromLTWH(x, 0, size.width * 0.45, size.height);
    canvas.drawRect(
      shineRect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(shineRect),
    );
  }

  @override
  bool shouldRepaint(_AuroraPainter oldDelegate) => false;
}

/// Bordo conico iridescente rotante (2 giri per ciclo, ~6s/giro).
class _FeaturedRingPainter extends CustomPainter {
  final Animation<double> turn;

  _FeaturedRingPainter(this.turn) : super(repaint: turn);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = SweepGradient(
        transform: GradientRotation(turn.value * 4 * math.pi),
        colors: const [
          AppColors.blue400,
          AppColors.green500,
          AppColors.purple600,
          AppColors.blue600,
          AppColors.blue400,
        ],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(25)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_FeaturedRingPainter oldDelegate) => false;
}

// ── Maggior Presenza widget ────────────────────────────────────────────────

class _MaggiorPresenzaCard extends ConsumerStatefulWidget {
  const _MaggiorPresenzaCard();

  @override
  ConsumerState<_MaggiorPresenzaCard> createState() =>
      _MaggiorPresenzaCardState();
}

class _MaggiorPresenzaCardState extends ConsumerState<_MaggiorPresenzaCard> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _prevMonth() => setState(() {
    if (_month == 1) {
      _month = 12;
      _year--;
    } else {
      _month--;
    }
  });

  void _nextMonth() => setState(() {
    if (_month == 12) {
      _month = 1;
      _year++;
    } else {
      _month++;
    }
  });

  static String _hm(int mins) {
    if (mins == 0) return '0h';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  static const _monthsShort = AppStrings.monthsShort;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppColors.neutral600;

    final profileData = ref.watch(userProfileStreamProvider).asData?.value;

    // Resolve the caps effective for the SELECTED month from the cap-period
    // history (ADR-0009); fall back to the flat profile fields when no period
    // covers the month (pre-migration users).
    final periods =
        ref.watch(capPeriodsStreamProvider).asData?.value ?? const [];
    final monthKey = '$_year-${_month.toString().padLeft(2, '0')}';
    final caps = capsForMonth(periods, monthKey);
    final art9CapMins =
        (caps?.monthlyArt9Hours ??
            (profileData?['monthlyArt9Hours'] as int? ?? 0)) *
        60;
    final sliCapMins =
        (caps?.monthlySliHours ??
            (profileData?['monthlySliHours'] as int? ?? 0)) *
        60;
    final sboCapMins =
        (caps?.monthlySboHours ??
            (profileData?['monthlySboHours'] as int? ?? 0)) *
        60;

    final entries =
        ref
            .watch(monthlyTimesheetsProvider((year: _year, month: _month)))
            .asData
            ?.value ??
        [];

    final totalOtMins = entries.fold<int>(
      0,
      (s, e) => s + (e.extraMins > 0 ? e.extraMins : 0),
    );

    final art9Alloc = totalOtMins.clamp(0, art9CapMins);
    final sliAlloc = (totalOtMins - art9CapMins).clamp(0, sliCapMins);
    final sboAlloc = (totalOtMins - art9CapMins - sliCapMins).clamp(
      0,
      sboCapMins,
    );
    final opeAlloc = (totalOtMins - art9CapMins - sliCapMins - sboCapMins)
        .clamp(0, 99999);
    final totalCap = art9CapMins + sliCapMins + sboCapMins;

    if (totalOtMins == 0 && totalCap == 0) return const SizedBox.shrink();

    final hasOpe = opeAlloc > 0;
    final pct = totalCap > 0
        ? (totalOtMins / totalCap * 100).clamp(0, 999).round()
        : null;

    final now = DateTime.now();
    final isCurrentMonth = _year == now.year && _month == now.month;
    final monthLabel = '${_monthsShort[_month - 1]} $_year';

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      // Tier compatto (GlassTile): widget mono-metrica, come BancaOreTile
      // e FavoriteColleaguesCard — gerarchia a 3 livelli nella Home.
      child: GlassTile(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row (uniforme, con month navigator) ─────────────
            Row(
              children: [
                Expanded(
                  child: HomeWidgetHeader(
                    pose: ChigioQuotes.corre,
                    title: AppStrings.widgetTitleMaggiorPresenza,
                    subtitleWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppTappable(
                          onTap: _prevMonth,
                          child: Icon(
                            Icons.chevron_left_rounded,
                            size: 16,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : AppColors.neutral400,
                          ),
                        ),
                        Text(
                          monthLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isCurrentMonth
                                ? AppColors.blue600.withValues(alpha: 0.8)
                                : textSub,
                          ),
                        ),
                        AppTappable(
                          onTap: _nextMonth,
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : AppColors.neutral400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  _hm(totalOtMins),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: hasOpe ? AppColors.red700 : AppColors.blue600,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (hasOpe ? AppColors.red700 : AppColors.blue600)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    hasOpe ? '+${_hm(opeAlloc)} OPE' : '${pct ?? 0}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: hasOpe ? AppColors.red700 : AppColors.blue600,
                    ),
                  ),
                ),
              ],
            ),

            // ── Segmented bar with threshold markers ─────────────────────
            if (totalCap > 0) ...[
              const SizedBox(height: 10),
              _SegmentedBarThresholds(
                art9Cap: art9CapMins,
                art9Alloc: art9Alloc,
                sliCap: sliCapMins,
                sliAlloc: sliAlloc,
                sboCap: sboCapMins,
                sboAlloc: sboAlloc,
                totalCap: totalCap,
                isDark: isDark,
              ),
              const SizedBox(height: 4),
              // Proportional labels aligned to segments
              Row(
                children: [
                  if (art9CapMins > 0)
                    Flexible(
                      flex: art9CapMins,
                      child: Center(
                        child: Text(
                          AppStrings.art9Label,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue600,
                          ),
                        ),
                      ),
                    ),
                  if (sliCapMins > 0)
                    Flexible(
                      flex: sliCapMins,
                      child: Center(
                        child: Text(
                          AppStrings.sliLabel,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.green600,
                          ),
                        ),
                      ),
                    ),
                  if (sboCapMins > 0)
                    Flexible(
                      flex: sboCapMins,
                      child: Center(
                        child: Text(
                          AppStrings.sboLabel,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.orange500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],

            // ── Breakdown chips ──────────────────────────────────────────
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (art9CapMins > 0)
                  _PresenzaChip(
                    label: AppStrings.art9Label,
                    value: _hm(art9Alloc),
                    cap: _hm(art9CapMins),
                    color: AppColors.blue600,
                    isDark: isDark,
                  ),
                if (sliCapMins > 0)
                  _PresenzaChip(
                    label: AppStrings.sliLabel,
                    value: _hm(sliAlloc),
                    cap: _hm(sliCapMins),
                    color: AppColors.green600,
                    isDark: isDark,
                  ),
                if (sboCapMins > 0)
                  _PresenzaChip(
                    label: AppStrings.sboLabel,
                    value: _hm(sboAlloc),
                    cap: _hm(sboCapMins),
                    color: AppColors.orange500,
                    isDark: isDark,
                  ),
                if (hasOpe || totalCap > 0)
                  _PresenzaChip(
                    label: AppStrings.opeLabel,
                    value: _hm(opeAlloc),
                    cap: null,
                    color: hasOpe ? AppColors.red700 : AppColors.neutral400,
                    isDark: isDark,
                  ),
                if (!hasOpe && totalCap == 0)
                  Text(
                    _hm(totalOtMins),
                    style: TextStyle(fontSize: 11, color: textSub),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Segmented bar with threshold dividers ─────────────────────────────────────

class _SegmentedBarThresholds extends StatelessWidget {
  final int art9Cap, art9Alloc, sliCap, sliAlloc, sboCap, sboAlloc, totalCap;
  final bool isDark;

  const _SegmentedBarThresholds({
    required this.art9Cap,
    required this.art9Alloc,
    required this.sliCap,
    required this.sliAlloc,
    required this.sboCap,
    required this.sboAlloc,
    required this.totalCap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final emptyColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.07);
    final dividerColor = isDark
        ? Colors.black.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.8);

    final segments = [
      (cap: art9Cap, alloc: art9Alloc, color: AppColors.blue600),
      (cap: sliCap, alloc: sliAlloc, color: AppColors.green600),
      (cap: sboCap, alloc: sboAlloc, color: AppColors.orange500),
    ].where((s) => s.cap > 0).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 12,
        child: Row(
          children: [
            for (int i = 0; i < segments.length; i++) ...[
              Flexible(
                flex: (segments[i].cap * 1000 ~/ totalCap),
                child: Stack(
                  children: [
                    // Filled + empty portions
                    Row(
                      children: [
                        if (segments[i].alloc > 0)
                          Flexible(
                            flex: (segments[i].alloc * 1000 ~/ segments[i].cap),
                            child: Container(color: segments[i].color),
                          ),
                        if (segments[i].alloc < segments[i].cap)
                          Flexible(
                            flex:
                                ((segments[i].cap - segments[i].alloc) *
                                1000 ~/
                                segments[i].cap),
                            child: Container(color: emptyColor),
                          ),
                      ],
                    ),
                    // Threshold divider on right edge (except last segment)
                    if (i < segments.length - 1)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(width: 2, color: dividerColor),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PresenzaChip extends StatelessWidget {
  final String label, value;
  final String? cap;
  final Color color;
  final bool isDark;

  const _PresenzaChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    this.cap,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppColors.neutral600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: textMain,
            ),
          ),
          if (cap != null) ...[
            Text(' / $cap', style: TextStyle(fontSize: 11, color: textSub)),
          ],
        ],
      ),
    );
  }
}

// ── Note attività ──────────────────────────────────────────────────────

class _NoteSection extends ConsumerStatefulWidget {
  final String dateId;
  final String? initialNote;

  const _NoteSection({required this.dateId, this.initialNote});

  @override
  ConsumerState<_NoteSection> createState() => _NoteSectionState();
}

class _NoteSectionState extends ConsumerState<_NoteSection> {
  late TextEditingController _ctrl;
  late String _originalText;
  bool _saving = false;
  bool _saved = false;
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _originalText = widget.initialNote ?? '';
    _ctrl = TextEditingController(text: _originalText);
    _expanded = widget.initialNote?.isNotEmpty == true;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _dirty => _ctrl.text != _originalText;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saved = false;
    });
    try {
      await ref
          .read(timesheetRepositoryProvider)
          .saveNote(widget.dateId, _ctrl.text);
      if (mounted) {
        setState(() {
          _saved = true;
          _originalText = _ctrl.text;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppColors.neutral600;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTappable(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                const Text('📝', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  AppStrings.noteLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textMain,
                  ),
                ),
                const Spacer(),
                if (_saved && _expanded)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      AppStrings.saved,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.green600,
                      ),
                    ),
                  ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.add,
                  size: 18,
                  color: textSub,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.7),
                ),
              ),
              child: TextField(
                controller: _ctrl,
                maxLines: 3,
                maxLength: 500,
                scrollPadding: const EdgeInsets.only(bottom: 220),
                style: TextStyle(fontSize: 13, color: textMain),
                decoration: InputDecoration(
                  hintText: AppStrings.notePlaceholder,
                  hintStyle: TextStyle(fontSize: 13, color: textSub),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                  counterText: '',
                ),
                onChanged: (_) => setState(() => _saved = false),
              ),
            ),
            if (_dirty || _saving) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: AppTappable(
                  onTap: _saving ? null : _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: _saving
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xE60055A5), Color(0xF2003D8F)],
                            ),
                      color: _saving
                          ? (isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.06))
                          : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.blue400,
                            ),
                          )
                        : const Text(
                            AppStrings.save,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ], // end if (_dirty || _saving)
          ], // end if (_expanded)
        ],
      ),
    );
  }
}

// ── Tabella orari bottom sheet ─────────────────────────────────────────────

// ── GPS prompt card ──────────────────────────────────────────────────────────

class _GpsPromptCard extends StatefulWidget {
  final Map<String, dynamic>? profileData;
  final bool isDark;
  final VoidCallback onClockIn;

  const _GpsPromptCard({
    required this.profileData,
    required this.isDark,
    required this.onClockIn,
  });

  @override
  State<_GpsPromptCard> createState() => _GpsPromptCardState();
}

class _GpsPromptCardState extends State<_GpsPromptCard> {
  bool _checking = false;
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.profileData;
    final gpsEnabled = data?['gpsAutoClockIn'] as bool? ?? false;
    final officeLat = (data?['officeLat'] as num?)?.toDouble();
    final officeLng = (data?['officeLng'] as num?)?.toDouble();

    // Show only between 06:00–11:00, GPS enabled, office coords set, not dismissed
    final hour = DateTime.now().hour;
    if (!gpsEnabled ||
        officeLat == null ||
        officeLng == null ||
        _dismissed ||
        hour < 6 ||
        hour >= 11) {
      return const SizedBox.shrink();
    }

    final radius =
        (data?['officeRadiusM'] as num?)?.toDouble() ??
        GeofencingService.defaultRadiusM;
    final isDark = widget.isDark;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppColors.neutral600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.blue600.withValues(alpha: isDark ? 0.10 : 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.blue600.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Text('📍', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppStrings.gpsAutoClockInDialog,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppColors.neutral900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_checking)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.blue600,
                ),
              )
            else ...[
              AppTappable(
                onTap: () async {
                  final ctx = context;
                  setState(() => _checking = true);
                  final result = await GeofencingService.checkInOffice(
                    officeLat: officeLat,
                    officeLng: officeLng,
                    radiusM: radius,
                  );
                  if (!ctx.mounted) return;
                  setState(() => _checking = false);
                  if (result == GeofenceResult.inside) {
                    final ok = await showDialog<bool>(
                      context: ctx,
                      builder: (_) => AlertDialog(
                        title: const Text(AppStrings.gpsAutoClockInDialog),
                        content: const Text(AppStrings.gpsAutoClockInBody),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text(AppStrings.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(AppStrings.clockIn),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) widget.onClockIn();
                  } else if (result == GeofenceResult.permissionDenied) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text(AppStrings.gpsPermissionDenied),
                        ),
                      );
                    }
                  }
                  setState(() => _dismissed = true);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blue600,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    AppStrings.gpsSetFromHere,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              AppTappable(
                onTap: () => setState(() => _dismissed = true),
                child: Icon(Icons.close_rounded, size: 16, color: textSub),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Monthly OT threshold alert banner ────────────────────────────────────────

class _OtAlertBanner extends StatelessWidget {
  final int thresholdHours;
  final int totalHours;

  const _OtAlertBanner({
    required this.thresholdHours,
    required this.totalHours,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_rounded,
            size: 16,
            color: AppColors.orange500,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.otAlertMessage(thresholdHours, totalHours),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.orange500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Compact custom counters strip on Home ────────────────────────────────────

class _HomeCountersRow extends ConsumerWidget {
  const _HomeCountersRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counters = ref.watch(customCountersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HomeWidgetHeader(
            pose: ChigioQuotes.calcolatrice,
            title: AppStrings.widgetTitleCounters,
          ),
          const SizedBox(height: 10),
          if (counters.isEmpty)
            HomeWidgetEmpty(
              message: AppStrings.countersEmpty,
              ctaLabel: AppStrings.countersEmptyCta,
              onCta: () => showCounterEditSheet(context, ref),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: counters.map((c) {
                  final color =
                      CustomCounter.palette[c.colorIndex.clamp(
                        0,
                        CustomCounter.palette.length - 1,
                      )];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onLongPress: () =>
                          showCounterEditSheet(context, ref, editing: c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: color.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${c.value}${c.unit.isNotEmpty ? ' ${c.unit}' : ''}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: color,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              c.label,
                              style: TextStyle(
                                fontSize: 10,
                                color: color.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
