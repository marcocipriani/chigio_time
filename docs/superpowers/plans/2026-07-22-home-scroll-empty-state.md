# Home Scroll Performance and Empty State Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the mobile Web Home lazy and smooth during initial scroll and tab returns, isolate one-second timer rebuilds, reduce only the costly Web effects, and present new users with the approved Chigio add-widget empty state.

**Architecture:** The mobile dashboard becomes a `CustomScrollView` whose secondary Home widgets are built by `SliverList.builder`; desktop keeps the current two-column composition. A minute-stable timer selector feeds the large hero while one small pause counter remains second-accurate. Shared skeletons use one animation, the horizontal Web navbar does not blur moving content, and a pure visibility model switches between the large zero-widget card and the compact one-or-more-widget link.

**Tech Stack:** Flutter 3, Dart 3.10+, Riverpod 3, slivers, `flutter_test`, existing Chigio/Glass components, PNG asset generated during the approved brainstorming session.

## Global Constraints

- Mobile Web is the priority path; desktop layout remains visually unchanged.
- Home widget order, hidden IDs, featured IDs, Firestore data rules, and navigation destinations remain unchanged.
- Secondary widgets are not mounted at the first pump when far outside the viewport.
- Existing Home data stays visible during refresh; global skeleton is only for profile/month data with no usable value.
- One shared animation drives each skeleton group and respects `MediaQuery.disableAnimations`.
- The large `TimbraturaHero` rebuilds no more than once per minute for clock-only changes; only the pause duration text updates each second.
- The slide affordance nudges once per relevant phase, never in a permanent loop.
- Only horizontal Flutter Web navigation loses `BackdropFilter`; native and desktop vertical glass may keep it.
- Graphics reductions are limited to Home hero/featured shadows and the mobile Web navbar.
- Zero additional widgets: large Chigio CTA. One or more additional widgets: compact `Modifica widget` link.
- Exact copy: `Costruisci la tua Home`; `Scegli i widget che ti servono ogni giorno. Puoi cambiarli quando vuoi.`; `Aggiungi widget`.
- Selected mascot: Chigio holding one white rounded tile with a blue `+`, stored as `assets/images/chigio-aggiungi-widget.png`.
- This plan does not authorize a production or preview deployment; physical-device smoke starts only after the build is reachable through a separately authorized deployment or device connection.
- Existing untracked files `.impeccable/`, `.superpowers/brainstorm/`, `AGENTS.md`, and `Appendice A-elenco strutture.pdf` are not staged.
- Every task that changes `lib/` updates `docs/funzionalita/dashboard.md` or the relevant wiki page and `docs/CHANGELOG.md` in the same commit.

## File Structure

- Create `lib/features/dashboard/presentation/home_mobile_scroll_view.dart`: reusable sliver composition and stable `PageStorageKey`.
- Create `lib/features/dashboard/presentation/home_widget_visibility.dart`: pure order/visibility result for zero, one, or many visible widgets.
- Create `lib/features/dashboard/widgets/home_loading_skeleton.dart`: structural Home skeleton built from shared static shapes.
- Create `lib/features/dashboard/widgets/add_widgets_empty_state.dart`: approved Chigio card, semantics, copy, and callback.
- Modify `lib/features/dashboard/presentation/dashboard_screen.dart`: split cheap leading sections from lazy widget builders; use visibility result and the new skeleton/empty state.
- Modify `lib/shared/widgets/skeleton_tile.dart`: one pulse controller per group instead of one per tile.
- Modify `lib/features/dashboard/presentation/timer_provider.dart`: minute-stable `TimerHeroSnapshot` selector value.
- Modify `lib/features/dashboard/widgets/timbratura_hero.dart`: minute-stable main consumer, isolated live-pause counter, one-shot nudge, and reduced moving shadow.
- Modify `lib/shared/widgets/floating_nav.dart`: conditional Web-mobile blur and reduced horizontal shadow.
- Modify `lib/core/constants/app_strings.dart`: approved empty-state copy.
- Create `assets/images/chigio-aggiungi-widget.png`: optimized transparent asset from the selected generated pose.
- Create `test/widget/home_mobile_scroll_view_test.dart`: lazy construction and scroll restoration.
- Create `test/widget/home_loading_skeleton_test.dart`: structural geometry and one shared fade.
- Create `test/features/timer_hero_snapshot_test.dart`: same-minute equality and second/minute separation.
- Modify `test/widget/floating_nav_test.dart`: blur-off/blur-on rendering contract.
- Modify `test/features/ux_review_contract_test.dart`: one-shot nudge and bounded visual-effects contract.
- Create `test/widget/add_widgets_empty_state_test.dart`: exact copy, image, semantics, full-width CTA, and callback.
- Create `test/features/home_widget_visibility_test.dart`: zero/one/many behavior and new-account default contract.
- Modify `docs/funzionalita/dashboard.md`, `docs/processi/testing.md`, and `docs/CHANGELOG.md`.

---

### Task 1: Shared structural skeleton with one animation

**Files:**
- Modify: `lib/shared/widgets/skeleton_tile.dart:1-115`
- Create: `lib/features/dashboard/widgets/home_loading_skeleton.dart`
- Modify: `lib/features/dashboard/presentation/dashboard_screen.dart:54-92`
- Test: `test/widget/home_loading_skeleton_test.dart`
- Modify: `docs/funzionalita/dashboard.md`
- Modify: `docs/CHANGELOG.md`

**Interfaces:**
- Produces: `SkeletonPulse`, stateless `SkeletonTile`, unchanged `SkeletonList` constructor, and `HomeLoadingSkeleton`.
- Consumes: `MediaQuery.disableAnimations`, current theme brightness, and the dashboard's existing no-value loading branch.

- [ ] **Step 1: Write the failing skeleton widget tests**

