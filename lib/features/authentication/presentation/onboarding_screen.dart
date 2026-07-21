import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_provider.dart';
import '../../../shared/providers/global_providers.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../app/theme/color_schemes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/chigio_quotes.dart';
import '../../../core/data/pcm_locations_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../../shared/widgets/app_tappable.dart';
import '../../../shared/widgets/pcm_assignment_form.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static const int _totalSteps = 9;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stepColors = [
      AppColors.blue600,
      AppColors.blue600,
      AppColors.green600,
      AppColors.blue600,
      AppColors.blue600,
      AppColors.blue600,
      AppColors.green600,
      AppColors.blue600,
      AppColors.orange600,
      AppColors.blue600,
      AppColors.blue600,
      AppColors.orange600,
    ];
    final currentColor =
        stepColors[state.currentStep.clamp(0, stepColors.length - 1)];

    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppColors.neutral600;

    String formatMins(int m) {
      return '${m ~/ 60}h ${(m % 60).toString().padLeft(2, '0')}m';
    }

    bool isDailyAltered() {
      if (state.employmentType == AppStrings.etRuolo) {
        return state.standardDailyHours.inMinutes != 456;
      }
      if (state.employmentType == AppStrings.etComando) {
        return state.standardDailyHours.inMinutes != 432;
      }
      return false;
    }

    bool isMealAltered() {
      if (state.employmentType == AppStrings.etRuolo ||
          state.employmentType == AppStrings.etComando) {
        return state.mealVoucherThreshold.inMinutes != 380;
      }
      return false;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Progress dots
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_totalSteps, (i) {
                    final active = i == state.currentStep;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: active
                            ? currentColor
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.black.withValues(alpha: 0.12)),
                      ),
                    );
                  }),
                ),
              ),

              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: _buildStep(
                    context,
                    ref,
                    state,
                    notifier,
                    isDark,
                    textMain,
                    textSub,
                    currentColor,
                    formatMins,
                    isDailyAltered,
                    isMealAltered,
                  ),
                ),
              ),

              // Nav buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (state.currentStep > 0)
                      TextButton(
                        onPressed: notifier.previousStep,
                        child: Text(
                          AppStrings.back,
                          style: TextStyle(
                            color: AppColors.blue400,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    GlassBtn(
                      label: state.currentStep == _totalSteps - 1
                          ? AppStrings.finishEmoji
                          : AppStrings.next,
                      fullWidth: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      onPressed: () async {
                        if (state.currentStep < _totalSteps - 1) {
                          if (state.currentStep == 1 &&
                              state.name.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(AppStrings.enterNameToContinue),
                              ),
                            );
                            return;
                          }
                          if (state.currentStep == 2 &&
                              state.administration.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  AppStrings.administrationRequired,
                                ),
                              ),
                            );
                            return;
                          }
                          if (state.currentStep == 3 &&
                              state.employmentType.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  AppStrings.selectYourEmploymentType,
                                ),
                              ),
                            );
                            return;
                          }
                          final isCcnlStep5 =
                              state.currentStep == 4 &&
                              (state.employmentType == AppStrings.etRuolo ||
                                  state.employmentType == AppStrings.etComando);
                          if (isCcnlStep5 &&
                              state.scheduleVariant == 'mixed' &&
                              state.longWorkDays.length != 2) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(AppStrings.longWorkDaysTooFew),
                              ),
                            );
                            return;
                          }
                          notifier.nextStep();
                        } else {
                          if (state.dipartimento.isEmpty ||
                              state.sedeId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(AppStrings.pcmAssignmentRequired),
                              ),
                            );
                            return;
                          }
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                          final nav = Navigator.of(
                            context,
                            rootNavigator: true,
                          );
                          try {
                            await ref
                                .read(profileRepositoryProvider)
                                .saveOnboardingData(state);
                            // Just pop the loading dialog. Do NOT navigate
                            // manually: the saved Firestore doc flips
                            // hasProfileStreamProvider to true, and the router
                            // redirect moves /onboarding → /dashboard reactively.
                            // A manual go('/dashboard') here would race the
                            // stream (still stale `false` when the local write
                            // resolves) and bounce back through /onboarding.
                            nav.pop();
                          } catch (e) {
                            nav.pop();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppStrings.errorSave(e)),
                                  backgroundColor: AppColors.red700,
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    WidgetRef ref,
    OnboardingState state,
    Onboarding notifier,
    bool isDark,
    Color textMain,
    Color textSub,
    Color stepColor,
    String Function(int) formatMins,
    bool Function() isDailyAltered,
    bool Function() isMealAltered,
  ) {
    Widget stepContent;

    switch (state.currentStep) {
      case 0:
        stepContent = _centeredText(
          key: const ValueKey(0),
          icon: '',
          iconWidget: Image.asset(
            ChigioQuotes.ciao,
            height: 120,
            fit: BoxFit.contain,
          ),
          title: AppStrings.welcomeToChigioTime,
          body: AppStrings.onboardingIntro,
          isDark: isDark,
        );

      case 1:
        stepContent = _stepContainer(
          key: const ValueKey(1),
          icon: '👤',
          title: AppStrings.whoAreYouTitle,
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                style: TextStyle(fontSize: 16, color: textMain),
                onChanged: notifier.setName,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: AppStrings.yourFullName,
                  hintStyle: TextStyle(color: textSub),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.chigioWillUseRightGender,
                style: TextStyle(fontSize: 13, color: textSub),
              ),
              const SizedBox(height: 12),
              Row(
                children:
                    [
                      ('M', AppStrings.genderMale, AppColors.blue600),
                      ('F', AppStrings.genderFemale, AppColors.green600),
                      ('A', AppStrings.genderOtherShort, AppColors.orange600),
                    ].map((t) {
                      final (val, label, color) = t;
                      final selected = state.gender == val;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: AppTappable(
                            onTap: () => notifier.setGender(val),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              height: 60,
                              decoration: BoxDecoration(
                                color: selected
                                    ? color.withValues(alpha: 0.15)
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : Colors.black.withValues(
                                              alpha: 0.04,
                                            )),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selected ? color : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? color
                                        : (isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.6,
                                                )
                                              : AppColors.neutral600),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 10),
              Text(
                AppStrings.youCanChangeItLaterFromProfile,
                style: TextStyle(fontSize: 11, color: textSub),
              ),
            ],
          ),
        );

      case 2:
        stepContent = _stepContainer(
          key: const ValueKey(2),
          icon: '🏛️',
          title: AppStrings.whereDoYouWork,
          isDark: isDark,
          child: Autocomplete<String>(
            initialValue: TextEditingValue(text: state.administration),
            optionsBuilder: (v) {
              const options = [AppStrings.appOrg];
              if (v.text.isEmpty) return const Iterable<String>.empty();
              return options.where(
                (o) => o.toLowerCase().contains(v.text.toLowerCase()),
              );
            },
            onSelected: notifier.setAdministration,
            fieldViewBuilder: (_, ctrl, fn, _) => TextField(
              controller: ctrl,
              focusNode: fn,
              style: TextStyle(fontSize: 16, color: textMain),
              onChanged: notifier.setAdministration,
              decoration: InputDecoration(
                hintText: AppStrings.administrationHint,
                hintStyle: TextStyle(color: textSub),
              ),
            ),
          ),
        );

      case 3:
        stepContent = _stepContainer(
          key: const ValueKey(3),
          icon: '📋',
          title: AppStrings.employmentType,
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ContractChip(
                    label: AppStrings.etRuolo,
                    color: AppColors.blue600,
                    selected: state.employmentType == AppStrings.etRuolo,
                    isDark: isDark,
                    onTap: () => notifier.setEmploymentType(AppStrings.etRuolo),
                  ),
                  _ContractChip(
                    label: AppStrings.etComando,
                    color: AppColors.green600,
                    selected: state.employmentType == AppStrings.etComando,
                    isDark: isDark,
                    onTap: () =>
                        notifier.setEmploymentType(AppStrings.etComando),
                  ),
                  _ContractChip(
                    label: AppStrings.etAltro,
                    color: AppColors.neutral600,
                    selected: state.employmentType == AppStrings.etAltro,
                    isDark: isDark,
                    onTap: () => notifier.setEmploymentType(AppStrings.etAltro),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Data presa servizio (mai nel futuro)
              AppTappable(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: state.hireDate ?? now,
                    firstDate: DateTime(1980),
                    lastDate: now,
                    helpText: AppStrings.hireDateLabel.toUpperCase(),
                  );
                  if (picked != null) notifier.setHireDate(picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Text('📅', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppStrings.hireDateLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textMain,
                          ),
                        ),
                      ),
                      Text(
                        state.hireDate != null
                            ? '${state.hireDate!.day.toString().padLeft(2, '0')}/${state.hireDate!.month.toString().padLeft(2, '0')}/${state.hireDate!.year}'
                            : AppStrings.hireDatePick,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

      case 4:
        final isCcnl =
            state.employmentType == AppStrings.etRuolo ||
            state.employmentType == AppStrings.etComando;
        final isMixed = state.scheduleVariant == 'mixed';
        stepContent = _stepContainer(
          key: const ValueKey(4),
          icon: '🗓️',
          title: isCcnl
              ? AppStrings.scheduleVariantTitle
              : AppStrings.standardSchedule,
          isDark: isDark,
          child: isCcnl
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _VariantChip(
                          label: AppStrings.scheduleVariantUniform,
                          subtitle: AppStrings.scheduleVariantUniformDesc,
                          selected: !isMixed,
                          color: AppColors.blue600,
                          isDark: isDark,
                          onTap: () => notifier.setScheduleVariant('uniform'),
                        ),
                        const SizedBox(width: 10),
                        _VariantChip(
                          label: AppStrings.scheduleVariantMixed,
                          subtitle: AppStrings.scheduleVariantMixedDesc,
                          selected: isMixed,
                          color: AppColors.green600,
                          isDark: isDark,
                          onTap: () => notifier.setScheduleVariant('mixed'),
                        ),
                      ],
                    ),
                    if (isMixed) ...[
                      const SizedBox(height: 20),
                      Text(
                        AppStrings.longWorkDaysLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.longWorkDaysHint,
                        style: TextStyle(fontSize: 11, color: textSub),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(5, (i) {
                          final weekday = i + 1; // 1=Mon…5=Fri
                          final label = AppStrings.weekdaysShort[i];
                          final selected = state.longWorkDays.contains(weekday);
                          final disabled =
                              !selected && state.longWorkDays.length >= 2;
                          return AppTappable(
                            onTap: disabled
                                ? null
                                : () => notifier.toggleLongWorkDay(weekday),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? AppColors.green600.withValues(alpha: 0.15)
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : Colors.black.withValues(
                                              alpha: 0.04,
                                            )),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.green600
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? AppColors.green600
                                        : (disabled
                                              ? (isDark
                                                    ? Colors.white.withValues(
                                                        alpha: 0.2,
                                                      )
                                                    : AppColors.neutral400)
                                              : textSub),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                )
              : Column(
                  children: [
                    Text(
                      formatMins(state.standardDailyHours.inMinutes),
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: stepColor,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: stepColor,
                        thumbColor: stepColor,
                        inactiveTrackColor: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.12),
                      ),
                      child: Slider(
                        value: state.standardDailyHours.inMinutes.toDouble(),
                        min: 360,
                        max: 540,
                        divisions: 36,
                        onChanged: (v) => notifier.addDailyMinutes(
                          v.toInt() - state.standardDailyHours.inMinutes,
                        ),
                      ),
                    ),
                    GlassCard(
                      radius: 14,
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        AppStrings.scheduleAltroHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSub,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
        );

      case 5:
        stepContent = _stepContainer(
          key: const ValueKey(5),
          icon: '🍽️',
          title: AppStrings.mealVoucherThresholdTitle,
          isDark: isDark,
          child: Column(
            children: [
              Text(
                formatMins(state.mealVoucherThreshold.inMinutes),
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: stepColor,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 12),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppColors.green600,
                  thumbColor: AppColors.green600,
                  inactiveTrackColor: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.12),
                ),
                child: Slider(
                  value: state.mealVoucherThreshold.inMinutes.toDouble(),
                  min: 240,
                  max: 480,
                  divisions: 48,
                  onChanged: (v) => notifier.addMealMinutes(
                    v.toInt() - state.mealVoucherThreshold.inMinutes,
                  ),
                ),
              ),
              GlassCard(
                radius: 14,
                padding: const EdgeInsets.all(12),
                overrideColor: isDark
                    ? AppColors.green700.withValues(alpha: 0.2)
                    : AppColors.green600.withValues(alpha: 0.08),
                child: Text(
                  AppStrings.usuallyMealThresholdNote,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.green600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );

      case 6:
        final isCcnlArt9 =
            state.employmentType == AppStrings.etRuolo ||
            state.employmentType == AppStrings.etComando;
        final art9Max = state.employmentType == AppStrings.etComando ? 17 : 8;
        final art9MaxLabel = state.employmentType == AppStrings.etComando
            ? AppStrings.art9MaxLabelComando
            : AppStrings.art9MaxLabelRuolo;
        final tetto = state.monthlySliHours + state.monthlySboHours;
        stepContent = _stepContainer(
          key: const ValueKey(6),
          icon: '📑',
          title: AppStrings.sauStepTitle,
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Art. 9: 0 oppure il massimo dell'inquadramento ──
              Text(
                AppStrings.art9StepTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textSub,
                ),
              ),
              const SizedBox(height: 10),
              if (isCcnlArt9)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ContractChip(
                      label: AppStrings.art9ZeroLabel,
                      color: AppColors.neutral600,
                      selected: state.monthlyArt9Hours == 0,
                      isDark: isDark,
                      onTap: () =>
                          notifier.addArt9Hours(0 - state.monthlyArt9Hours),
                    ),
                    const SizedBox(width: 12),
                    _ContractChip(
                      label: art9MaxLabel,
                      color: AppColors.blue600,
                      selected: state.monthlyArt9Hours == art9Max,
                      isDark: isDark,
                      onTap: () => notifier.addArt9Hours(
                        art9Max - state.monthlyArt9Hours,
                      ),
                    ),
                  ],
                )
              else
                GlassCard(
                  radius: 14,
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    AppStrings.art9AltroHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: textSub),
                  ),
                ),
              const SizedBox(height: 16),
              Divider(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              const SizedBox(height: 12),

              // ── SLI + SBO (SLI + SBO = SAU) ──
              Text(
                AppStrings.sliHoursValue(state.monthlySliHours),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: stepColor,
                  letterSpacing: -1,
                ),
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: stepColor,
                  thumbColor: stepColor,
                  inactiveTrackColor: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.12),
                ),
                child: Slider(
                  value: state.monthlySliHours.toDouble(),
                  min: 0,
                  max: 20,
                  divisions: 20,
                  onChanged: (v) => notifier.setMonthlySliHours(v.toInt()),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.sboHoursValue(state.monthlySboHours),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.orange600,
                  letterSpacing: -1,
                ),
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppColors.orange600,
                  thumbColor: AppColors.orange600,
                  inactiveTrackColor: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.12),
                ),
                child: Slider(
                  value: state.monthlySboHours.toDouble(),
                  min: 0,
                  max: 20,
                  divisions: 20,
                  onChanged: (v) => notifier.setMonthlySboHours(v.toInt()),
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                radius: 14,
                padding: const EdgeInsets.all(14),
                overrideColor: isDark
                    ? AppColors.orange600.withValues(alpha: 0.12)
                    : AppColors.orange600.withValues(alpha: 0.07),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.sauLabel(tetto),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.orange600,
                      ),
                    ),
                    Text(
                      AppStrings.sliSboLegend,
                      style: TextStyle(fontSize: 10, color: textSub),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.sliSboCapNote,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: textSub),
              ),
            ],
          ),
        );

      case 7:
        stepContent = _stepContainer(
          key: const ValueKey(7),
          icon: '🌗',
          title: AppStrings.preferredTheme,
          isDark: isDark,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ThemeChip(
                label: AppStrings.themeLight,
                icon: Icons.light_mode_rounded,
                selected: state.themePreference == ThemeMode.light,
                isDark: isDark,
                onTap: () {
                  notifier.setThemePreference(ThemeMode.light);
                  ref
                      .read(themeModeProvider.notifier)
                      .setTheme(ThemeMode.light);
                },
              ),
              _ThemeChip(
                label: AppStrings.themeDark,
                icon: Icons.dark_mode_rounded,
                selected: state.themePreference == ThemeMode.dark,
                isDark: isDark,
                onTap: () {
                  notifier.setThemePreference(ThemeMode.dark);
                  ref.read(themeModeProvider.notifier).setTheme(ThemeMode.dark);
                },
              ),
            ],
          ),
        );

      case 8:
        final catalogAsync = ref.watch(pcmCatalogProvider);
        stepContent = _stepContainer(
          key: const ValueKey(8),
          icon: '🏢',
          title: AppStrings.dipartimentoAndSedeTitle,
          isDark: isDark,
          child: catalogAsync.when(
            data: (catalog) => PcmAssignmentForm(
              structures: catalog.structures,
              structureName: state.dipartimento,
              siteId: state.sedeId,
              onStructureSelected: notifier.setDipartimento,
              onSiteSelected: (site) => notifier.setOfficeLocation(
                id: site.id,
                sede: site.name,
                address: site.fullAddress,
                latitude: site.latitude,
                longitude: site.longitude,
              ),
            ),
            error: (_, _) => Column(
              children: [
                const Text(AppStrings.pcmCatalogUnavailable),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.invalidate(pcmCatalogLoadProvider),
                  child: const Text(AppStrings.retry),
                ),
              ],
            ),
            loading: () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(999),
                  color: stepColor,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.loadingPcmSites,
                  style: TextStyle(fontSize: 12, color: textSub),
                ),
              ],
            ),
          ),
        );

      default:
        stepContent = const SizedBox.shrink(key: ValueKey('empty'));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: stepContent,
    );
  }

  Widget _centeredText({
    required Key key,
    required String icon,
    required String title,
    required String body,
    required bool isDark,
    Widget? iconWidget,
  }) {
    return Column(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        iconWidget ?? Text(icon, style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark
                ? Colors.white.withValues(alpha: 0.9)
                : AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.65)
                  : AppColors.neutral700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepContainer({
    required Key key,
    required String icon,
    required String title,
    required Widget child,
    required bool isDark,
  }) {
    // Scrollabile: gli step accorpati (chi sei, SAU) superano l'altezza
    // dei telefoni piccoli.
    return Center(
      key: key,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 24),
            GlassCard(child: child),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _VariantChip extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _VariantChip({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppTappable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.12)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected
                      ? color
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppColors.neutral700),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: selected
                      ? color.withValues(alpha: 0.8)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : AppColors.neutral400),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContractChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _ContractChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppTappable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 96,
        height: 52,
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? color
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : AppColors.neutral600),
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppTappable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 130,
        height: 110,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.blue600.withValues(alpha: 0.12)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.blue600 : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 36,
              color: selected ? AppColors.blue600 : AppColors.neutral400,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.blue600 : AppColors.neutral600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
