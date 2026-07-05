import 'package:flutter/material.dart';

import '../../app/theme/color_schemes.dart';
import 'app_tappable.dart';
import 'chigio_mini.dart';

/// Header uniforme dei widget Home (stile "Percorsi PCM"): contenitore
/// 36×36 con mini-Chigio, titolo grande, sottotitolo opzionale, trailing.
class HomeWidgetHeader extends StatelessWidget {
  final String pose;
  final String title;
  final String? subtitle;

  /// Alternativa a [subtitle] quando serve un widget (es. month navigator).
  final Widget? subtitleWidget;
  final Widget? trailing;
  final Color accent;

  const HomeWidgetHeader({
    super.key,
    required this.pose,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.trailing,
    this.accent = AppColors.blue600,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.92)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : AppColors.neutral600;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: ChigioMini(pose, size: 24)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textMain,
                ),
              ),
              if (subtitleWidget != null)
                subtitleWidget!
              else if (subtitle != null)
                Text(subtitle!, style: TextStyle(fontSize: 11, color: textSub)),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Stato vuoto uniforme per un widget Home flaggato visibile ma senza dati:
/// messaggio + CTA. Mantiene il widget in pagina invece di nasconderlo.
class HomeWidgetEmpty extends StatelessWidget {
  final String message;
  final String ctaLabel;
  final VoidCallback onCta;

  const HomeWidgetEmpty({
    super.key,
    required this.message,
    required this.ctaLabel,
    required this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : AppColors.neutral600;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, height: 1.35, color: textSub),
            ),
          ),
          const SizedBox(width: 8),
          AppTappable(
            onTap: onCta,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.blue600.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                ctaLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