Create `test/widget/home_loading_skeleton_test.dart`:

```dart
import 'package:chigio_time/features/dashboard/widgets/home_loading_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('matches the first Home viewport with one shared pulse', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomeLoadingSkeleton())),
    );

    expect(find.byKey(const Key('home-skeleton-hero')), findsOneWidget);
    expect(find.byKey(const Key('home-skeleton-intro')), findsOneWidget);
    expect(find.byKey(const Key('home-skeleton-card')), findsNWidgets(2));
    expect(find.byType(FadeTransition), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('reduced motion keeps the skeleton static', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: HomeLoadingSkeleton()),
        ),
      ),
    );
    final fade = tester.widget<FadeTransition>(find.byType(FadeTransition));
    final before = fade.opacity.value;
    await tester.pump(const Duration(seconds: 2));
    expect(fade.opacity.value, before);
  });
}
```

- [ ] **Step 2: Run the skeleton test and verify RED**

Run:

```bash
flutter test test/widget/home_loading_skeleton_test.dart
```

Expected: compilation fails because `HomeLoadingSkeleton` does not exist.

- [ ] **Step 3: Refactor skeleton primitives to one controller per group**

In `skeleton_tile.dart`, make `SkeletonTile` a stateless shape with its current color/radius logic. Add:

```dart
class SkeletonTile extends StatelessWidget {
  final double height;
  final double radius;

  const SkeletonTile({super.key, this.height = 72, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFF002878).withValues(alpha: 0.06);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class SkeletonPulse extends StatefulWidget {
  final Widget child;

  const SkeletonPulse({super.key, required this.child});

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final Animation<double> _opacity = Tween<double>(
    begin: 0.55,
    end: 1,
  ).animate(_controller);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0.55;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: widget.child,
  );
}
```

Keep `SkeletonList`'s public fields unchanged but wrap its entire `Column` in one `SkeletonPulse`; do not wrap individual tiles.

```dart
return SkeletonPulse(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var index = 0; index < count; index++) ...[
        if (index > 0) SizedBox(height: gap),
        SkeletonTile(height: height),
      ],
    ],
  ),
);
```

- [ ] **Step 4: Implement the structural Home skeleton**

Create `home_loading_skeleton.dart`. Its `SafeArea` content is a `SingleChildScrollView` with `Padding(EdgeInsets.fromLTRB(16, 12, 16, 96))`, one `SkeletonPulse`, and these exact shapes:

```dart
const SkeletonTile(
  key: Key('home-skeleton-hero'),
  height: 300,
  radius: 32,
),
const SizedBox(height: 11),
const SkeletonTile(
  key: Key('home-skeleton-intro'),
  height: 84,
  radius: 22,
),
const SizedBox(height: 11),
const SkeletonTile(
  key: Key('home-skeleton-card'),
  height: 156,
  radius: 28,
),
const SizedBox(height: 11),
const SkeletonTile(
  key: Key('home-skeleton-card'),
  height: 124,
  radius: 28,
),
```

Replace the dashboard's `SkeletonList(count: 4, height: 112)` branch with `const HomeLoadingSkeleton()` while keeping the existing “loading only when `!hasValue`” condition.

- [ ] **Step 5: Run tests and verify GREEN**

Run:

```bash
dart format lib/shared/widgets/skeleton_tile.dart lib/features/dashboard/widgets/home_loading_skeleton.dart lib/features/dashboard/presentation/dashboard_screen.dart test/widget/home_loading_skeleton_test.dart
flutter test test/widget/home_loading_skeleton_test.dart
```

Expected: both skeleton tests pass; the Home test finds one `FadeTransition` for all four shapes.

- [ ] **Step 6: Update docs and commit the skeleton**

Update the dashboard loading section to distinguish global profile/month skeleton from per-widget loading and state that existing values remain visible during refresh. Add the dated entry to `docs/CHANGELOG.md`.

Run:

```bash
git add lib/shared/widgets/skeleton_tile.dart lib/features/dashboard/widgets/home_loading_skeleton.dart lib/features/dashboard/presentation/dashboard_screen.dart test/widget/home_loading_skeleton_test.dart docs/funzionalita/dashboard.md docs/CHANGELOG.md
git diff --cached --check
git commit -m "perf: use one structural Home skeleton"
```

Expected: one independently green skeleton commit.

---

### Task 2: Lazy mobile Home slivers and scroll restoration

**Files:**
- Create: `lib/features/dashboard/presentation/home_mobile_scroll_view.dart`
- Modify: `lib/features/dashboard/presentation/dashboard_screen.dart:94-465`
- Test: `test/widget/home_mobile_scroll_view_test.dart`
- Modify: `docs/funzionalita/dashboard.md`
- Modify: `docs/processi/testing.md`
- Modify: `docs/CHANGELOG.md`

**Interfaces:**
- Produces: `HomeMobileScrollView({leadingChildren, widgetCount, widgetBuilder, footer})` with `PageStorageKey<String>('dashboard-home-scroll')`.
- Consumes: a list of cheap first-viewport sections and an `IndexedWidgetBuilder` that creates secondary widget cards only when their sliver child is requested.

- [ ] **Step 1: Write failing lazy-build and restoration tests**

Create `test/widget/home_mobile_scroll_view_test.dart`:

