import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'routes/app_router.dart';

class ChigioTimeApp extends ConsumerWidget {
  const ChigioTimeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Usiamo MaterialApp.router per integrare GoRouter [cite: 51]
    return MaterialApp.router(
      title: 'Calcio Circolo Chigi', // [2026-01-07] Nome App aggiornato
      debugShowCheckedModeBanner: false,
      
      // Temi
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Segue le impostazioni di sistema
      
      // Routing
      routerConfig: goRouter,
    );
  }
}