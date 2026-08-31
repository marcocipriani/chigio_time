import 'dart:async';

import 'package:chigio_time/app/app.dart';
import 'package:chigio_time/core/constants/app_strings.dart';
import 'package:chigio_time/core/logging/app_logger.dart';
import 'package:chigio_time/core/services/fcm_service.dart';
import 'package:chigio_time/core/services/notification_routing.dart';
import 'package:chigio_time/firebase_options.dart';
import 'package:chigio_time/shared/providers/global_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _logTag = 'bootstrap';

/// Chiave del sito reCAPTCHA v3, iniettata al build:
/// `flutter build web --dart-define=APP_CHECK_RECAPTCHA_KEY=...`.
/// Non e' un segreto (viaggia nella pagina), ma sta fuori dal sorgente perche'
/// cambia tra progetti Firebase.
const appCheckRecaptchaSiteKey = String.fromEnvironment(
  'APP_CHECK_RECAPTCHA_KEY',
);

/// App Check attesta che le chiamate a Firestore/Storage vengano dall'app
/// pubblicata: la config Firebase e' pubblica per costruzione, quindi senza
/// attestazione chiunque sia autenticato puo' parlare col database da uno
/// script. Le regole restano l'autorizzazione, questo e' l'autenticita'.
///
/// Su web serve la chiave reCAPTCHA: senza, non si attiva (build locali,
/// test). Un fallimento non deve mai impedire l'avvio — finche' l'enforcement
/// e' spento in console il traffico passa comunque.
Future<void> activateAppCheck() async {
  if (kIsWeb && appCheckRecaptchaSiteKey.isEmpty) return;
  try {
    await FirebaseAppCheck.instance.activate(
      providerWeb: kIsWeb
          ? ReCaptchaV3Provider(appCheckRecaptchaSiteKey)
          : null,
      providerAndroid: const AndroidPlayIntegrityProvider(),
      providerApple: const AppleDeviceCheckProvider(),
    );
  } catch (error, stackTrace) {
    AppLog.warning(
      _logTag,
      'App Check non attivato',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

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

/// Font del testo dell'interfaccia: il primo frame li aspetta, senza di loro
/// la UI comparirebbe con un fallback e poi salterebbe.
Future<void> loadBundledUiFonts() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.plusJakartaSans(),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
      GoogleFonts.roboto(),
    ]);
  } finally {
    GoogleFonts.config.allowRuntimeFetching = true;
  }
}

/// Fallback per i glifi che Plus Jakarta non copre (simboli, alfabeti non
/// latini). Sono 1,4 MB su web e nessuna schermata iniziale ne ha bisogno:
/// vanno scaldati fuori dal percorso critico, come l'emoji a colori.
Future<void> warmFallbackFonts() async {
  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.notoSans(),
      GoogleFonts.notoSansSymbols(),
      GoogleFonts.notoSansSymbols2(),
    ]);
  } catch (error, stackTrace) {
    AppLog.warning(
      _logTag,
      'fallback font warm-up skipped',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

Future<void> warmColorEmojiFont() async {
  try {
    await GoogleFonts.pendingFonts([GoogleFonts.notoColorEmoji()]);
  } catch (error, stackTrace) {
    AppLog.warning(
      _logTag,
      'color emoji warm-up skipped',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

void registerBundledFontLicenses() {
  for (final entry in const <(String, List<String>)>[
    ('assets/fonts/OFL-PlusJakartaSans.txt', ['Plus Jakarta Sans']),
    (
      'assets/fonts/OFL-Noto.txt',
      ['Noto Sans', 'Noto Sans Symbols', 'Noto Sans Symbols 2'],
    ),
    ('assets/fonts/OFL-Roboto.txt', ['Roboto']),
  ]) {
    LicenseRegistry.addLicense(() async* {
      final text = await rootBundle.loadString(entry.$1);
      yield LicenseEntryWithLineBreaks(entry.$2, text);
    });
  }
}

Future<AppBootstrapData> loadAppBootstrap() async {
  final preferencesFuture = SharedPreferences.getInstance();
  final localeFuture = initializeDateFormatting('it_IT', null);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await activateAppCheck();
  if (kIsWeb) {
    try {
      FirebaseFirestore.instance.settings = firestoreWebCacheSettings();
    } catch (error, stackTrace) {
      AppLog.warning(
        _logTag,
        'Firestore persistent cache unavailable',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  if (supportsFcm(defaultTargetPlatform, isWeb: kIsWeb)) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  await Future.wait<void>([localeFuture, loadBundledUiFonts()]);
  final preferences = await preferencesFuture;
  unawaited(warmFallbackFonts());
  unawaited(warmColorEmojiFont());

  return AppBootstrapData(
    preferences: preferences,
    themeModeName: preferences.getString('chigio_themeMode') ?? 'system',
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

  void _retry() {
    final future = widget.load();
    setState(() {
      _future = future;
    });
  }

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

class _BootstrapHomeSkeleton extends StatelessWidget {
  const _BootstrapHomeSkeleton();

  @override
  Widget build(BuildContext context) {
    final animationsDisabled = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      key: const Key('bootstrap-home-skeleton'),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDCEFFF), Color(0xFFF4FAFF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.58, end: 0.88),
                duration: animationsDisabled
                    ? Duration.zero
                    : const Duration(milliseconds: 850),
                curve: Curves.easeInOut,
                builder: (context, opacity, child) => Opacity(
                  opacity: animationsDisabled ? 0.72 : opacity,
                  child: child,
                ),
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(20, 28, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SkeletonShape(
                        key: Key('bootstrap-hero-shape'),
                        height: 220,
                        radius: 30,
                      ),
                      SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _SkeletonShape(width: 176, height: 18),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        child: _SkeletonShape(
                          key: Key('bootstrap-card-shape'),
                          height: 112,
                          radius: 24,
                        ),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        child: _SkeletonShape(
                          key: Key('bootstrap-card-shape'),
                          height: 92,
                          radius: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonShape extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const _SkeletonShape({
    super.key,
    this.width,
    required this.height,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0x1F135F9E)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x12135F9E),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
    ),
  );
}

class _BootstrapError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _BootstrapError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFEEF7FF),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.errorGeneric(error),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF123B5D),
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onRetry,
                  child: const Text(AppStrings.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