```dart
import 'package:chigio_time/features/dashboard/presentation/home_mobile_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> setPhone(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 700);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
  }

  testWidgets('does not build a secondary widget far outside the viewport', (
    tester,
  ) async {
    await setPhone(tester);
    final built = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeMobileScrollView(
            leadingChildren: const [SizedBox(height: 300)],
            widgetCount: 20,
            widgetBuilder: (_, index) {
              built.add(index);
              return SizedBox(height: 260, child: Text('widget-$index'));
            },
          ),
        ),
      ),
    );

    expect(built, isNot(contains(19)));
    expect(find.text('widget-19'), findsNothing);

    await tester.drag(
      find.byKey(const Key('dashboard-home-scroll')),
      const Offset(0, -5000),
    );
    await tester.pumpAndSettle();
    expect(built.length, greaterThan(3));
  });

  testWidgets('restores scroll offset after the Home scrollable is remounted', (
    tester,
  ) async {
    await setPhone(tester);
    final bucket = PageStorageBucket();

    Widget home() => MaterialApp(
      home: PageStorage(
        bucket: bucket,
        child: Scaffold(
          body: HomeMobileScrollView(
            leadingChildren: const [SizedBox(height: 300)],
            widgetCount: 12,
            widgetBuilder: (_, index) => SizedBox(
              height: 240,
              child: Text('widget-$index'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(home());
    await tester.drag(
      find.byKey(const Key('dashboard-home-scroll')),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    final before = tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
    expect(before, greaterThan(0));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(home());
    await tester.pump();
    final after = tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
    expect(after, closeTo(before, 1));
  });
}
```

- [ ] **Step 2: Run the sliver tests and verify RED**

Run:

```bash
flutter test test/widget/home_mobile_scroll_view_test.dart
```

Expected: compilation fails because `HomeMobileScrollView` does not exist.

- [ ] **Step 3: Implement the focused mobile sliver component**

Create `home_mobile_scroll_view.dart`:

```dart
class HomeMobileScrollView extends StatelessWidget {
  final List<Widget> leadingChildren;
  final int widgetCount;
  final IndexedWidgetBuilder widgetBuilder;
  final Widget? footer;

  const HomeMobileScrollView({
    super.key,
    required this.leadingChildren,
    required this.widgetCount,
    required this.widgetBuilder,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey<String>('dashboard-home-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverList.list(
            children: [
              for (final child in leadingChildren)
                Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: child,
                ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.builder(
            itemCount: widgetCount,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: widgetBuilder(context, index),
            ),
          ),
        ),
        if (footer != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverToBoxAdapter(child: footer),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 88)),
      ],
    );
  }
}
```

Do not set `cacheExtent`; retain Flutter's default repaint boundaries.

- [ ] **Step 4: Convert only the mobile dashboard path to lazy builders**

In `dashboard_screen.dart`, compute:

```dart
final visibleWidgetIds = widgetOrder
    .where((id) => !hiddenWidgets.contains(id))
    .toList(growable: false);
```

Extract the existing switch into a local `Widget buildHomeWidget(String id)` that returns exactly one widget for every ID:

```dart
Widget featured(String id, Widget child) =>
    _featureWrap(featuredWidgets.contains(id), child);

Widget buildHomeWidget(String id) => switch (id) {
  'favorites' => featured(id, const FavoriteColleaguesCard()),
  'maggiorPresenza' => featured(id, const _MaggiorPresenzaCard()),
  'counters' => featured(id, const _HomeCountersRow()),
  'bancaOre' => featured(
      id,
      totData != null
          ? BancaOreTile(data: totData)
          : _PortaleMissingCard(
              title: AppStrings.bankHoursUpper,
              pose: ChigioQuotes.festeggia,
              accent: AppColors.green600,
              onCta: () => showPortaleEdit(context, ref, profileData ?? {}),
            ),
    ),
  'totalizzatori' => totData != null
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            featured(
              id,
              TotalizzatoriSection(
                data: totData,
                consumption: absenceConsumption,
                onEdit: () => showPortaleEdit(context, ref, profileData ?? {}),
                onChipEdit: (updates) async {
                  final map = Map<String, dynamic>.from(
                    ref.read(portaleRawProvider) ?? {},
                  )..addAll(updates);
                  await ref.read(profileRepositoryProvider).savePortaleData(map);
                },
              ),
            ),
            const SizedBox(height: 4),
            const CustomCountersSection(),
          ],
        )
      : featured(
          id,
          _PortaleMissingCard(
            title: AppStrings.totalizatori,
            pose: ChigioQuotes.lista,
            accent: AppColors.blue600,
            onCta: () => showPortaleEdit(context, ref, profileData ?? {}),
          ),
        ),
  'routePlanner' => featured(id, const PcmRoutePlannerCard()),
  'orariTable' => featured(id, OrariTableCard(profileData: profileData)),
  'pomodoro' => featured(id, const PomodoroCard()),
  'salary' => featured(id, const SalaryCard()),
  _ => const SizedBox.shrink(),
};
```

Build `leadingChildren` from hero, optional GPS/note, portal alert, and OT alert only:

```dart
final leadingChildren = <Widget>[
  hero,
  ?gpsCard,
  ?noteSection,
  if (totData != null && totData.activeAlerts.isNotEmpty)
    TotAlertBanner(alerts: totData.activeAlerts),
  if (otAlertActive)
    _OtAlertBanner(
      thresholdHours: otAlertThresholdMins ~/ 60,
      totalHours: totalMonthOtMins ~/ 60,
    ),
];

final homeFooter = visibleWidgetIds.isEmpty
    ? _AddWidgetsCta(profileData: profileData ?? const {})
    : visibleWidgetIds.length > 1
    ? editWidgetsLink
    : null;
```

This is the compiling intermediate behavior; Task 5 replaces the footer rule with the approved zero-versus-one-or-more contract. For mobile return:

```dart
return HomeMobileScrollView(
  leadingChildren: leadingChildren,
  widgetCount: visibleWidgetIds.length,
  widgetBuilder: (_, index) => buildHomeWidget(visibleWidgetIds[index]),
  footer: homeFooter,
);
```

