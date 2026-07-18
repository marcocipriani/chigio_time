import 'package:flutter/foundation.dart';
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
import 'core/services/notification_routing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Transparent status bar so the glass design bleeds to the top
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // Font loading strategy (2026-07-05): the previous code awaited
  // notoColorEmoji too — a ~10 MB color-emoji TTF fetched from the Google
  // Fonts CDN — which BLOCKED the first frame and made the Home slow to
  // appear on web/cold-start.
  //
  // Now we block only on the small fonts needed to render text without tofu:
  //   • Plus Jakarta Sans (primary UI font)
  //   • Noto Sans          → Latin Extended, incl. schwa "ə" (inclusive IT)
  //   • Noto Sans Symbols  → arrows/math/geometric (→ − ≈ ↑ ↓ ▶)
  //   • Noto Sans Symbols2 → monochrome symbols (⚠ ☕ ✓ …)
  // The heavy color-emoji font is preloaded WITHOUT blocking: color emoji may
  // pop in a beat late on a cold web load instead of freezing the whole Home.
  // Wrapped in try-catch so an offline first launch still starts the app.
  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.plusJakartaSans(),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
      GoogleFonts.notoSans(),
      GoogleFonts.notoSansSymbols(),
      GoogleFonts.notoSansSymbols2(),
    ]);
  } catch (_) {
    // Offline or font CDN unavailable — app works; some glyphs may show tofu
    // on first cold-start without network.
  }
  // Non-blocking: warms the color-emoji cache without delaying the first frame.
  () async {
    try {
      await GoogleFonts.pendingFonts([GoogleFonts.notoColorEmoji()]);
    } catch (_) {}
  }();

  await Future.wait([
    initializeDateFormatting('it_IT', null),
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
  ]);

  // Must be registered before any other FirebaseMessaging calls.
  if (supportsFcm(defaultTargetPlatform, isWeb: kIsWeb)) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

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
