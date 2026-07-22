import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_schemes.dart';

class AppTheme {
  // fontFamilyFallback: Plus Jakarta Sans lacks emoji/symbol/latin-ext glyphs.
  // System emoji fonts cover macOS/iOS/Android/Windows; on platforms without
  // one (Linux desktop, Flutter Web CanvasKit) the engine logs "Could not find
  // a set of Noto fonts to display all missing characters" and renders tofu.
  // These Google Fonts close every gap the app actually uses:
  //   • notoColorEmoji   → color emoji 🎉🚀🏠
  //   • notoSansSymbols2 → monochrome symbols ⚠ ☕ ✓ ☎
  //   • notoSansSymbols  → arrows/math/geometric → − ≈ ↑ ↓ ▶
  //   • notoSans         → Latin Extended, incl. schwa "ə" (inclusive Italian)
  // Ordered narrow→wide. All first-frame variants resolve from bundled assets
  // behind the Flutter skeleton; only Noto Color Emoji may use the network and
  // its warm-up never blocks the ready app.
  static List<String> get _emojiFallback => [
    'Apple Color Emoji',
    'Segoe UI Emoji',
    'Noto Color Emoji',
    GoogleFonts.notoColorEmoji().fontFamily!,
    GoogleFonts.notoSansSymbols2().fontFamily!,
    GoogleFonts.notoSansSymbols().fontFamily!,
    GoogleFonts.notoSans().fontFamily!,
  ];

  static TextTheme _textTheme(ColorScheme scheme) =>
      GoogleFonts.plusJakartaSansTextTheme(
        TextTheme(
          displayLarge: TextStyle(color: scheme.onSurface),
          displayMedium: TextStyle(color: scheme.onSurface),
          displaySmall: TextStyle(color: scheme.onSurface),
          headlineLarge: TextStyle(color: scheme.onSurface),
          headlineMedium: TextStyle(color: scheme.onSurface),
          headlineSmall: TextStyle(color: scheme.onSurface),
          titleLarge: TextStyle(color: scheme.onSurface),
          titleMedium: TextStyle(color: scheme.onSurface),
          titleSmall: TextStyle(color: scheme.onSurface),
          bodyLarge: TextStyle(color: scheme.onSurface),
          bodyMedium: TextStyle(color: scheme.onSurface),
          bodySmall: TextStyle(color: scheme.onSurfaceVariant),
          labelLarge: TextStyle(color: scheme.onSurface),
          labelMedium: TextStyle(color: scheme.onSurfaceVariant),
          labelSmall: TextStyle(color: scheme.onSurfaceVariant),
        ),
      ).apply(fontFamilyFallback: _emojiFallback);

  static ThemeData get lightTheme {
    const scheme = AppColorSchemes.light;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: _textTheme(scheme),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.neutral900,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blue600,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.blue600, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: const TextStyle(color: AppColors.neutral600),
      ),
    );
  }

  static ThemeData get darkTheme {
    const scheme = AppColorSchemes.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: _textTheme(scheme),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFe8eaf0),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blue400,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.blue400, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: const TextStyle(color: AppColors.neutral400),
      ),
    );
  }
}
