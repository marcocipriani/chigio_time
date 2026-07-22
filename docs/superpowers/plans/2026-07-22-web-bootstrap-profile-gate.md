# Web Bootstrap and Profile Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show a structural skeleton from the first browser paint, start Flutter without a blank interval, enable Firestore's persistent multi-tab Web cache, and prevent cache-only profile data or errors from routing an existing user to onboarding.

**Architecture:** `main()` mounts a testable bootstrap host immediately. The host loads bundled UI fonts, Firebase, Firestore settings, locale, and preferences behind a Flutter skeleton, while `web/index.html` shows the matching DOM skeleton before Flutter is ready. A typed profile-gate reducer preserves cache/server metadata and feeds a pure redirect function; only an incomplete server snapshot may select onboarding.

**Tech Stack:** Flutter 3, Dart 3.10+, Riverpod 3 code generation, GoRouter, Firebase Auth, Cloud Firestore 6.6.0 resolved by `pubspec.lock`, SharedPreferences, Flutter Web bootstrap API, `flutter_test`.

## Global Constraints

- No new package dependency.
- Chrome tab and installed PWA must coexist against the same Firestore IndexedDB cache through `WebPersistentMultipleTabManager`.
- A cache-only incomplete or absent profile never selects `/onboarding`.
- Only an incomplete or absent server profile selects `/onboarding`.
- A profile/cache error never selects `/onboarding`.
- The HTML and Flutter loaders use stable Home-like geometry; no spinner-only or blank screen.
- UI fonts are bundled. The color-emoji warm-up remains non-blocking.
- `profileDocIsComplete` remains the only profile-completeness rule.
- Existing untracked files `.impeccable/`, `.superpowers/brainstorm/`, `AGENTS.md`, and `Appendice A-elenco strutture.pdf` are not staged.
- Every task that changes `lib/` updates the relevant wiki page and `docs/CHANGELOG.md` in the same commit.

## File Structure

- Create `lib/app/bootstrap/app_bootstrap.dart`: bootstrap orchestration, initial skeleton, retry UI, Firestore Web settings, and ready-app builder.
- Modify `lib/main.dart`: synchronous first `runApp` only; no awaited work before the root widget.
- Modify `lib/shared/providers/global_providers.dart`: injectable `SharedPreferences` provider used by the bootstrap and profile data layer.
- Modify `lib/app/theme/app_theme.dart`: document bundled font lookup and keep only the non-blocking emoji fallback.
- Modify `pubspec.yaml`: include `assets/fonts/` without changing dependencies.
- Create `assets/fonts/*`: eight exact Google Fonts artifacts plus license files.
- Modify `web/index.html`: DOM skeleton and stable page background.
- Create `web/flutter_bootstrap.js`: initialize Flutter and remove the DOM loader after `runApp()` succeeds.
- Create `lib/features/profile/domain/profile_gate.dart`: completeness rule, typed gate result, and pure snapshot/error reducer.
- Modify `lib/features/profile/data/profile_repository.dart`: metadata-aware gate stream and positive-marker persistence.
- Create `lib/app/routes/app_redirect.dart`: pure redirect decision.
- Modify `lib/app/routes/app_router.dart`: listen to `profileGateProvider` and delegate decisions to the pure redirect function.
- Create `test/widget/app_bootstrap_test.dart`: Flutter skeleton, ready, error, and retry states.
- Create `test/platform/web_bootstrap_loader_test.dart`: HTML/JS loader contract.
- Create `test/platform/ui_font_assets_test.dart`: bundled font and no-blocking-font contract.
- Create `test/core/profile_gate_test.dart`: typed reducer, local marker, and metadata-listener contract.
- Create `test/core/app_redirect_test.dart`: complete redirect truth table.
- Modify `test/core/profile_doc_complete_test.dart`: import the new domain location.
- Create `docs/decisioni/0014-bootstrap-web-cache-first.md`: architectural decision.
- Modify `docs/architettura/navigation.md`, `docs/architettura/state-management.md`, `docs/architettura/persistence.md`, `docs/funzionalita/authentication.md`, `docs/funzionalita/onboarding.md`, `docs/processi/testing.md`, and `docs/CHANGELOG.md`.

---

### Task 1: Immediate HTML and Flutter bootstrap skeleton

**Files:**
- Create: `lib/app/bootstrap/app_bootstrap.dart`
- Modify: `lib/main.dart:1-81`
- Modify: `lib/shared/providers/global_providers.dart:1-102`
- Modify: `web/index.html:1-29`
- Create: `web/flutter_bootstrap.js`
- Test: `test/widget/app_bootstrap_test.dart`
- Test: `test/platform/web_bootstrap_loader_test.dart`
- Modify: `docs/funzionalita/authentication.md`
- Modify: `docs/CHANGELOG.md`

**Interfaces:**
- Produces: `AppBootstrapData`, `BootstrapLoader`, `ReadyAppBuilder`, `ChigioBootstrapApp`, `loadAppBootstrap()`, `buildReadyApp(AppBootstrapData)`, `firestoreWebCacheSettings()`, and `sharedPreferencesProvider`.
- Consumes: `ChigioTimeApp`, `DefaultFirebaseOptions`, Firebase Messaging background registration, locale initialization, and the existing theme/locale override providers.

- [ ] **Step 1: Write the failing bootstrap widget tests**

Create `test/widget/app_bootstrap_test.dart` with a `Completer<AppBootstrapData>` loader and an injected ready builder. The complete assertions are:

```dart
import 'dart:async';

import 'package:chigio_time/app/bootstrap/app_bootstrap.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  test('uses persistent Firestore cache with the Web multi-tab manager', () {
    final settings = firestoreWebCacheSettings();
    expect(settings.persistenceEnabled, isTrue);
    expect(
      settings.webPersistentTabManager,
      isA<WebPersistentMultipleTabManager>(),
    );
  });

  testWidgets('shows a structural Home skeleton before bootstrap completes', (
    tester,
  ) async {
    final pending = Completer<AppBootstrapData>();
    await tester.pumpWidget(
      ChigioBootstrapApp(
        load: () => pending.future,
        readyBuilder: (_) => const Text('ready'),
      ),
    );

    expect(find.byKey(const Key('bootstrap-home-skeleton')), findsOneWidget);
    expect(find.byKey(const Key('bootstrap-hero-shape')), findsOneWidget);
    expect(find.byKey(const Key('bootstrap-card-shape')), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('ready'), findsNothing);
  });

  testWidgets('replaces the skeleton with the ready app', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ChigioBootstrapApp(
        load: () async => AppBootstrapData(
          preferences: prefs,
          themeModeName: 'dark',
          localeCode: 'it',
        ),
        readyBuilder: (_) => const Directionality(
          textDirection: TextDirection.ltr,
          child: Text('ready'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ready'), findsOneWidget);
    expect(find.byKey(const Key('bootstrap-home-skeleton')), findsNothing);
  });

  testWidgets('shows a human error and retries with a new Future', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    var attempts = 0;
    Future<AppBootstrapData> load() async {
      attempts++;
      if (attempts == 1) throw StateError('network unavailable');
      return AppBootstrapData(
        preferences: prefs,
        themeModeName: 'system',
        localeCode: 'it',
      );
    }

    await tester.pumpWidget(
      ChigioBootstrapApp(
        load: load,
        readyBuilder: (_) => const Directionality(
          textDirection: TextDirection.ltr,
          child: Text('ready'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Riprova'), findsOneWidget);
    expect(find.textContaining('Connessione assente'), findsOneWidget);

    await tester.tap(find.text('Riprova'));
    await tester.pump();
    await tester.pump();

    expect(attempts, 2);
    expect(find.text('ready'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Write the failing Web-loader contract test**

Create `test/platform/web_bootstrap_loader_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('index and Flutter bootstrap keep a structural loader until runApp', () {
    final html = File('web/index.html').readAsStringSync();
    final bootstrap = File('web/flutter_bootstrap.js').readAsStringSync();

    expect(html, contains('id="app-loader"'));
    expect(html, contains('aria-label="Caricamento della Home"'));
    expect(html, contains('class="loader-hero"'));
    expect(html, contains('class="loader-card"'));
    expect(html, contains('flutter_bootstrap.js'));
    expect(bootstrap, contains('{{flutter_js}}'));
    expect(bootstrap, contains('{{flutter_build_config}}'));
    expect(bootstrap, contains('await appRunner.runApp()'));
    expect(bootstrap, contains("document.getElementById('app-loader')?.remove()"));
  });
}
```

- [ ] **Step 3: Run the focused tests and verify RED**

Run:

```bash
flutter test test/widget/app_bootstrap_test.dart test/platform/web_bootstrap_loader_test.dart
```

Expected: compilation fails because `app_bootstrap.dart` and its public types do not exist; the Web contract also reports the missing loader/custom bootstrap.

- [ ] **Step 4: Add the injectable preferences provider**

Add to `lib/shared/providers/global_providers.dart` immediately below the preference keys:

```dart
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw StateError('sharedPreferencesProvider must be overridden'),
  name: 'sharedPreferencesProvider',
);
```

The ready builder will always override it with the instance loaded during bootstrap.

- [ ] **Step 5: Implement the bootstrap host and structural skeleton**

Create `lib/app/bootstrap/app_bootstrap.dart` with these public contracts and state transitions:

```dart
typedef BootstrapLoader = Future<AppBootstrapData> Function();
typedef ReadyAppBuilder = Widget Function(AppBootstrapData data);

class AppBootstrapData {
  final SharedPreferences preferences;
  final String themeModeName;
  final String localeCode;

  const AppBootstrapData({
    required this.preferences,
    required this.themeModeName,
    required this.localeCode,
  });
}

Settings firestoreWebCacheSettings() => const Settings(
  persistenceEnabled: true,
  webPersistentTabManager: WebPersistentMultipleTabManager(),
);

Future<AppBootstrapData> loadAppBootstrap() async {
  final preferencesFuture = SharedPreferences.getInstance();
  final localeFuture = initializeDateFormatting('it_IT', null);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kIsWeb) {
    try {
      FirebaseFirestore.instance.settings = firestoreWebCacheSettings();
    } catch (error) {
      debugPrint('[bootstrap] Firestore persistent cache unavailable: $error');
    }
  }

  if (supportsFcm(defaultTargetPlatform, isWeb: kIsWeb)) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  await localeFuture;
  final preferences = await preferencesFuture;

  return AppBootstrapData(
    preferences: preferences,
    themeModeName:
        preferences.getString('chigio_themeMode') ?? 'system',
    localeCode: preferences.getString('chigio_locale') ?? 'it',
  );
}

Widget buildReadyApp(AppBootstrapData data) => ProviderScope(
  overrides: [
    sharedPreferencesProvider.overrideWithValue(data.preferences),
    initialThemeModeNameProvider.overrideWithValue(data.themeModeName),
    initialLocaleCodeProvider.overrideWithValue(data.localeCode),
  ],
  child: const ChigioTimeApp(),
);
```

Implement `ChigioBootstrapApp` as a `StatefulWidget` that stores one `_future`, recreates it only in `_retry()`, and uses `FutureBuilder<AppBootstrapData>`:

```dart
class ChigioBootstrapApp extends StatefulWidget {
  final BootstrapLoader load;
  final ReadyAppBuilder readyBuilder;