For desktop retain both `SingleChildScrollView` columns and build `visibleWidgetIds.map(buildHomeWidget)` eagerly in the right column; desktop rewriting is outside scope. Ensure each alert and widget keeps its current 11 px spacing and that `PomodoroCard` is reached only through the sliver builder on mobile.

- [ ] **Step 5: Run the focused tests and dashboard analysis**

Run:

```bash
dart format lib/features/dashboard/presentation/home_mobile_scroll_view.dart lib/features/dashboard/presentation/dashboard_screen.dart test/widget/home_mobile_scroll_view_test.dart
flutter test test/widget/home_mobile_scroll_view_test.dart
flutter analyze lib/features/dashboard/presentation/dashboard_screen.dart lib/features/dashboard/presentation/home_mobile_scroll_view.dart
```

Expected: lazy and restoration tests pass; analysis is clean; `dashboard_screen.dart` contains `HomeMobileScrollView` and no mobile `ListView` wrapping the full widget `Column`.

- [ ] **Step 6: Update docs and commit lazy rendering**

Document mobile `CustomScrollView`, lazy secondary providers, default `cacheExtent`, desktop unchanged layout, and the new regression test in dashboard/testing pages. Add the dated changelog entry.

Run:

```bash
git add lib/features/dashboard/presentation/home_mobile_scroll_view.dart lib/features/dashboard/presentation/dashboard_screen.dart test/widget/home_mobile_scroll_view_test.dart docs/funzionalita/dashboard.md docs/processi/testing.md docs/CHANGELOG.md
git diff --cached --check
git commit -m "perf: build Home widgets lazily"
```

Expected: one commit that independently proves secondary widgets are not all mounted at first pump.

---

### Task 3: Isolate one-second timer rebuilds

**Files:**
- Modify: `lib/features/dashboard/presentation/timer_provider.dart:15-150`
- Modify: `lib/features/dashboard/widgets/timbratura_hero.dart:90-470`
- Create: `test/features/timer_hero_snapshot_test.dart`
- Modify: `docs/architettura/state-management.md`
- Modify: `docs/funzionalita/dashboard.md`
- Modify: `docs/CHANGELOG.md`

**Interfaces:**
- Produces: `TimerHeroSnapshot(TimerState)`, equality stable within the same minute when no structural field changes, and `formatLivePause(int seconds)`.
- Consumes: unchanged `workTimerProvider`; the notifier may continue ticking once per second for auto-abandon and live pause behavior.

- [ ] **Step 1: Write failing selector-granularity tests**

Create `test/features/timer_hero_snapshot_test.dart`:

```dart
import 'dart:io';

import 'package:chigio_time/features/dashboard/presentation/timer_provider.dart';
import 'package:chigio_time/features/dashboard/widgets/timbratura_hero.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 7, 22, 9);

  TimerState state(DateTime now, {WorkState status = WorkState.working}) =>
      TimerState(
        status: status,
        startTime: start,
        currentTime: now,
        standardWorkMins: 456,
      );

  test('hero snapshot ignores seconds inside one minute', () {
    final first = TimerHeroSnapshot(state(DateTime(2026, 7, 22, 9, 15, 1)));
    final second = TimerHeroSnapshot(state(DateTime(2026, 7, 22, 9, 15, 59)));
    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('hero snapshot changes at the next minute or structural transition', () {
    final base = TimerHeroSnapshot(state(DateTime(2026, 7, 22, 9, 15, 59)));
    final nextMinute = TimerHeroSnapshot(
      state(DateTime(2026, 7, 22, 9, 16)),
    );
    final paused = TimerHeroSnapshot(
      state(DateTime(2026, 7, 22, 9, 15, 59), status: WorkState.paused),
    );
    expect(base, isNot(nextMinute));
    expect(base, isNot(paused));
  });

  test('live pause formatter retains second precision', () {
    expect(formatLivePause(5), '00:05');
    expect(formatLivePause(65), '01:05');
    expect(formatLivePause(3661), '01:01:01');
  });

  test('hero wiring selects the minute snapshot and isolates pause seconds', () {
    final source = File(
      'lib/features/dashboard/widgets/timbratura_hero.dart',
    ).readAsStringSync();
    expect(source, contains('TimerHeroSnapshot(value)'));
    expect(source, contains("key: const Key('live-pause-duration')"));
    expect(source, isNot(contains('final state = ref.watch(workTimerProvider);')));
  });
}
```

- [ ] **Step 2: Run the timer-granularity test and verify RED**

Run:

```bash
flutter test test/features/timer_hero_snapshot_test.dart
```

Expected: compilation fails because `TimerHeroSnapshot` and `formatLivePause` do not exist.

- [ ] **Step 3: Implement the minute-stable selector value**

Add to `timer_provider.dart` after `TimerState`:

```dart
class TimerHeroSnapshot {
  final TimerState state;

  const TimerHeroSnapshot(this.state);

  int get _minuteEpoch =>
      state.currentTime.millisecondsSinceEpoch ~/ Duration.millisecondsPerMinute;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimerHeroSnapshot &&
        other.state.status == state.status &&
        other.state.startTime == state.startTime &&
        other.state.currentPauseStart == state.currentPauseStart &&
        other.state.currentPauseType == state.currentPauseType &&
        other.state.totalStandardPauseMins == state.totalStandardPauseMins &&
        other.state.totalLeavePauseMins == state.totalLeavePauseMins &&
        other.state.totalLunchPauseMins == state.totalLunchPauseMins &&
        other.state.standardWorkMins == state.standardWorkMins &&
        other.state.exitNotifMins == state.exitNotifMins &&
        other.state.lastCompletedShift == state.lastCompletedShift &&
        other._minuteEpoch == _minuteEpoch;
  }

  @override
  int get hashCode => Object.hash(
    state.status,
    state.startTime,
    state.currentPauseStart,
    state.currentPauseType,
    state.totalStandardPauseMins,
    state.totalLeavePauseMins,
    state.totalLunchPauseMins,
    state.standardWorkMins,
    state.exitNotifMins,
    state.lastCompletedShift,
    _minuteEpoch,
  );
}
```

