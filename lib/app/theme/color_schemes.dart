import 'package:flutter/material.dart';

class AppColorSchemes {
  // Generiamo una palette completa basata su un colore "Professional Blue"
  // Tipico per app istituzionali/Circolo Chigi
  static final lightColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0055A5), // Blu istituzionale
    brightness: Brightness.light,
    
    // Override per colori funzionali specifici richiesti dal documento 
    primary: const Color(0xFF0055A5),
    secondary: const Color(0xFF00796B), // Verde (Lavoro normale)
    tertiary: const Color(0xFFE65100),  // Arancione (Straordinario)
    error: const Color(0xFFD32F2F),     // Rosso (Pausa/Errori)
  );

  static final darkColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0055A5),
    brightness: Brightness.dark,
  );
  
  // Colori specifici per la Timeline [cite: 209-213]
  static const Color timelinePrePost = Color(0xFFEEEEEE);
  static const Color timelineNormal = Color(0xFF4CAF50); // Verde
  static const Color timelineOvertime = Color(0xFFFF9800); // Arancione
  static const Color timelineLunch = Color(0xFFEF9A9A); // Rosso chiaro
}