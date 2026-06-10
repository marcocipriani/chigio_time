import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // Pre-load all fonts before the first frame so Flutter's engine never needs
  // to fall back to CDN Noto downloads (which triggers the "Could not find a
  // set of Noto fonts" warning on CanvasKit web and cold-start mobile).
  // Wrapped in try-catch so an offline first launch still starts the app.
  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.plusJakartaSans(),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
      GoogleFonts.notoColorEmoji(),
      GoogleFonts.notoSansSymbols2(),
    ]);
  } catch (_) {
    // Offline or font CDN unavailable — app works; some glyphs may show tofu
    // on first cold-start without network.
  }

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