- [ ] **Step 4: Use minute granularity for the hero and seconds only for pause text**

At the start of `_TimbraturaHeroState.build`, replace the broad watch with:

```dart
final state = ref.watch(
  workTimerProvider.select((value) => TimerHeroSnapshot(value)),
).state;
```

Move the existing `_fmtHHMMSS` logic to the public top-level pure function:

```dart
String formatLivePause(int totalSeconds) {
  final seconds = totalSeconds < 0 ? 0 : totalSeconds;
  String two(int value) => value.toString().padLeft(2, '0');
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remainder = seconds % 60;
  return hours > 0
      ? '${two(hours)}:${two(minutes)}:${two(remainder)}'
      : '${two(minutes)}:${two(remainder)}';
}
```

Add the private consumer:

```dart
class _LivePauseDuration extends ConsumerWidget {
  const _LivePauseDuration();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seconds = ref.watch(
      workTimerProvider.select((state) {
        final start = state.currentPauseStart;
        if (state.status != WorkState.paused || start == null) return 0;
        return state.currentTime.difference(start).inSeconds;
      }),
    );
    return Text(
      formatLivePause(seconds),
      key: const Key('live-pause-duration'),
      style: const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: AppColors.orange300,
        letterSpacing: -1.5,
        height: 1,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}
```

Replace only the paused duration `Text` with `const _LivePauseDuration()`. All minute-based worked time, exit, progress, phrase context, and nine-hour calculations continue to use the selected `TimerState` snapshot.

- [ ] **Step 5: Run timer and existing shift tests**

Run:

```bash
dart format lib/features/dashboard/presentation/timer_provider.dart lib/features/dashboard/widgets/timbratura_hero.dart test/features/timer_hero_snapshot_test.dart
flutter test test/features/timer_hero_snapshot_test.dart test/features/timer_state_test.dart
```

Expected: all tests pass; same-minute snapshots compare equal while pause formatting remains second-accurate.

- [ ] **Step 6: Update docs and commit timer isolation**

Document the three granularities: structural actions, minute-stable hero values, and second-only pause text. Add the dated changelog entry.

Run:

```bash
git add lib/features/dashboard/presentation/timer_provider.dart lib/features/dashboard/widgets/timbratura_hero.dart test/features/timer_hero_snapshot_test.dart docs/architettura/state-management.md docs/funzionalita/dashboard.md docs/CHANGELOG.md
git diff --cached --check
git commit -m "perf: isolate live timer rebuilds"
```

Expected: one commit preserving timer behavior while reducing the large hero's clock-only invalidations from 60/minute to 1/minute.

---

### Task 4: Selective Web graphics reduction

**Files:**
- Modify: `lib/shared/widgets/floating_nav.dart:1-430`
- Modify: `lib/features/dashboard/widgets/timbratura_hero.dart:850-1110`
- Modify: `lib/features/dashboard/presentation/dashboard_screen.dart:590-735`
- Modify: `test/widget/floating_nav_test.dart`
- Modify: `test/features/ux_review_contract_test.dart`
- Modify: `docs/funzionalita/dashboard.md`
- Modify: `docs/CHANGELOG.md`

**Interfaces:**
- Produces: optional `FloatingNav.useBackdropFilter` test seam; default is `false` only for horizontal Web and `true` for native or vertical desktop.
- Consumes: `kIsWeb`, `isVertical`, existing glass gradients, reduced-motion helper, and the unchanged tap/navigation APIs.

- [ ] **Step 1: Add failing navbar and one-shot-animation tests**

Append to `test/widget/floating_nav_test.dart`:

```dart
testWidgets('can render the Web-mobile pill without BackdropFilter', (
  tester,
) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: FloatingNav(
          currentIndex: 0,
          onTap: _noop,
          useBackdropFilter: false,
        ),
      ),
    ),
  );
  expect(find.byType(BackdropFilter), findsNothing);
  expect(find.text('Home'), findsOneWidget);
});

testWidgets('retains blur when explicitly enabled', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: FloatingNav(
          currentIndex: 0,
          onTap: _noop,
          useBackdropFilter: true,
        ),
      ),
    ),
  );
  expect(find.byType(BackdropFilter), findsOneWidget);
});
```

Append to `test/features/ux_review_contract_test.dart`:

```dart
test('slide affordance nudges once and does not repeat forever', () {
  final source = File(
    'lib/features/dashboard/widgets/timbratura_hero.dart',
  ).readAsStringSync();
  expect(source, contains('_nudgeCtrl.forward()'));
  expect(source, isNot(contains(')..repeat();')));
});
```

- [ ] **Step 2: Run focused visual-contract tests and verify RED**

Run:

```bash
flutter test test/widget/floating_nav_test.dart test/features/ux_review_contract_test.dart
```

Expected: compilation fails for `useBackdropFilter`; the source contract still finds the permanent repeat.

- [ ] **Step 3: Disable blur only for horizontal Web navigation**

Add `final bool? useBackdropFilter` to `FloatingNav`. Pass this resolved value into `_GlassPill` in both orientations:

```dart
final useBlur = useBackdropFilter ?? (!kIsWeb || isVertical);
```

In `_GlassPill.build`, construct the existing decorated inner `Container` once as `surface`, then return:

```dart
child: useBackdropFilter
    ? BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: surface,
      )
    : surface,
```

Keep the same translucent gradient, border, active pill, semantics, and tap behavior. Reduce only the horizontal outer shadow from blur radius `32`/offset `10` to blur radius `20`/offset `7`; vertical desktop retains the current shadow through an orientation parameter passed to `_GlassPill`.

