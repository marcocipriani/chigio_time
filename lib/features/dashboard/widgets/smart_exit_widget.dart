import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/color_schemes.dart';
import '../../../app/theme/text_styles.dart';
import '../presentation/dashboard_providers.dart';

class SmartExitWidget extends ConsumerWidget {
  const SmartExitWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(timesheetResultProvider);
    final theme = Theme.of(context);

    // Formatter per orari
    final timeFormat = DateFormat('HH:mm');
    final exitTimeStr = timeFormat.format(result.normalExitTime);

    return Card(
      // La card usa il tema definito in app_theme.dart (CardThemeData)
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header [cite: 141]
            Row(
              children: [
                Icon(Icons.timer_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  "La tua giornata",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                // Badge Buono Pasto [cite: 132]
                if (result.mealVoucherEarned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColorSchemes.timelineNormal.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.restaurant, size: 14, color: AppColorSchemes.timelineNormal),
                        const SizedBox(width: 4),
                        Text(
                          "Buono",
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColorSchemes.timelineNormal, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),

            // Body con orari [cite: 142]
            Center(
              child: Column(
                children: [
                  Text("Uscita prevista", style: theme.textTheme.bodyMedium),
                  Text(
                    exitTimeStr,
                    style: AppTextStyles.bigTimer.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    "Tra ${result.normalExitTime.difference(DateTime.now()).inMinutes} min", // Countdown approssimativo
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Timeline Indicator [cite: 144]
            // Visualizzazione semplificata dei "cancelli"
            SizedBox(
              height: 30,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Linea di base
                  Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Progress Bar (Ore lavorate)
                  FractionallySizedBox(
                    widthFactor: (result.workedHours.inMinutes / 600).clamp(0.0, 1.0), // clamp per demo
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Markers (Cancelli)
                  _TimelineMarker(
                    label: "Pasto",
                    color: AppColorSchemes.timelineNormal, 
                    percent: 0.65, // Posizione approssimativa buono pasto
                  ),
                  _TimelineMarker(
                    label: "Uscita",
                    color: theme.colorScheme.primary, 
                    percent: 0.8, // Posizione uscita
                    isBig: true,
                  ),
                  _TimelineMarker(
                    label: "Max",
                    color: AppColorSchemes.timelineOvertime, 
                    percent: 0.95, // Posizione straordinario
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // Footer CTA [cite: 136]
            FilledButton.icon(
              onPressed: () {
                // TODO: Navigazione a dettaglio o timbratura uscita
              },
              icon: const Icon(Icons.logout),
              label: const Text("Timbra Uscita"),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineMarker extends StatelessWidget {
  final String label;
  final Color color;
  final double percent;
  final bool isBig;

  const _TimelineMarker({
    required this.label,
    required this.color,
    required this.percent,
    this.isBig = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(percent * 2 - 1, 0), // Converte 0..1 in -1..1
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isBig ? 16 : 12,
            height: isBig ? 16 : 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.4), blurRadius: 4, spreadRadius: 1)
              ]
            ),
          ),
        ],
      ),
    );
  }
}