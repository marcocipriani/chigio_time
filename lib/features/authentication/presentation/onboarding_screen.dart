import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'onboarding_provider.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Osserviamo lo stato (si aggiorna automaticamente quando cambi i valori)
    final state = ref.watch(onboardingProvider);
    
    // 2. Leggiamo il notifier per chiamare i metodi (setStandardHours, nextStep, etc.)
    final notifier = ref.read(onboardingProvider.notifier);
    
    final theme = Theme.of(context);

    // Helper per formattare la durata (es. 7h 36m)
    String formatDuration(Duration d) => "${d.inHours}h ${d.inMinutes.remainder(60)}m";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Configura Orario"),
        // Barra di progresso in alto
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (state.currentStep + 1) / 3, // 3 step totali
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Expanded(
              // Animazione fluida al cambio di step
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildStepContent(context, state, notifier, formatDuration),
              ),
            ),
            
            // Bottoni Navigazione in basso
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Bottone Indietro / Salta
                if (state.currentStep > 0)
                  TextButton(
                    onPressed: notifier.previousStep,
                    child: const Text("Indietro"),
                  )
                else
                  TextButton(
                    onPressed: () => context.go('/home'), // Salta configurazione
                    child: const Text("Salta"),
                  ),
                  
                // Bottone Avanti / Fine
                FilledButton(
                  onPressed: () {
                    if (state.currentStep < 2) {
                      notifier.nextStep();
                    } else {
                      // Fine Wizard -> Vai alla Dashboard
                      // TODO: Qui salveremo i dati su Database Locale/Remoto
                      context.go('/home');
                    }
                  },
                  child: Text(state.currentStep == 2 ? "Fine" : "Avanti"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Costruisce il contenuto centrale in base allo step corrente
  Widget _buildStepContent(
    BuildContext context, 
    OnboardingState state, 
    Onboarding notifier, // Tipo corretto del notifier generato
    String Function(Duration) format,
  ) {
    final theme = Theme.of(context);
    
    switch (state.currentStep) {
      case 0: // Step 1: Orario Standard
        return Column(
          key: const ValueKey(0),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            Text("Orario Giornaliero", style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text("Quanto devi lavorare ogni giorno?"),
            const SizedBox(height: 48),
            
            // Display ore
            Text(format(state.standardDailyHours), style: theme.textTheme.displaySmall),
            
            // Slider minuti totali
            Slider(
              value: state.standardDailyHours.inMinutes.toDouble(),
              min: 6 * 60, // Minimo 6 ore
              max: 9 * 60, // Massimo 9 ore
              divisions: 36, // Scatti da 5 minuti
              label: format(state.standardDailyHours),
              onChanged: (val) {
                notifier.setStandardHours(0, val.toInt());
              },
            ),
            const SizedBox(height: 16),
            
            // Chips per selezione rapida
            Wrap(
              spacing: 8,
              children: [
                _PresetChip("7h 12m", () => notifier.setStandardHours(7, 12)),
                _PresetChip("7h 36m", () => notifier.setStandardHours(7, 36)),
                _PresetChip("8h 00m", () => notifier.setStandardHours(8, 0)),
              ],
            )
          ],
        );

      case 1: // Step 2: Soglie e Cancelli
        return Column(
          key: const ValueKey(1),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant, size: 64, color: Colors.orange),
            const SizedBox(height: 24),
            Text("Soglie & Buono Pasto", style: theme.textTheme.headlineSmall),
            const SizedBox(height: 48),
            
            Text("Minimo per Buono Pasto: ${format(state.mealVoucherThreshold)}"),
            Slider(
              value: state.mealVoucherThreshold.inMinutes.toDouble(),
              min: 4 * 60,
              max: 8 * 60,
              onChanged: (val) => notifier.setMealThreshold(0, val.toInt()),
            ),
          ],
        );

      case 2: // Step 3: Tetto Straordinari
        return Column(
          key: const ValueKey(2),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber, size: 64, color: Colors.red),
            const SizedBox(height: 24),
            Text("Tetto Straordinari", style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text("Ore massime accumulabili al mese"),
            const SizedBox(height: 48),
            
            Text("${state.monthlyOvertimeCapHours} ore", style: theme.textTheme.displaySmall),
            Slider(
              value: state.monthlyOvertimeCapHours.toDouble(),
              min: 0,
              max: 50,
              divisions: 50,
              onChanged: (val) => notifier.setOvertimeCap(val.toInt()),
            ),
          ],
        );
        
      default:
        return const SizedBox.shrink();
    }
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PresetChip(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text(label), onPressed: onTap);
  }
}