  const ChigioBootstrapApp({
    super.key,
    this.load = loadAppBootstrap,
    this.readyBuilder = buildReadyApp,
  });

  @override
  State<ChigioBootstrapApp> createState() => _ChigioBootstrapAppState();
}

class _ChigioBootstrapAppState extends State<ChigioBootstrapApp> {
  late Future<AppBootstrapData> _future = widget.load();

  void _retry() => setState(() => _future = widget.load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppBootstrapData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) return widget.readyBuilder(snapshot.data!);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: snapshot.hasError
              ? _BootstrapError(error: snapshot.error!, onRetry: _retry)
              : const _BootstrapHomeSkeleton(),
        );
      },
    );
  }
}
```

`_BootstrapHomeSkeleton` must be a full-screen blue/ice gradient with key `bootstrap-home-skeleton`, a 220 px rounded hero keyed `bootstrap-hero-shape`, and two rounded cards keyed `bootstrap-card-shape`. Use one `TweenAnimationBuilder<double>` around the whole skeleton, stop at a fixed opacity when `MediaQuery.disableAnimations` is true, and use no package fonts. `_BootstrapError` uses `AppStrings.errorGeneric(error)` and a `TextButton` labelled `AppStrings.retry`.

- [ ] **Step 6: Mount the bootstrap before all asynchronous work**

Replace `main()` in `lib/main.dart` with the synchronous entry point below and move all Firebase/font/preferences imports into `app_bootstrap.dart`:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const ChigioBootstrapApp());
}
```

`main.dart` retains only Flutter material/services imports plus `app_bootstrap.dart`.

- [ ] **Step 7: Add the DOM loader and custom Flutter bootstrap**

In `web/index.html`, add before the script:

```html
<main id="app-loader" role="status" aria-live="polite"
      aria-label="Caricamento della Home">
  <section class="loader-shell">
    <div class="loader-hero"></div>
    <div class="loader-line loader-line-wide"></div>
    <div class="loader-card"></div>
    <div class="loader-card loader-card-short"></div>
  </section>
</main>
```

Add inline CSS in `<head>` that sets `html, body, #app-loader` to full size, removes body margin, uses `#eef7ff` as the base, centers a `max-width: 430px` shell, and applies one opacity animation to `.loader-shell`. Respect `@media (prefers-reduced-motion: reduce)` by disabling the animation. Keep hero/card dimensions aligned with `_BootstrapHomeSkeleton`.

Create `web/flutter_bootstrap.js`:

```javascript
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    document.getElementById('app-loader')?.remove();
  },
});
```

- [ ] **Step 8: Run tests and verify GREEN**

Run:

```bash
dart format lib/main.dart lib/app/bootstrap/app_bootstrap.dart lib/shared/providers/global_providers.dart test/widget/app_bootstrap_test.dart test/platform/web_bootstrap_loader_test.dart
flutter test test/widget/app_bootstrap_test.dart test/platform/web_bootstrap_loader_test.dart
```

Expected: all bootstrap and Web-loader tests pass.

- [ ] **Step 9: Update docs and commit the first-frame fix**

Update `docs/funzionalita/authentication.md` so the app-start sequence begins with DOM skeleton → Flutter skeleton → initialized app. Add a dated `fix/perf` entry to `docs/CHANGELOG.md` naming the two skeleton layers and retry state.

Run:

```bash
git add lib/main.dart lib/app/bootstrap/app_bootstrap.dart lib/shared/providers/global_providers.dart web/index.html web/flutter_bootstrap.js test/widget/app_bootstrap_test.dart test/platform/web_bootstrap_loader_test.dart docs/funzionalita/authentication.md docs/CHANGELOG.md
git diff --cached --check
git commit -m "perf: show skeleton during web bootstrap"
```

Expected: one commit containing the immediate first-frame path and its documentation.

---

### Task 2: Bundle the first-frame UI fonts

**Files:**
- Create: `assets/fonts/PlusJakartaSans-Regular.ttf`
- Create: `assets/fonts/PlusJakartaSans-SemiBold.ttf`
- Create: `assets/fonts/PlusJakartaSans-Bold.ttf`
- Create: `assets/fonts/PlusJakartaSans-ExtraBold.ttf`
- Create: `assets/fonts/NotoSans-Regular.ttf`
- Create: `assets/fonts/NotoSansSymbols-Regular.ttf`
- Create: `assets/fonts/NotoSansSymbols2-Regular.ttf`
- Create: `assets/fonts/Roboto-Regular.ttf`
- Create: `assets/fonts/OFL-PlusJakartaSans.txt`
- Create: `assets/fonts/OFL-Noto.txt`
- Create: `assets/fonts/OFL-Roboto.txt`
- Modify: `pubspec.yaml:105-150`
- Modify: `lib/app/bootstrap/app_bootstrap.dart`
- Modify: `lib/main.dart`
- Modify: `lib/app/theme/app_theme.dart:1-146`
- Test: `test/platform/ui_font_assets_test.dart`
- Modify: `docs/architettura/state-management.md`
- Modify: `docs/CHANGELOG.md`

**Interfaces:**
- Produces: `Future<void> loadBundledUiFonts()`, `Future<void> warmColorEmojiFont()`, and `void registerBundledFontLicenses()` integrated into Task 1's bootstrap host.
- Consumes: the existing `GoogleFonts.plusJakartaSans*`, `notoSans*`, and `roboto` APIs; their asset lookup recognizes the exact filenames below.

