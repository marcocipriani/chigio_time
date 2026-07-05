import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/color_schemes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/chigio_quotes.dart';
import '../../../shared/widgets/app_tappable.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/home_widget_header.dart';
import '../../profile/data/profile_repository.dart';
import '../../salary/data/salary_repository.dart';
import '../../salary/domain/salary_payment.dart';
import '../../salary/presentation/salary_screen.dart' show kDefaultPaydayDay;

/// Widget Home "Stipendio": countdown al prossimo accredito + stima netto
/// dagli ultimi ordinari (stessa logica dell'hero di SalaryScreen).
/// Tap → /salary.
class SalaryCard extends ConsumerWidget {
  const SalaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments =
        ref.watch(salaryPaymentsStreamProvider).asData?.value ?? [];
    final profile = ref.watch(userProfileStreamProvider).asData?.value;
    final paydayDay =
        (profile?['paydayDay'] as num?)?.toInt() ?? kDefaultPaydayDay;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var next = DateTime(today.year, today.month, paydayDay.clamp(1, 28));
    if (next.isBefore(today)) {
      next = DateTime(today.year, today.month + 1, paydayDay.clamp(1, 28));
    }
    final days = next.difference(today).inDays;

    // Stima dagli ultimi 3 accrediti ordinari.
    final ordinary = payments
        .where((p) => p.type == SalaryPaymentType.ordinaria && p.netAmount > 0)
        .take(3)
        .toList();
    final estimate = ordinary.isEmpty
        ? null
        : ordinary.fold<double>(0, (a, p) => a + p.netAmount) / ordinary.length;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : AppColors.neutral600;

    return AppTappable(
      onTap: () => context.go('/salary'),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeWidgetHeader(
              pose: ChigioQuotes.festeggia,
              title: AppStrings.salaryWidgetTitle,
              accent: AppColors.green600,
              subtitle:
                  '${AppStrings.weekdaysFull[next.weekday - 1]} '
                  '${next.day} ${AppStrings.months[next.month - 1].toLowerCase()}',
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.green600.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  AppStrings.salaryDaysTo(days),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.green600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (estimate != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '€ ${estimate.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.92)
                          : AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      AppStrings.salaryEstimated,
                      style: TextStyle(fontSize: 11, color: textSub),
                    ),
                  ),
                ],
              )
            else
              HomeWidgetEmpty(
                message: AppStrings.salaryNoData,
                ctaLabel: AppStrings.salaryOpen,
                onCta: () => context.go('/salary'),
              ),
          ],
        ),
      ),
    );
  }
}
