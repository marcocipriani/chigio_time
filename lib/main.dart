import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'shared/providers/global_providers.dart';
import 'core/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Transparent status bar so the glass design bleeds to the top
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  await Future.wait([
    initializeDateFormatting('it_IT', null),
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
  ]);

  // Must be registered before any other FirebaseMessaging calls.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('chigio_themeMode') ?? 'system';
  final savedLocale = prefs.getString('chigio_locale') ?? 'it';

  runApp(
    ProviderScope(
      overrides: [
        initialThemeModeNameProvider.overrideWithValue(savedTheme),
        initialLocaleCodeProvider.overrideWithValue(savedLocale),
      ],
      child: const ChigioTimeApp(),
    ),
  );
}