- [ ] **Step 1: Write the failing asset contract test**

Create `test/platform/ui_font_assets_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const files = <String>[
    'PlusJakartaSans-Regular.ttf',
    'PlusJakartaSans-SemiBold.ttf',
    'PlusJakartaSans-Bold.ttf',
    'PlusJakartaSans-ExtraBold.ttf',
    'NotoSans-Regular.ttf',
    'NotoSansSymbols-Regular.ttf',
    'NotoSansSymbols2-Regular.ttf',
    'Roboto-Regular.ttf',
  ];

  test('first-frame UI fonts are bundled and non-empty', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/fonts/'));
    for (final name in files) {
      final file = File('assets/fonts/$name');
      expect(file.existsSync(), isTrue, reason: name);
      expect(file.lengthSync(), greaterThan(10000), reason: name);
    }
  });

  test('main no longer awaits fonts before the first runApp', () {
    final main = File('lib/main.dart').readAsStringSync();
    final bootstrap = File(
      'lib/app/bootstrap/app_bootstrap.dart',
    ).readAsStringSync();
    expect(main, isNot(contains('GoogleFonts.pendingFonts')));
    expect(bootstrap, contains('loadBundledUiFonts'));
    expect(bootstrap, contains('unawaited(warmColorEmojiFont())'));
  });
}
```

- [ ] **Step 2: Run the asset test and verify RED**

Run:

```bash
flutter test test/platform/ui_font_assets_test.dart
```

Expected: FAIL because `assets/fonts/` and the bootstrap font functions are absent.

- [ ] **Step 3: Download the exact Google Fonts artifacts and licenses**

Create `assets/fonts/`, then download the package-compatible static files. The hash in each URL is also the SHA-256 expected by `google_fonts` 8.1.0:

```bash
mkdir -p assets/fonts
curl -fL https://fonts.gstatic.com/s/a/1306435ed883e4a1e6dad370e6d035955da71f4df9c07ca192833f7cb58a18d7.ttf -o assets/fonts/PlusJakartaSans-Regular.ttf
curl -fL https://fonts.gstatic.com/s/a/8590ab94f96850ab246d5795a9ba442e42f64036673bc329573dfe93efbc7c87.ttf -o assets/fonts/PlusJakartaSans-SemiBold.ttf
curl -fL https://fonts.gstatic.com/s/a/5b6d946cf820c9851ff7b4776425ee43f5cf405c6f891a4a7fcb4a74d5e32d52.ttf -o assets/fonts/PlusJakartaSans-Bold.ttf
curl -fL https://fonts.gstatic.com/s/a/9ab901a45e6afa0c663def7606b753bbdfb60fc73bf3277e8110c167ddb6bbc3.ttf -o assets/fonts/PlusJakartaSans-ExtraBold.ttf
curl -fL https://fonts.gstatic.com/s/a/61ea1e781b9d7b10db9b4a6aa2d855cf2215c316c7cb700aeb067a0440d031e0.ttf -o assets/fonts/NotoSans-Regular.ttf
curl -fL https://fonts.gstatic.com/s/a/4942cf29dd874c976fea691a7c52b67183923a646335c13ad09de11a36560b8a.ttf -o assets/fonts/NotoSansSymbols-Regular.ttf
curl -fL https://fonts.gstatic.com/s/a/760ba6cdbfc3d581392d9a49346f8ecb1ef3e56cbcb58d4227d8ad44628a96fd.ttf -o assets/fonts/NotoSansSymbols2-Regular.ttf
curl -fL https://fonts.gstatic.com/s/a/7f3ec5073a282c666c9a0063573345841229caf50ed34d33017e20d441bf5caf.ttf -o assets/fonts/Roboto-Regular.ttf
curl -fL https://raw.githubusercontent.com/google/fonts/main/ofl/plusjakartasans/OFL.txt -o assets/fonts/OFL-PlusJakartaSans.txt
curl -fL https://raw.githubusercontent.com/google/fonts/main/ofl/notosans/OFL.txt -o assets/fonts/OFL-Noto.txt
curl -fL https://raw.githubusercontent.com/google/fonts/main/ofl/roboto/OFL.txt -o assets/fonts/OFL-Roboto.txt
```

Verify all binary hashes:

```bash
(cd assets/fonts && printf '%s  %s\n' \
  1306435ed883e4a1e6dad370e6d035955da71f4df9c07ca192833f7cb58a18d7 PlusJakartaSans-Regular.ttf \
  8590ab94f96850ab246d5795a9ba442e42f64036673bc329573dfe93efbc7c87 PlusJakartaSans-SemiBold.ttf \
  5b6d946cf820c9851ff7b4776425ee43f5cf405c6f891a4a7fcb4a74d5e32d52 PlusJakartaSans-Bold.ttf \
  9ab901a45e6afa0c663def7606b753bbdfb60fc73bf3277e8110c167ddb6bbc3 PlusJakartaSans-ExtraBold.ttf \
  61ea1e781b9d7b10db9b4a6aa2d855cf2215c316c7cb700aeb067a0440d031e0 NotoSans-Regular.ttf \
  4942cf29dd874c976fea691a7c52b67183923a646335c13ad09de11a36560b8a NotoSansSymbols-Regular.ttf \
  760ba6cdbfc3d581392d9a49346f8ecb1ef3e56cbcb58d4227d8ad44628a96fd NotoSansSymbols2-Regular.ttf \
  7f3ec5073a282c666c9a0063573345841229caf50ed34d33017e20d441bf5caf Roboto-Regular.ttf \
  | shasum -a 256 -c -)
```