- [ ] **Step 4: Make the slide nudge one-shot and bound Home shadows**

Initialize `_nudgeCtrl` without a cascade. In `didChangeDependencies`, start it only once and only when animations are enabled:

```dart
bool _nudgeStarted = false;

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (!_nudgeStarted && !MediaQuery.disableAnimationsOf(context)) {
    _nudgeStarted = true;
    _nudgeCtrl.forward();
  }
}
```

The existing `TweenSequence` still produces one invitation and return-to-rest. A newly mounted slide button in another phase gets one new invitation naturally.

Reduce only these moving-path shadows:

- `TimbraturaHero` card: blur `32` → `24`, offset `8` → `6`;
- `_FeaturedWidget` wrapper in `dashboard_screen.dart`: blur `34` → `24`, offset `10` → `7`;
- horizontal Web navbar: values from Step 3.

Do not alter `GlassCard`, native navbar blur, Aurora painters, tap scaling, phase transitions, or functional progress animations.

- [ ] **Step 5: Run visual-contract tests**

Run:

```bash
dart format lib/shared/widgets/floating_nav.dart lib/features/dashboard/widgets/timbratura_hero.dart lib/features/dashboard/presentation/dashboard_screen.dart test/widget/floating_nav_test.dart test/features/ux_review_contract_test.dart
flutter test test/widget/floating_nav_test.dart test/features/ux_review_contract_test.dart
```

Expected: all tests pass; blur can be absent without changing tabs; source contains no cascading `repeat()` on `_nudgeCtrl`.

- [ ] **Step 6: Update docs and commit selective effects**

Document that horizontal Web nav uses a translucent surface without backdrop blur, native/vertical keep glass blur, and the slide invitation runs once. Record the three bounded shadow changes and add the dated changelog entry.

Run:

```bash
git add lib/shared/widgets/floating_nav.dart lib/features/dashboard/widgets/timbratura_hero.dart lib/features/dashboard/presentation/dashboard_screen.dart test/widget/floating_nav_test.dart test/features/ux_review_contract_test.dart docs/funzionalita/dashboard.md docs/CHANGELOG.md
git diff --cached --check
git commit -m "perf: trim costly Home Web effects"
```

Expected: one narrow graphics-performance commit with no general glass redesign.

---

### Task 5: Approved Chigio zero-widget state and compact transition

**Files:**
- Create: `lib/features/dashboard/presentation/home_widget_visibility.dart`
- Create: `lib/features/dashboard/widgets/add_widgets_empty_state.dart`
- Create: `assets/images/chigio-aggiungi-widget.png`
- Modify: `lib/core/constants/app_strings.dart:725-740`
- Modify: `lib/features/dashboard/presentation/dashboard_screen.dart:94-605`
- Create: `test/features/home_widget_visibility_test.dart`
- Create: `test/widget/add_widgets_empty_state_test.dart`
- Modify: `docs/funzionalita/dashboard.md`
- Modify: `docs/CHANGELOG.md`

**Interfaces:**
- Produces: `HomeWidgetVisibility resolveHomeWidgetVisibility({savedOrder, hiddenWidgets})` and `AddWidgetsEmptyState({onAdd})`.
- Consumes: `AppConstants.homeWidgetIds`, `showHomeWidgetsPanel`, the selected generated PNG, and Task 2's `homeFooter` slot.

- [ ] **Step 1: Write failing zero/one/many visibility tests**

Create `test/features/home_widget_visibility_test.dart`:

```dart
import 'dart:io';

import 'package:chigio_time/core/constants/app_constants.dart';
import 'package:chigio_time/features/dashboard/presentation/home_widget_visibility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('zero additional widgets selects the large CTA only', () {
    final result = resolveHomeWidgetVisibility(
      savedOrder: const [],
      hiddenWidgets: AppConstants.homeWidgetIds.toSet(),
    );
    expect(result.visibleIds, isEmpty);
    expect(result.showLargeAddCard, isTrue);
    expect(result.showCompactEditLink, isFalse);
  });

  test('one additional widget selects the compact link', () {
    final hidden = AppConstants.homeWidgetIds.toSet()..remove('favorites');
    final result = resolveHomeWidgetVisibility(
      savedOrder: const ['favorites'],
      hiddenWidgets: hidden,
    );
    expect(result.visibleIds, ['favorites']);
    expect(result.showLargeAddCard, isFalse);
    expect(result.showCompactEditLink, isTrue);
  });

  test('many widgets preserve saved order and use the compact link', () {
    final hidden = AppConstants.homeWidgetIds.toSet()
      ..removeAll(['salary', 'pomodoro']);
    final result = resolveHomeWidgetVisibility(
      savedOrder: const ['salary', 'pomodoro'],
      hiddenWidgets: hidden,
    );
    expect(result.visibleIds.take(2), ['salary', 'pomodoro']);
    expect(result.showLargeAddCard, isFalse);
    expect(result.showCompactEditLink, isTrue);
  });

  test('onboarding continues to hide every optional Home widget', () {
    final source = File(
      'lib/features/profile/data/profile_repository.dart',
    ).readAsStringSync();
    expect(
      source,
      contains("'hiddenHomeWidgets': AppConstants.homeWidgetIds"),
    );
  });
}
```

- [ ] **Step 2: Write the failing approved-card widget test**

Create `test/widget/add_widgets_empty_state_test.dart`:

```dart
import 'dart:io';

import 'package:chigio_time/features/dashboard/widgets/add_widgets_empty_state.dart';
import 'package:chigio_time/shared/widgets/glass_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows approved Chigio copy and invokes the add action', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 900);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: AddWidgetsEmptyState(onAdd: () => taps++),
          ),
        ),
      ),
    );

    expect(find.text('Costruisci la tua Home'), findsOneWidget);
    expect(
      find.text(
        'Scegli i widget che ti servono ogni giorno. '
        'Puoi cambiarli quando vuoi.',
      ),
      findsOneWidget,
    );
    expect(find.text('Aggiungi widget'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Chigio invita ad aggiungere un widget'),
      findsOneWidget,
    );
    expect(tester.getSize(find.byType(GlassBtn)).width, greaterThan(350));

    await tester.tap(find.text('Aggiungi widget'));
    expect(taps, 1);
  });

  test('approved mascot asset is optimized and transparent-source sized', () {
    final asset = File('assets/images/chigio-aggiungi-widget.png');
    expect(asset.existsSync(), isTrue);
    expect(asset.lengthSync(), lessThan(350 * 1024));
  });
}
```

- [ ] **Step 3: Run the empty-state tests and verify RED**

Run:

```bash
flutter test test/features/home_widget_visibility_test.dart test/widget/add_widgets_empty_state_test.dart
```

Expected: compilation fails because the visibility model/card and optimized asset do not exist.

- [ ] **Step 4: Optimize the approved generated Chigio asset**

Use the approved transparent source from brainstorming and constrain the longest side to 480 px:

```bash
sips -Z 480 .superpowers/brainstorm/14336-1784705448/content/chigio-add-single.png --out assets/images/chigio-aggiungi-widget.png
sips -g pixelWidth -g pixelHeight -g hasAlpha assets/images/chigio-aggiungi-widget.png
ls -lh assets/images/chigio-aggiungi-widget.png
```

Expected: maximum dimension is 480 px, `hasAlpha: yes`, and file size is below 350 KiB. If `sips` exceeds the size ceiling, run the exact 420 px fallback below; do not convert to WebP because the approved asset contract is PNG.

Exact fallback command:

```bash
sips -Z 420 .superpowers/brainstorm/14336-1784705448/content/chigio-add-single.png --out assets/images/chigio-aggiungi-widget.png
```

- [ ] **Step 5: Implement the pure Home visibility result**

Create `home_widget_visibility.dart`:

```dart
import '../../../core/constants/app_constants.dart';

class HomeWidgetVisibility {
  final List<String> orderedIds;
  final List<String> visibleIds;

  const HomeWidgetVisibility({
    required this.orderedIds,
    required this.visibleIds,
  });

  bool get showLargeAddCard => visibleIds.isEmpty;
  bool get showCompactEditLink => visibleIds.isNotEmpty;
}

HomeWidgetVisibility resolveHomeWidgetVisibility({
  required List<String> savedOrder,
  required Set<String> hiddenWidgets,
}) {
  final ordered = [
    ...savedOrder.where(AppConstants.homeWidgetIds.contains),
    ...AppConstants.homeWidgetIds.where((id) => !savedOrder.contains(id)),
  ];
  return HomeWidgetVisibility(
    orderedIds: List.unmodifiable(ordered),
    visibleIds: List.unmodifiable(
      ordered.where((id) => !hiddenWidgets.contains(id)),
    ),
  );
}
```

If `AppConstants.homeWidgetIds` order differs from the existing dashboard's local `defaultWidgetOrder`, first move that exact local order into `AppConstants.homeWidgetIds`; the resulting test must preserve `favorites`, `maggiorPresenza`, `counters`, `bancaOre`, `totalizzatori`, `routePlanner`, `orariTable`, `pomodoro`, `salary`.

- [ ] **Step 6: Implement the approved empty-state card**

Change `AppStrings` values to:

```dart
static const addWidgetsCtaTitle = 'Costruisci la tua Home';
static const addWidgetsCtaBody =
    'Scegli i widget che ti servono ogni giorno. '
    'Puoi cambiarli quando vuoi.';
static const addWidgetsCtaBtn = 'Aggiungi widget';
```

Create `add_widgets_empty_state.dart` as a stateless `GlassCard` containing:

```dart
Semantics(
  image: true,
  label: 'Chigio invita ad aggiungere un widget',
  child: SizedBox(
    height: 180,
    child: Image.asset(
      'assets/images/chigio-aggiungi-widget.png',
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    ),
  ),
),
const SizedBox(height: 4),
Text(
  AppStrings.addWidgetsCtaTitle,
  textAlign: TextAlign.center,
  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
),
const SizedBox(height: 6),
Text(
  AppStrings.addWidgetsCtaBody,
  textAlign: TextAlign.center,
  style: TextStyle(fontSize: 12, height: 1.45, color: secondaryTextColor),
),
const SizedBox(height: 14),
GlassBtn(
  label: AppStrings.addWidgetsCtaBtn,
  icon: const Icon(Icons.add_rounded, size: 18),
  onPressed: onAdd,
),
```

Use `crossAxisAlignment: CrossAxisAlignment.stretch`; do not use `HomeWidgetHeader`, a mini pose, or rasterized text.

- [ ] **Step 7: Wire zero versus one-or-more behavior into the dashboard**

Replace local order/visibility calculation with `resolveHomeWidgetVisibility`. Feed `visibility.visibleIds` to Task 2's lazy builder. Build the footer as:

```dart
final homeFooter = visibility.showLargeAddCard
    ? AddWidgetsEmptyState(
        onAdd: () => showHomeWidgetsPanel(
          context,
          ref,
          profileData ?? const {},
        ),
      )
    : Center(
        child: AppTappable(
          onTap: () => showHomeWidgetsPanel(
            context,
            ref,
            profileData ?? const {},
          ),
          child: const _EditWidgetsLinkContent(),
        ),
      );
```

