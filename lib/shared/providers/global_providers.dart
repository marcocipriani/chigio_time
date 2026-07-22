import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeKey = 'chigio_themeMode';
const _kLocaleKey = 'chigio_locale';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw StateError('sharedPreferencesProvider must be overridden'),
  name: 'sharedPreferencesProvider',
);

final initialThemeModeNameProvider = Provider<String>(
  (_) => 'system',
  name: 'initialThemeModeNameProvider',
);

final initialThemeModeProvider = Provider<ThemeMode>(
  (_) => ThemeMode.system,
  name: 'initialThemeModeProvider',
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  String _savedName = 'system';

  @override
  ThemeMode build() {
    _savedName = ref.read(initialThemeModeNameProvider);
    if (_savedName == 'auto') {
      // Re-evaluate every minute so theme switches at 06:00 and 18:00.
      final t = Timer.periodic(
        const Duration(minutes: 1),
        (_) => refreshAutoTheme(),
      );
      ref.onDispose(t.cancel);
    }
    return _effective(_savedName);
  }

  ThemeMode _effective(String name) => switch (name) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    'auto' => _byHour(),
    _ => ThemeMode.system,
  };

  ThemeMode _byHour() {
    final h = DateTime.now().hour;
    return (h >= 18 || h < 6) ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isAutoByTime => _savedName == 'auto';

  void setTheme(ThemeMode mode) {
    _savedName = mode.name;
    state = mode;
    SharedPreferences.getInstance().then(
      (p) => p.setString(_kThemeKey, mode.name),
    );
  }

  void setAutoByTime() {
    _savedName = 'auto';
    state = _byHour();
    SharedPreferences.getInstance().then(
      (p) => p.setString(_kThemeKey, 'auto'),
    );
    // Rebuild provider so build() installs the periodic timer.
    ref.invalidateSelf();
  }

  void refreshAutoTheme() {
    if (_savedName == 'auto') state = _byHour();
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

// ── Locale ────────────────────────────────────────────────────────────────────

final initialLocaleCodeProvider = Provider<String>(
  (_) => 'it',
  name: 'initialLocaleCodeProvider',
);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final code = ref.read(initialLocaleCodeProvider);
    return Locale(code);
  }

  void setLocale(String languageCode) {
    state = Locale(languageCode);
    SharedPreferences.getInstance().then(
      (p) => p.setString(_kLocaleKey, languageCode),
    );
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
