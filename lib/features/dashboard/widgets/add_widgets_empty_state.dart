import 'package:flutter/material.dart';

import '../../../app/theme/color_schemes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/glass_card.dart';

class AddWidgetsEmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const AddWidgetsEmptyState({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark
        ? Colors.white.withValues(alpha: 0.62)
        : AppColors.neutral600;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            image: true,
            label: 'Chigio invita ad aggiungere un widget',
            child: SizedBox(
              height: 180,
              child: Image.asset(
                'assets/images/chigio-aggiungi-widget.png',
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            AppStrings.addWidgetsCtaTitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.addWidgetsCtaBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 14),
          GlassBtn(
            label: AppStrings.addWidgetsCtaBtn,
            icon: const Icon(Icons.add_rounded, size: 18),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}
