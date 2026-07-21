import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'routes/app_router.dart';
import '../shared/providers/global_providers.dart';
import '../shared/widgets/app_background.dart';
import '../shared/widgets/pcm_assignment_gate.dart';
import '../features/authentication/data/auth_repository.dart';
import '../core/services/fcm_service.dart';
import '../core/services/notification_routing.dart';
import '../core/constants/app_strings.dart';

const double kDesktopBreakpoint = 800.0;

class ChigioTimeApp extends ConsumerStatefulWidget {
  const ChigioTimeApp({super.key});

  @override
  ConsumerState<ChigioTimeApp> createState() => _ChigioTimeAppState();
}

class _ChigioTimeAppState extends ConsumerState<ChigioTimeApp> {
  StreamSubscription<RemoteMessage>? _bgTapSub;
  StreamSubscription<RemoteMessage>? _fgSub;
  AppLifecycleListener? _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _setupFcmTapHandlers();
    _lifecycleListener = AppLifecycleListener(
      onResume: () => ref.read(themeModeProvider.notifier).refreshAutoTheme(),
    );
  }

  void _setupFcmTapHandlers() {
    final fcm = ref.read(fcmServiceProvider);

    // App launched from terminated state via notification tap.
    fcm.handleInitialMessage((route) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        rootNavigatorKey.currentContext?.go(route);
      });
    });

    // App foregrounded from background via notification tap.
    _bgTapSub = fcm.handleMessageOpenedApp(
      (route) => rootNavigatorKey.currentContext?.go(route),
    );

    // Foreground push → SnackBar.
    _fgSub = fcm.onForegroundMessage.listen(_showForegroundSnack);
  }

  void _showForegroundSnack(RemoteMessage message) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !mounted) return;
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';
    ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🔔 ', style: TextStyle(fontSize: 18)),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  if (body.isNotEmpty)
                    Text(body, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: AppStrings.view,
          onPressed: () => rootNavigatorKey.currentContext?.go(
            notificationRoute(message.data),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bgTapSub?.cancel();
    _fgSub?.cancel();
    _lifecycleListener?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(localeProvider);

    ref.listen(authStateChangesProvider, (_, next) {
      final authData = next.asData;
      if (authData == null) return;

      final fcm = ref.read(fcmServiceProvider);
      final uid = authData.value?.uid;
      if (uid == null) {
        fcm.deactivate();
      } else {
        unawaited(fcm.init(uid));
      }
    });

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      locale: currentLocale,
      supportedLocales: const [Locale('it'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: currentThemeMode,
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) =>
          PcmAssignmentGate(child: AppBackground(child: child!)),
    );
  }
}