Expected: eight `OK` lines.

- [ ] **Step 4: Register the font assets and local loading contract**

Add to `pubspec.yaml` under `flutter/assets`:

```yaml
    - assets/fonts/
```

In `app_bootstrap.dart`, implement:

Add `dart:async`, `flutter/services.dart`, and `google_fonts/google_fonts.dart` imports. Keep the existing `flutter/foundation.dart` import so `LicenseRegistry`, `LicenseEntryWithLineBreaks`, `kIsWeb`, and `debugPrint` remain available.

```dart
Future<void> loadBundledUiFonts() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.plusJakartaSans(),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
      GoogleFonts.notoSans(),
      GoogleFonts.notoSansSymbols(),
      GoogleFonts.notoSansSymbols2(),
      GoogleFonts.roboto(),
    ]);
  } finally {
    GoogleFonts.config.allowRuntimeFetching = true;
  }
}

Future<void> warmColorEmojiFont() async {
  try {
    await GoogleFonts.pendingFonts([GoogleFonts.notoColorEmoji()]);
  } catch (error) {
    debugPrint('[bootstrap] color emoji warm-up skipped: $error');
  }
}

void registerBundledFontLicenses() {
  for (final entry in const <(String, List<String>)>[
    ('assets/fonts/OFL-PlusJakartaSans.txt', ['Plus Jakarta Sans']),
    ('assets/fonts/OFL-Noto.txt', [
      'Noto Sans',
      'Noto Sans Symbols',
      'Noto Sans Symbols 2',
    ]),
    ('assets/fonts/OFL-Roboto.txt', ['Roboto']),
  ]) {
    LicenseRegistry.addLicense(() async* {
      final text = await rootBundle.loadString(entry.$1);
      yield LicenseEntryWithLineBreaks(entry.$2, text);
    });
  }
}
```

`AppTheme` keeps `GoogleFonts.plusJakartaSansTextTheme`; update its comment to state that all first-frame variants resolve from assets and only `Noto Color Emoji` may use the network after the first frame.

Update `loadAppBootstrap()` so the locale and bundled UI fonts complete together, then start the emoji warm-up after preferences resolve:

```dart
await Future.wait<void>([localeFuture, loadBundledUiFonts()]);
final preferences = await preferencesFuture;
unawaited(warmColorEmojiFont());
```

Add `registerBundledFontLicenses();` immediately before `runApp` in `main()`.

- [ ] **Step 5: Run the font and bootstrap tests**

Run:

```bash
flutter pub get
dart format lib/app/bootstrap/app_bootstrap.dart lib/app/theme/app_theme.dart test/platform/ui_font_assets_test.dart
flutter test test/platform/ui_font_assets_test.dart test/widget/app_bootstrap_test.dart
```

Expected: all tests pass and no test log reports an HTTP fetch for the eight UI font variants.

- [ ] **Step 6: Update docs and commit bundled fonts**

Update `docs/architettura/state-management.md` bootstrap notes: first-frame UI fonts are local assets, loaded behind the Flutter skeleton, while color emoji is best-effort and non-blocking. Add the matching `perf` entry to `docs/CHANGELOG.md`.

Run:

```bash
git add assets/fonts pubspec.yaml pubspec.lock lib/main.dart lib/app/bootstrap/app_bootstrap.dart lib/app/theme/app_theme.dart test/platform/ui_font_assets_test.dart docs/architettura/state-management.md docs/CHANGELOG.md
git diff --cached --check
git commit -m "perf: bundle first-frame UI fonts"
```

Expected: one commit with font binaries, license texts, bootstrap loading, tests, and docs.

---

### Task 3: Metadata-aware typed profile gate

**Files:**
- Create: `lib/features/profile/domain/profile_gate.dart`
- Modify: `lib/features/profile/data/profile_repository.dart:1-528`
- Modify: `lib/shared/providers/global_providers.dart`
- Modify: `lib/features/dashboard/presentation/dashboard_screen.dart:54-92`
- Modify: generated `lib/features/profile/data/profile_repository.g.dart` through `build_runner` only
- Test: `test/core/profile_gate_test.dart`
- Modify: `test/core/profile_doc_complete_test.dart`
- Modify: `docs/architettura/persistence.md`
- Modify: `docs/funzionalita/onboarding.md`
- Modify: `docs/funzionalita/dashboard.md`
- Modify: `docs/entita/user-profile.md`
- Modify: `docs/CHANGELOG.md`

**Interfaces:**
- Produces: `ProfileGateStatus`, `ProfileGateResult`, `profileDocIsComplete(Map<String, dynamic>?)`, `reduceProfileGateSnapshot(...)`, `reduceProfileGateError(...)`, and generated `profileGateProvider`.
- Consumes: `sharedPreferencesProvider`, `authStateChangesProvider`, Firestore snapshot metadata, and `ProfileRepository.saveOnboardingData`.

- [ ] **Step 1: Write failing reducer and stream-contract tests**

Create `test/core/profile_gate_test.dart`:

