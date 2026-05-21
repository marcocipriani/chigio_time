import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_provider.dart';
import '../../../shared/providers/global_providers.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../app/theme/color_schemes.dart';
import '../../../core/constants/pcm_locations.dart';
import '../../../core/data/pcm_locations_repository.dart';
import '../../profile/data/profile_repository.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static const int _totalSteps = 12;

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
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral600;

    String formatMins(int m) {
      return '${m ~/ 60}h ${(m % 60).toString().padLeft(2, '0')}m';
    }

    bool isDailyAltered() {
      if (state.employmentType == 'Ruolo') {
        return state.standardDailyHours.inMinutes != 456;
      }
      if (state.employmentType == 'Comando') {
        return state.standardDailyHours.inMinutes != 432;
      }
      return false;
    }

    bool isMealAltered() {
      if (state.employmentType == 'Ruolo' ||
          state.employmentType == 'Comando') {
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
                    TextButton(
                      onPressed: state.currentStep > 0
                          ? (state.currentStep == 10
                                ? notifier.nextStep
                                : notifier.previousStep)
                          : null,
                      child: Text(
                        state.currentStep == 0
                            ? 'Salta'
                            : (state.currentStep == 10 ? 'Salta' : 'Indietro'),
                        style: TextStyle(
                          color: AppColors.blue400,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GlassBtn(
                      label: state.currentStep == _totalSteps - 1
                          ? 'Fine 🎉'
                          : 'Avanti',
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
                                content: Text(
                                  'Inserisci il tuo nome per continuare!',
                                ),
                              ),
                            );
                            return;
                          }
                          if (state.currentStep == 3 &&
                              state.administration.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "L'amministrazione è obbligatoria!",
                                ),
                              ),
                            );
                            return;
                          }
                          if (state.currentStep == 4 &&
                              state.employmentType.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Seleziona il tuo inquadramento!',
                                ),
                              ),
                            );
                            return;
                          }
                          notifier.nextStep();
                        } else {
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
                          final router = GoRouter.of(context);
                          try {
                            await ref
                                .read(profileRepositoryProvider)
                                .saveOnboardingData(state);
                            // Use FirebaseAuth.instance.currentUser (always
                            // synchronous) instead of the Riverpod stream
                            // value, which throws in Riverpod 3 when loading.
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool(
                                'hasProfile_${user.uid}',
                                true,
                              );
                            }
                            nav.pop();
                            router.go('/dashboard');
                          } catch (e) {
                            nav.pop();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Errore salvataggio: $e'),
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
          icon: '👋',
          title: 'Benvenuto in Chigio Time!',
          body:
              "L'app pensata per il dipendente pubblico. Traccia l'orario, gestisci gli straordinari e non perdere mai un buono pasto.",
          isDark: isDark,
        );

      case 1:
        stepContent = _stepContainer(
          key: const ValueKey(1),
          icon: '👤',
          title: 'Come ti chiami?',
          isDark: isDark,
          child: TextField(
            style: TextStyle(fontSize: 16, color: textMain),
            onChanged: notifier.setName,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Il tuo nome e cognome',
              hintStyle: TextStyle(color: textSub),
            ),
          ),
        );

      case 2:
        stepContent = _stepContainer(
          key: const ValueKey(2),
          icon: '🧬',
          title: 'Come preferisci che Chigio ti chiami?',
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Chigio userà il genere giusto nelle sue frasi.',
                style: TextStyle(fontSize: 13, color: textSub),
              ),
              const SizedBox(height: 16),
              Row(
                children:
                    [
                      ('M', '♂ Maschile', AppColors.blue600),
                      ('F', '♀ Femminile', AppColors.green600),
                      ('A', 'Altrə', AppColors.orange600),
                    ].map((t) {
                      final (val, label, color) = t;
                      final selected = state.gender == val;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
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
              const SizedBox(height: 12),
              Text(
                'Puoi cambiarlo in seguito dal profilo.',
                style: TextStyle(fontSize: 11, color: textSub),
              ),
            ],
          ),
        );

      case 3:
        stepContent = _stepContainer(
          key: const ValueKey(3),
          icon: '🏛️',
          title: 'Dove lavori?',
          isDark: isDark,
          child: Autocomplete<String>(
            initialValue: TextEditingValue(text: state.administration),
            optionsBuilder: (v) {
              const options = ['Presidenza del Consiglio dei Ministri'];
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
                hintText: 'Amministrazione',
                hintStyle: TextStyle(color: textSub),
              ),
            ),
          ),
        );

      case 4:
        stepContent = _stepContainer(
          key: const ValueKey(4),
          icon: '📋',
          title: 'Inquadramento',
          isDark: isDark,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ContractChip(
                label: 'Ruolo',
                color: AppColors.blue600,
                selected: state.employmentType == 'Ruolo',
                isDark: isDark,
                onTap: () => notifier.setEmploymentType('Ruolo'),
              ),
              _ContractChip(
                label: 'Comando',
                color: AppColors.green600,
                selected: state.employmentType == 'Comando',
                isDark: isDark,
                onTap: () => notifier.setEmploymentType('Comando'),
              ),
              _ContractChip(
                label: 'Altro',
                color: AppColors.neutral600,
                selected: state.employmentType == 'Altro',
                isDark: isDark,
                onTap: () => notifier.setEmploymentType('Altro'),
              ),
            ],
          ),
        );

      case 5:
        stepContent = _stepContainer(
          key: const ValueKey(5),
          icon: '🕐',
          title: 'Orario Standard',
          isDark: isDark,
          child: Column(
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
              if (isDailyAltered())
                Text(
                  "Differisce dallo standard '${state.employmentType}'",
                  style: const TextStyle(
                    color: AppColors.orange600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        );

      case 6:
        stepContent = _stepContainer(
          key: const ValueKey(6),
          icon: '🍽️',
          title: 'Soglia Buono Pasto',
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
                  'Di solito 6h 20m per i dipendenti pubblici (CCNL)',
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

      case 7:
        stepContent = _stepContainer(
          key: const ValueKey(7),
          icon: '📑',
          title: 'Articolo 9',
          isDark: isDark,
          child: Column(
            children: [
              Text(
                '${state.monthlyArt9Hours} ore',
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
                  activeTrackColor: AppColors.blue600,
                  thumbColor: AppColors.blue600,
                  inactiveTrackColor: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.12),
                ),
                child: Slider(
                  value: state.monthlyArt9Hours.toDouble(),
                  min: 0,
                  max: 50,
                  divisions: 50,
                  onChanged: (v) =>
                      notifier.addArt9Hours(v.toInt() - state.monthlyArt9Hours),
                ),
              ),
            ],
          ),
        );

      case 8:
        stepContent = _stepContainer(
          key: const ValueKey(8),
          icon: '⚠️',
          title: 'Tetto Straordinari',
          isDark: isDark,
          child: Column(
            children: [
              Text(
                '${state.monthlyOvertimeHours} ore',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: AppColors.orange600,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 12),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppColors.orange600,
                  thumbColor: AppColors.orange600,
                  inactiveTrackColor: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.12),
                ),
                child: Slider(
                  value: state.monthlyOvertimeHours.toDouble(),
                  min: 0,
                  max: 50,
                  divisions: 50,
                  onChanged: (v) => notifier.addOvertimeHours(
                    v.toInt() - state.monthlyOvertimeHours,
                  ),
                ),
              ),
            ],
          ),
        );

      case 9:
        stepContent = _stepContainer(
          key: const ValueKey(9),
          icon: '🌗',
          title: 'Tema preferito',
          isDark: isDark,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ThemeChip(
                label: 'Chiaro',
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
                label: 'Scuro',
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

      case 10:
        final officesAsync = ref.watch(pcmOfficeLocationsProvider);
        stepContent = _stepContainer(
          key: const ValueKey(10),
          icon: '🏢',
          title: 'Struttura e sede (opzionale)',
          isDark: isDark,
          child: officesAsync.when(
            data: (offices) => _PcmOfficeDropdown(
              offices: offices,
              state: state,
              notifier: notifier,
              isDark: isDark,
              textMain: textMain,
              textSub: textSub,
            ),
            error: (_, _) => _PcmOfficeDropdown(
              offices: activePcmOfficeSeeds(),
              state: state,
              notifier: notifier,
              isDark: isDark,
              textMain: textMain,
              textSub: textSub,
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
                const SizedBox(height: 12),
                Text(
                  'Carico le sedi PCM...',
                  style: TextStyle(fontSize: 12, color: textSub),
                ),
              ],
            ),
          ),
        );

      case 11:
        stepContent = _stepContainer(
          key: const ValueKey(11),
          icon: '📊',
          title: 'SLI / SBO mensile (opzionale)',
          isDark: isDark,
          child: Column(
            children: [
              Text(
                'SLI: ${state.monthlySliHours} ore',
                style: TextStyle(
                  fontSize: 28,
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
              const SizedBox(height: 8),
              Text(
                'SBO: ${state.monthlySboHours} ore',
                style: TextStyle(
                  fontSize: 28,
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
              const SizedBox(height: 8),
              GlassCard(
                radius: 14,
                padding: const EdgeInsets.all(12),
                child: Text(
                  'SLI = straordinario liquidato in busta  |  SBO = straordinario in banca ore',
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
  }) {
    return Column(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(icon, style: const TextStyle(fontSize: 56)),
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
    return Column(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
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
      ],
    );
  }
}

class _PcmOfficeDropdown extends StatelessWidget {
  final List<PcmOfficeOption> offices;
  final OnboardingState state;
  final Onboarding notifier;
  final bool isDark;
  final Color textMain;
  final Color textSub;

  const _PcmOfficeDropdown({
    required this.offices,
    required this.state,
    required this.notifier,
    required this.isDark,
    required this.textMain,
    required this.textSub,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...offices]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final selectedId = sorted.any((office) => office.id == state.sedeId)
        ? state.sedeId
        : null;

    if (sorted.isEmpty) {
      return Text(
        'Nessuna sede disponibile.',
        style: TextStyle(fontSize: 13, color: textSub),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(selectedId ?? 'pcm-office-empty'),
          initialValue: selectedId,
          isExpanded: true,
          menuMaxHeight: 360,
          itemHeight: 64,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: textSub),
          dropdownColor: isDark ? const Color(0xFF10102A) : Colors.white,
          decoration: InputDecoration(
            hintText: 'Seleziona struttura',
            hintStyle: TextStyle(color: textSub),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          selectedItemBuilder: (_) => sorted
              .map(
                (office) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    office.structureName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, color: textMain),
                  ),
                ),
              )
              .toList(growable: false),
          items: sorted
              .map(
                (office) => DropdownMenuItem<String>(
                  value: office.id,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        office.structureName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${office.locationName} - ${office.address}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: textSub),
                      ),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: (id) {
            if (id == null) return;
            final office = sorted.firstWhere((item) => item.id == id);
            notifier.setOfficeLocation(
              id: office.id,
              dipartimento: office.structureName,
              sede: office.locationName,
              address: office.address,
              latitude: office.latitude,
              longitude: office.longitude,
            );
          },
        ),
        if (state.sede.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.blue600.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.blue600.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: AppColors.blue600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${state.sede} - ${state.sedeAddress}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textMain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          'Puoi aggiornarla in seguito dal profilo.',
          style: TextStyle(fontSize: 12, color: textSub),
        ),
      ],
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
    return GestureDetector(
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
    return GestureDetector(
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
