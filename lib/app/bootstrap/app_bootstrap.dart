import 'package:chigio_time/app/app.dart';
import 'package:chigio_time/core/constants/app_strings.dart';
import 'package:chigio_time/core/services/fcm_service.dart';
import 'package:chigio_time/core/services/notification_routing.dart';
import 'package:chigio_time/firebase_options.dart';
import 'package:chigio_time/shared/providers/global_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