```dart
import 'dart:io';

import 'package:chigio_time/features/profile/domain/profile_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolving = ProfileGateResult(
    status: ProfileGateStatus.resolving,
    hasUsableProfile: false,
  );

  test('cache incomplete remains resolving and never becomes onboarding', () {
    final result = reduceProfileGateSnapshot(
      previous: resolving,
      data: const {'photoURL': 'https://example.test/photo.png'},
      isFromCache: true,
    );
    expect(result.status, ProfileGateStatus.resolving);
    expect(result.hasUsableProfile, isFalse);
    expect(result.requiresOnboarding, isFalse);
  });

  test('cache complete permits Home without server authority', () {
    final result = reduceProfileGateSnapshot(
      previous: resolving,
      data: const {'hasCompletedOnboarding': true},
      isFromCache: true,
    );
    expect(result.status, ProfileGateStatus.completeCached);
    expect(result.hasUsableProfile, isTrue);
  });

  test('server incomplete is the only snapshot that requires onboarding', () {
    final result = reduceProfileGateSnapshot(
      previous: resolving,
      data: null,
      isFromCache: false,
    );
    expect(result.status, ProfileGateStatus.incompleteServer);
    expect(result.requiresOnboarding, isTrue);
  });

  test('error preserves a previously usable cached profile', () {
    const cached = ProfileGateResult(
      status: ProfileGateStatus.completeCached,
      hasUsableProfile: true,
    );
    final error = StateError('network unavailable');
    final result = reduceProfileGateError(previous: cached, error: error);
    expect(result.status, ProfileGateStatus.failure);
    expect(result.hasUsableProfile, isTrue);
    expect(result.error, same(error));
    expect(result.requiresOnboarding, isFalse);
  });

  test('profile stream includes metadata and maintains the local marker', () {
    final source = File(
      'lib/features/profile/data/profile_repository.dart',
    ).readAsStringSync();
    expect(source, contains('snapshots(includeMetadataChanges: true)'));
    expect(source, contains("'hasProfile_${user.uid}'"));
    expect(source, contains('preferences.setBool(markerKey, true)'));
    expect(source, contains('preferences.remove(markerKey)'));
  });
}
```

Change `test/core/profile_doc_complete_test.dart` to import `features/profile/domain/profile_gate.dart`.

- [ ] **Step 2: Run the focused tests and verify RED**

Run:

```bash
flutter test test/core/profile_gate_test.dart test/core/profile_doc_complete_test.dart
```

Expected: compilation fails because the typed gate domain file does not exist.

- [ ] **Step 3: Implement the pure profile-gate domain contract**

Create `lib/features/profile/domain/profile_gate.dart`:

```dart
enum ProfileGateStatus {
  resolving,
  completeCached,
  completeServer,
  incompleteServer,
  failure,
}

class ProfileGateResult {
  final ProfileGateStatus status;
  final bool hasUsableProfile;
  final Object? error;

  const ProfileGateResult({
    required this.status,
    required this.hasUsableProfile,
    this.error,
  });

  bool get requiresOnboarding =>
      status == ProfileGateStatus.incompleteServer;

  bool get allowsHome => hasUsableProfile && !requiresOnboarding;
}

bool profileDocIsComplete(Map<String, dynamic>? data) {
  if (data == null) return false;
  if (data['hasCompletedOnboarding'] == true) return true;
  return (data['name'] as String? ?? '').trim().isNotEmpty &&
      (data['employmentType'] as String? ?? '').trim().isNotEmpty;
}

ProfileGateResult reduceProfileGateSnapshot({
  required ProfileGateResult previous,
  required Map<String, dynamic>? data,
  required bool isFromCache,
}) {
  if (profileDocIsComplete(data)) {
    return ProfileGateResult(
      status: isFromCache
          ? ProfileGateStatus.completeCached
          : ProfileGateStatus.completeServer,
      hasUsableProfile: true,
    );
  }
  if (isFromCache) {
    return ProfileGateResult(
      status: ProfileGateStatus.resolving,
      hasUsableProfile: previous.hasUsableProfile,
    );
  }
  return const ProfileGateResult(
    status: ProfileGateStatus.incompleteServer,
    hasUsableProfile: false,
  );
}

ProfileGateResult reduceProfileGateError({
  required ProfileGateResult previous,
  required Object error,
}) => ProfileGateResult(
  status: ProfileGateStatus.failure,
  hasUsableProfile: previous.hasUsableProfile,
  error: error,
);
```

Move the existing completeness comments with the function; remove the duplicate from the data file.

- [ ] **Step 4: Replace the boolean stream with the metadata-aware gate**

In `profile_repository.dart`, inject `SharedPreferences` into `ProfileRepository`:

```dart
final SharedPreferences _preferences;

ProfileRepository(this._firestore, this._auth, this._preferences);
```

Immediately after the existing Firestore `set(..., SetOptions(merge: true))` in `saveOnboardingData` completes, persist the positive marker:

```dart
await _preferences.setBool('hasProfile_${user.uid}', true);
```

Then replace `hasProfileStream` with:

```dart
@riverpod
Stream<ProfileGateResult> profileGate(Ref ref) async* {
  final authState = ref.watch(authStateChangesProvider);
  if (authState.isLoading) return;
  final user = authState.asData?.value;
  if (user == null) return;

  final preferences = ref.watch(sharedPreferencesProvider);
  final markerKey = 'hasProfile_${user.uid}';
  var current = preferences.getBool(markerKey) == true
      ? const ProfileGateResult(
          status: ProfileGateStatus.completeCached,
          hasUsableProfile: true,
        )
      : const ProfileGateResult(
          status: ProfileGateStatus.resolving,
          hasUsableProfile: false,
        );
  yield current;

  final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
  var backfilled = false;
  try {
    await for (final snapshot
        in docRef.snapshots(includeMetadataChanges: true)) {
      current = reduceProfileGateSnapshot(
        previous: current,
        data: snapshot.data(),
        isFromCache: snapshot.metadata.isFromCache,
      );

      if (current.status == ProfileGateStatus.completeServer) {
        await preferences.setBool(markerKey, true);
        final data = snapshot.data();
        if (data?['hasCompletedOnboarding'] != true &&
            !snapshot.metadata.hasPendingWrites &&
            !backfilled) {
          backfilled = true;
          docRef.update({'hasCompletedOnboarding': true}).ignore();
        }
      } else if (current.status == ProfileGateStatus.incompleteServer) {
        await preferences.remove(markerKey);
      }
      yield current;
    }
  } catch (error) {
    yield reduceProfileGateError(previous: current, error: error);
  }
}
```

