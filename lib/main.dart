import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/app.dart';

void main() async {
  // Assicura che i binding nativi siano inizializzati
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inizializza la formattazione date per l'italiano [cite: 38]
  await initializeDateFormatting('it_IT', null);

  // TODO: Qui inizializzeremo Firebase nel prossimo step
  // await Firebase.initializeApp(...)

  runApp(
    // ProviderScope è necessario per Riverpod [cite: 18]
    const ProviderScope(
      child: ChigioTimeApp(),
    ),
  );
}