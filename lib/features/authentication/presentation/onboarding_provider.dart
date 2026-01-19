import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../timesheet/domain/timesheet_calculator.dart';

// Questa riga è fondamentale per la code generation
part 'onboarding_provider.g.dart';

/// Stato del wizard di onboarding
class OnboardingState {
  final Duration standardDailyHours;
  final Duration mealVoucherThreshold;
  final Duration overtimeThreshold;
  final int monthlyOvertimeCapHours;
  final int currentStep;

  const OnboardingState({
    this.standardDailyHours = const Duration(hours: 7, minutes: 36),
    this.mealVoucherThreshold = const Duration(hours: 6, minutes: 20),
    this.overtimeThreshold = const Duration(hours: 9),
    this.monthlyOvertimeCapHours = 20,
    this.currentStep = 0,
  });

  OnboardingState copyWith({
    Duration? standardDailyHours,
    Duration? mealVoucherThreshold,
    Duration? overtimeThreshold,
    int? monthlyOvertimeCapHours,
    int? currentStep,
  }) {
    return OnboardingState(
      standardDailyHours: standardDailyHours ?? this.standardDailyHours,
      mealVoucherThreshold: mealVoucherThreshold ?? this.mealVoucherThreshold,
      overtimeThreshold: overtimeThreshold ?? this.overtimeThreshold,
      monthlyOvertimeCapHours: monthlyOvertimeCapHours ?? this.monthlyOvertimeCapHours,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

/// Sostituisce StateNotifier con la nuova sintassi @riverpod
@riverpod
class Onboarding extends _$Onboarding {
  @override
  OnboardingState build() {
    return const OnboardingState();
  }

  void setStandardHours(int hours, int minutes) {
    state = state.copyWith(standardDailyHours: Duration(hours: hours, minutes: minutes));
  }

  void setMealThreshold(int hours, int minutes) {
    state = state.copyWith(mealVoucherThreshold: Duration(hours: hours, minutes: minutes));
  }

  void setOvertimeCap(int hours) {
    state = state.copyWith(monthlyOvertimeCapHours: hours);
  }

  void nextStep() {
    if (state.currentStep < 3) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }
}