The provider factory becomes:

```dart
return ProfileRepository(
  FirebaseFirestore.instance,
  FirebaseAuth.instance,
  ref.watch(sharedPreferencesProvider),
);
```

In the dashboard retry callback, also call `ref.invalidate(profileGateProvider)` so an error without usable data has an explicit recovery path.

- [ ] **Step 5: Regenerate Riverpod code and run focused tests**

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
dart format lib/features/profile/domain/profile_gate.dart lib/features/profile/data/profile_repository.dart lib/features/dashboard/presentation/dashboard_screen.dart test/core/profile_gate_test.dart test/core/profile_doc_complete_test.dart
flutter test test/core/profile_gate_test.dart test/core/profile_doc_complete_test.dart
```

Expected: all gate/completeness tests pass; generated code exposes `profileGateProvider` and no `hasProfileStreamProvider` reference remains.

- [ ] **Step 6: Update persistence/onboarding docs and commit the gate**

Update the four wiki pages with these exact facts:

- the marker is positive-only and is never sufficient to route to onboarding;
- cache incomplete remains resolving;
- cache complete allows Home;
- server incomplete removes the marker and requires onboarding;
- errors preserve any usable profile and never imply a new user;
- the stream requests metadata changes.

In `docs/funzionalita/dashboard.md`, document that the global retry also invalidates the profile gate when no usable profile/month value exists.

Add the dated regression entry to `docs/CHANGELOG.md`, then run:

```bash
git add lib/features/profile/domain/profile_gate.dart lib/features/profile/data/profile_repository.dart lib/features/profile/data/profile_repository.g.dart lib/features/dashboard/presentation/dashboard_screen.dart lib/shared/providers/global_providers.dart test/core/profile_gate_test.dart test/core/profile_doc_complete_test.dart docs/architettura/persistence.md docs/funzionalita/onboarding.md docs/funzionalita/dashboard.md docs/entita/user-profile.md docs/CHANGELOG.md
git diff --cached --check
git commit -m "fix: make profile routing server authoritative"
```

Expected: one commit with reducer, stream, marker lifecycle, regression tests, generated code, and docs.

---

### Task 4: Pure routing decisions and architectural record

**Files:**
- Create: `lib/app/routes/app_redirect.dart`
- Modify: `lib/app/routes/app_router.dart:1-196`
- Test: `test/core/app_redirect_test.dart`
- Create: `docs/decisioni/0014-bootstrap-web-cache-first.md`
- Modify: `docs/decisioni/README.md`
- Modify: `docs/architettura/navigation.md`
- Modify: `docs/architettura/state-management.md`
- Modify: `docs/funzionalita/authentication.md`
- Modify: `docs/funzionalita/onboarding.md`
- Modify: `docs/processi/testing.md`
- Modify: `docs/CHANGELOG.md`

**Interfaces:**
- Consumes: `ProfileGateResult` and generated `profileGateProvider` from Task 3.
- Produces: `String? resolveAppRedirect(...)`, used as the only redirect decision inside `GoRouter`.

- [ ] **Step 1: Write the failing redirect truth-table test**

Create `test/core/app_redirect_test.dart`:

```dart
import 'package:chigio_time/app/routes/app_redirect.dart';
import 'package:chigio_time/features/profile/domain/profile_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolving = ProfileGateResult(
    status: ProfileGateStatus.resolving,
    hasUsableProfile: false,
  );
  const cached = ProfileGateResult(
    status: ProfileGateStatus.completeCached,
    hasUsableProfile: true,
  );
  const incomplete = ProfileGateResult(
    status: ProfileGateStatus.incompleteServer,
    hasUsableProfile: false,
  );
  const failed = ProfileGateResult(
    status: ProfileGateStatus.failure,
    hasUsableProfile: false,
    error: 'offline',
  );
  const failedWithCache = ProfileGateResult(
    status: ProfileGateStatus.failure,
    hasUsableProfile: true,
    error: 'offline',
  );

  test('unauthenticated users go only to login', () {
    expect(
      resolveAppRedirect(
        authLoading: false,
        isAuthenticated: false,
        gate: resolving,
        location: '/dashboard',
      ),
      '/login',
    );
    expect(
      resolveAppRedirect(
        authLoading: false,
        isAuthenticated: false,
        gate: resolving,
        location: '/login',
      ),
      isNull,
    );
  });

  test('resolving and failure never select onboarding', () {
    for (final gate in [resolving, failed]) {
      expect(
        resolveAppRedirect(
          authLoading: false,
          isAuthenticated: true,
          gate: gate,
          location: '/dashboard',
        ),
        isNull,
      );
    }
  });

  test('only incompleteServer selects onboarding', () {
    expect(
      resolveAppRedirect(
        authLoading: false,
        isAuthenticated: true,
        gate: incomplete,
        location: '/dashboard',
      ),
      '/onboarding',
    );
  });

  test('usable cache exits login or onboarding to dashboard', () {
    for (final gate in [cached, failedWithCache]) {
      for (final location in ['/login', '/onboarding']) {
        expect(
          resolveAppRedirect(
            authLoading: false,
            isAuthenticated: true,
            gate: gate,
            location: location,
          ),
          '/dashboard',
        );
      }
    }
  });
}
```

- [ ] **Step 2: Run the redirect test and verify RED**

Run:

```bash
flutter test test/core/app_redirect_test.dart
```

Expected: compilation fails because `app_redirect.dart` does not exist.

- [ ] **Step 3: Implement the pure redirect and wire GoRouter**

Create `lib/app/routes/app_redirect.dart`:

```dart
import '../../features/profile/domain/profile_gate.dart';

