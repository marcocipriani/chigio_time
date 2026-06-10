import 'package:flutter/material.dart';

class AppColors {
  // Brand Blues
  static const Color blue900 = Color(0xFF002d6b);
  static const Color blue800 = Color(0xFF003d8f);
  static const Color blue700 = Color(0xFF004aab);
  static const Color blue600 = Color(0xFF0055A5);
  static const Color blue500 = Color(0xFF1a6dbf);
  static const Color blue400 = Color(0xFF4d91d4);
  static const Color blue300 = Color(0xFF80b4e6);
  static const Color blue200 = Color(0xFFb3d4f2);
  static const Color blue100 = Color(0xFFd6eafc);
  static const Color blue50 = Color(0xFFebf4ff);

  // Success Greens
  static const Color green900 = Color(0xFF003d35);
  static const Color green700 = Color(0xFF00574e);
  static const Color green600 = Color(0xFF00796B);
  static const Color green500 = Color(0xFF4CAF50);
  static const Color green300 = Color(0xFF81c784);
  static const Color green100 = Color(0xFFc8e6c9);
  static const Color green50 = Color(0xFFe8f5e9);

  // Alert Oranges
  static const Color orange900 = Color(0xFF7c2800);
  static const Color orange700 = Color(0xFFbf360c);
  static const Color orange600 = Color(0xFFE65100);
  static const Color orange500 = Color(0xFFFF9800);
  static const Color orange300 = Color(0xFFffb74d);
  static const Color orange100 = Color(0xFFffe0b2);
  static const Color orange50 = Color(0xFFfff3e0);

  // Accent Purples (permesso/assenza)
  static const Color purple600 = Color(0xFF6A35A8);
  static const Color purple100 = Color(0xFFE8D5F5);

  // Accent Ambers (ferie/holiday)
  static const Color amber600 = Color(0xFFF59E0B);
  static const Color amber100 = Color(0xFFFEF3C7);

  // Error Reds
  static const Color red700 = Color(0xFFD32F2F);
  static const Color red300 = Color(0xFFEF9A9A);
  static const Color red100 = Color(0xFFffcdd2);
  static const Color red50 = Color(0xFFffebee);

  // Neutrals
  static const Color neutral900 = Color(0xFF1a1a2e);
  static const Color neutral800 = Color(0xFF2d2d44);
  static const Color neutral700 = Color(0xFF4a4a6a);
  static const Color neutral600 = Color(0xFF6b6b8a);
  static const Color neutral400 = Color(0xFF9e9eb8);
  static const Color neutral300 = Color(0xFFc5c5d8);
  static const Color neutral200 = Color(0xFFe2e2ed);
  static const Color neutral100 = Color(0xFFeeeeee);
  static const Color neutral50 = Color(0xFFf7f7fc);
  static const Color white = Color(0xFFffffff);

  // Background gradients
  static const Gradient lightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFbcd8f5), Color(0xFFb8d8ec), Color(0xFFc4edd8)],
    stops: [0.0, 0.5, 1.0],
  );

  static const Gradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF060616), Color(0xFF0b1028), Color(0xFF071420)],
    stops: [0.0, 0.5, 1.0],
  );
}

class AppColorSchemes {
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.blue600,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.blue100,
    onPrimaryContainer: AppColors.blue900,
    secondary: AppColors.green600,
    onSecondary: AppColors.white,
    secondaryContainer: AppColors.green100,
    onSecondaryContainer: AppColors.green900,
    tertiary: AppColors.orange600,
    onTertiary: AppColors.white,
    tertiaryContainer: AppColors.orange100,
    onTertiaryContainer: AppColors.orange900,
    error: AppColors.red700,
    onError: AppColors.white,
    errorContainer: AppColors.red100,
    onErrorContainer: AppColors.red700,
    surface: AppColors.white,
    onSurface: AppColors.neutral900,
    surfaceContainerHighest: Color(0xFFe8eef8),
    onSurfaceVariant: AppColors.neutral700,
    outline: AppColors.neutral300,
    outlineVariant: AppColors.neutral200,
  );

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.blue400,
    onPrimary: AppColors.blue900,
    primaryContainer: AppColors.blue800,
    onPrimaryContainer: AppColors.blue100,
    secondary: AppColors.green500,
    onSecondary: AppColors.green900,
    secondaryContainer: AppColors.green700,
    onSecondaryContainer: AppColors.green100,
    tertiary: AppColors.orange500,
    onTertiary: AppColors.orange900,
    tertiaryContainer: AppColors.orange700,
    onTertiaryContainer: AppColors.orange100,
    error: AppColors.red300,
    onError: AppColors.red700,
    errorContainer: Color(0xFF7c2828),
    onErrorContainer: AppColors.red100,
    surface: Color(0xFF0b1028),
    onSurface: Color(0xFFe8eaf0),
    surfaceContainerHighest: Color(0xFF1a2040),
    onSurfaceVariant: AppColors.neutral300,
    outline: AppColors.neutral700,
    outlineVariant: AppColors.neutral800,
  );
}