Extract the current icon/text/padding into `_EditWidgetsLinkContent`; its visible copy remains `Modifica widget`. Delete private `_AddWidgetsCta`. On desktop place the same `homeFooter` at the end of the right column. The condition is no longer `visibleWidgetCount > 1`; one visible widget must show the compact link.

- [ ] **Step 8: Run empty-state and dashboard tests**

Run:

```bash
dart format lib/features/dashboard/presentation/home_widget_visibility.dart lib/features/dashboard/widgets/add_widgets_empty_state.dart lib/core/constants/app_strings.dart lib/features/dashboard/presentation/dashboard_screen.dart test/features/home_widget_visibility_test.dart test/widget/add_widgets_empty_state_test.dart
flutter test test/features/home_widget_visibility_test.dart test/widget/add_widgets_empty_state_test.dart test/core/app_strings_test.dart
flutter analyze lib/features/dashboard lib/core/constants/app_strings.dart
```

Expected: zero/one/many tests pass; card copy and semantics match exactly; asset stays below the size ceiling; dashboard analysis is clean.

- [ ] **Step 9: Update docs and commit the approved state**

Update dashboard docs to state:

- onboarding stores all optional widget IDs hidden;
- zero visible optional widgets show the large selected Chigio card;
- one or more show the compact link;
- hiding the last optional widget restores the large card;
- the asset has no embedded text and is capped at 480 px.

Add the dated changelog entry and commit:

```bash
git add assets/images/chigio-aggiungi-widget.png lib/features/dashboard/presentation/home_widget_visibility.dart lib/features/dashboard/widgets/add_widgets_empty_state.dart lib/core/constants/app_strings.dart lib/features/dashboard/presentation/dashboard_screen.dart test/features/home_widget_visibility_test.dart test/widget/add_widgets_empty_state_test.dart docs/funzionalita/dashboard.md docs/CHANGELOG.md
git diff --cached --check
git commit -m "feat: guide new users to their first Home widget"
```

Expected: one commit with the approved visual, exact copy, zero/one transition, tests, and docs.

---

### Task 6: Full verification and Galaxy S25 Ultra smoke gate

**Files:**
- Modify only when a failed check identifies a scoped defect in Tasks 1-5.
- Modify: `docs/processi/testing.md` and `docs/CHANGELOG.md` only if the final smoke procedure or a correction changes documented behavior.

**Interfaces:**
- Consumes: completed Web bootstrap/profile plan plus all Task 1-5 Home deliverables.
- Produces: automated release proof and a device checklist for Chrome and installed PWA.

- [ ] **Step 1: Run format, generation, analysis, and the full suite**

Run:

```bash
dart format --output=none --set-exit-if-changed lib test
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
npm test --prefix functions
npm test --prefix scripts
node --check functions/index.js
node --check functions/notification_logic.js
node --check functions/notification_runtime.js
```

Expected: every command exits 0; no generated file is hand-edited.

- [ ] **Step 2: Build the release Web artifact**

Run:

```bash
flutter build web --release
du -sh build/web
find build/web/assets/assets/images -name 'chigio-aggiungi-widget.png' -ls
```

Expected: release build exits 0 and contains the optimized mascot exactly once.

- [ ] **Step 3: Local Chrome performance smoke**

Serve `build/web`, sign in with an existing profile, enable all Home widgets, and capture Chrome Performance traces for:

1. cold hard refresh;
2. full Home scroll;
3. Home → another app tab → Home;
4. full Home scroll after the return.

Verify the trace and Flutter performance overlay show no continuous navbar backdrop filtering on horizontal Web, no permanent slide nudge ticker, no construction of `PomodoroCard` before its sliver approaches the viewport, and no large hero rebuild every second. Record before/after long-frame and raster/compositing observations in the task commentary; do not claim device smoothness from widget tests alone.

- [ ] **Step 4: Galaxy S25 Ultra Chrome smoke after separate access authorization**

After the user authorizes a preview/release deployment or connects the device to a reachable local build, verify in Chrome:

1. authenticated hard refresh: DOM/Flutter skeleton or cached Home, never blank/login/onboarding;
2. first Home scroll immediately after load;
3. Home → another app section → Home retains position;
4. full scroll with all nine optional widgets visible;
5. offline reopen after one online session gives cached Home or retry, never onboarding;
6. zero optional widgets show the large Chigio CTA;
7. adding exactly `favorites` removes the large card and shows `Modifica widget`;
8. hiding `favorites` restores the large card.

Expected: all eight checks pass without a visible onboarding flash or persistent jank.

- [ ] **Step 5: Galaxy S25 Ultra installed-PWA smoke on the same authorized build**

Install/open the same build as PWA and repeat:

1. close PWA completely and reopen;
2. reopen while a Chrome tab for the same app remains open;
3. scroll Home before and after switching sections;
4. reopen offline with valid cache;
5. add/remove the first optional widget.

Expected: multi-tab persistence does not fail, startup never selects onboarding from cache/error, Home position survives branch changes, and zero/one UI transition matches Chrome.

- [ ] **Step 6: Correct only observed regressions, rerun the owning test, then the full gate**

For each observed failure, first add a focused regression assertion to the owning test file, run it to see RED, apply the smallest correction, and rerun that test to GREEN. Then rerun:

```bash
flutter analyze
flutter test
flutter build web --release
git diff --check
```

Expected: all final gates pass after any correction.

- [ ] **Step 7: Commit verification corrections if present and push**

If corrections were necessary, inspect and stage only their hunks:

```bash
git diff --name-only
git add -p
git diff --cached --check
git commit -m "fix: close Home performance smoke regressions"
```

If no correction was necessary, create no empty commit. Push the complete implementation sequence:

```bash
git push origin main
```

Expected: `origin/main` contains both approved implementation plans' green commits; user-owned untracked files remain untouched.