String? resolveAppRedirect({
  required bool authLoading,
  required bool isAuthenticated,
  required ProfileGateResult gate,
  required String location,
}) {
  if (authLoading) return null;
  final goingToLogin = location == '/login';
  final goingToOnboarding = location == '/onboarding';

  if (!isAuthenticated) return goingToLogin ? null : '/login';
  if (gate.requiresOnboarding) {
    return goingToOnboarding ? null : '/onboarding';
  }
  if (gate.allowsHome && (goingToLogin || goingToOnboarding)) {
    return '/dashboard';
  }
  return null;
}
```

In `app_router.dart`:

- `_RouterNotifier` listens to `profileGateProvider` instead of the removed boolean provider;
- `redirect` reads `profileGateProvider` and uses its value when present;
- an `AsyncLoading` or `AsyncError` wrapper is converted to `ProfileGateResult(status: resolving/failure, hasUsableProfile: false)` rather than to `false`;
- the final return is one `resolveAppRedirect(...)` call.

Use this normalization before the call:

```dart
final gateAsync = ref.read(profileGateProvider);
final gate = gateAsync.asData?.value ?? ProfileGateResult(
  status: gateAsync.hasError
      ? ProfileGateStatus.failure
      : ProfileGateStatus.resolving,
  hasUsableProfile: false,
  error: gateAsync.error,
);
```

- [ ] **Step 4: Run routing and gate tests**

Run:

```bash
dart format lib/app/routes/app_redirect.dart lib/app/routes/app_router.dart test/core/app_redirect_test.dart
flutter test test/core/app_redirect_test.dart test/core/profile_gate_test.dart test/core/profile_doc_complete_test.dart
```

Expected: all tests pass and `rg "hasProfileStreamProvider" lib test` returns no matches.

- [ ] **Step 5: Record ADR-0014 and update the wiki**

Create `docs/decisioni/0014-bootstrap-web-cache-first.md` from the repository template with:

- Context: blank cold start, false onboarding flash, Chrome + PWA multi-tab use.
- Options: server-only gate, boolean cache-first gate, typed cache/server gate.
- Decision: immediate two-layer skeleton; local UI fonts; Firestore persistent multi-tab cache; typed server-authoritative incomplete result.
- Consequences: cached complete Home is fast/offline; new users wait for server authority; cache failure degrades to memory/error UI; no duplicate Home cache.

Update `docs/decisioni/README.md`, navigation/state/auth/onboarding/testing pages, and the changelog. Replace any old statement saying “Firestore error means no profile” or “boolean stream is sufficient.”

- [ ] **Step 6: Commit the routing decision**

Run:

```bash
git add lib/app/routes/app_redirect.dart lib/app/routes/app_router.dart test/core/app_redirect_test.dart docs/decisioni/0014-bootstrap-web-cache-first.md docs/decisioni/README.md docs/architettura/navigation.md docs/architettura/state-management.md docs/funzionalita/authentication.md docs/funzionalita/onboarding.md docs/processi/testing.md docs/CHANGELOG.md
git diff --cached --check
git commit -m "fix: prevent cache-only onboarding redirects"
```

Expected: one commit with the pure redirect, complete truth table, ADR, and updated wiki.

---

### Task 5: Bootstrap/profile verification gate

**Files:**
- Modify only if a failure requires a scoped correction in files from Tasks 1-4.

**Interfaces:**
- Consumes: all Task 1-4 deliverables.
- Produces: a release-build proof for the first half of the approved design.

- [ ] **Step 1: Run code generation and static analysis**

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

Expected: generator exits 0; analyzer reports no errors or warnings introduced by this plan.

- [ ] **Step 2: Run the full Flutter suite**

Run:

```bash
flutter test
```

Expected: entire suite passes, including bootstrap, Web loader, font assets, profile gate, and redirect tests.

- [ ] **Step 3: Build Web release and inspect artifacts**

Run:

```bash
flutter build web --release
rg -n "app-loader|loader-hero" build/web/index.html
test -f build/web/flutter_bootstrap.js
find build/web/assets/assets/fonts -type f | sort
```

Expected: release build exits 0; DOM loader and custom bootstrap are present; all eight UI fonts and three license assets are bundled.

- [ ] **Step 4: Perform local Chrome smoke without deployment**

Serve `build/web` with the repository's documented local Web server and verify:

1. hard refresh shows DOM skeleton immediately;
2. Flutter skeleton replaces it without white flash;
3. an authenticated profile never shows onboarding while cache/server resolves;
4. DevTools Network filtered by `fonts.gstatic.com` shows no blocking request for Plus Jakarta Sans, Noto Sans/Symbols, or Roboto;
5. with Network offline after one successful session, cached Home or a retry error appears, never onboarding.

Expected: all five observations pass in Chrome; PWA/Galaxy verification remains in the second plan's final device gate.

- [ ] **Step 5: Commit any verification-only correction and push**

If Steps 1-4 required a correction, update the affected test and wiki/changelog in the same commit:

```bash
git diff --name-only
git add -p
git diff --cached --check
git commit -m "test: harden web bootstrap regression coverage"
```

Then push the completed sequence:

```bash
git push origin main
```

Expected: `origin/main` contains every green commit from this plan; unrelated untracked files remain uncommitted.
