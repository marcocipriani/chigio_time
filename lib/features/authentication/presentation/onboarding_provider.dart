import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/app_strings.dart';

part 'onboarding_provider.g.dart';

class OnboardingState {
  final int currentStep;
  final String name;
  final String administration;
  final String employmentType;
  final Duration standardDailyHours;
  final Duration mealVoucherThreshold;
  final int monthlyArt9Hours; // Ore Art. 9
  final int monthlyOvertimeHours; // Straordinari normali
  final ThemeMode themePreference;
  final String dipartimento;
  final String sede;
  final String sedeId;
  final String sedeAddress;
  final double? sedeLat;
  final double? sedeLng;
  final int monthlySliHours;
  final int monthlySboHours;
  final String gender; // 'M', 'F', 'A' (altro/schwa)

  OnboardingState({
    this.currentStep = 0,
    this.name = '',
    this.administration = 'Presidenza del Consiglio dei Ministri',
    this.employmentType = '',
    this.standardDailyHours = const Duration(hours: 7, minutes: 12),
    this.mealVoucherThreshold = const Duration(hours: 6, minutes: 0),
    this.monthlyArt9Hours = 0,
    this.monthlyOvertimeHours = 0,
    this.themePreference = ThemeMode.system,
    this.dipartimento = '',
    this.sede = '',
    this.sedeId = '',
    this.sedeAddress = '',
    this.sedeLat,
    this.sedeLng,
    this.monthlySliHours = 0,
    this.monthlySboHours = 0,
    this.gender = 'N',
  });

  OnboardingState copyWith({
    int? currentStep,
    String? name,
    String? administration,
    String? employmentType,
    Duration? standardDailyHours,
    Duration? mealVoucherThreshold,
    int? monthlyArt9Hours,
    int? monthlyOvertimeHours,
    ThemeMode? themePreference,
    String? dipartimento,
    String? sede,
    String? sedeId,
    String? sedeAddress,
    double? sedeLat,
    double? sedeLng,
    int? monthlySliHours,
    int? monthlySboHours,
    String? gender,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      name: name ?? this.name,
      administration: administration ?? this.administration,
      employmentType: employmentType ?? this.employmentType,
      standardDailyHours: standardDailyHours ?? this.standardDailyHours,
      mealVoucherThreshold: mealVoucherThreshold ?? this.mealVoucherThreshold,
      monthlyArt9Hours: monthlyArt9Hours ?? this.monthlyArt9Hours,
      monthlyOvertimeHours: monthlyOvertimeHours ?? this.monthlyOvertimeHours,
      themePreference: themePreference ?? this.themePreference,
      dipartimento: dipartimento ?? this.dipartimento,
      sede: sede ?? this.sede,
      sedeId: sedeId ?? this.sedeId,
      sedeAddress: sedeAddress ?? this.sedeAddress,
      sedeLat: sedeLat ?? this.sedeLat,
      sedeLng: sedeLng ?? this.sedeLng,
      monthlySliHours: monthlySliHours ?? this.monthlySliHours,
      monthlySboHours: monthlySboHours ?? this.monthlySboHours,
      gender: gender ?? this.gender,
    );
  }
}

@riverpod
class Onboarding extends _$Onboarding {
  @override
  OnboardingState build() => OnboardingState();

  void nextStep() => state = state.copyWith(currentStep: state.currentStep + 1);
  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setName(String name) => state = state.copyWith(name: name);
  void setAdministration(String admin) =>
      state = state.copyWith(administration: admin);

  void setEmploymentType(String type) {
    if (type == AppStrings.etRuolo) {
      state = state.copyWith(
        employmentType: type,
        standardDailyHours: const Duration(hours: 7, minutes: 36),
        mealVoucherThreshold: const Duration(hours: 6, minutes: 20),
        monthlyArt9Hours: 8,
        monthlyOvertimeHours: 0,
      );
    } else if (type == AppStrings.etComando) {
      state = state.copyWith(
        employmentType: type,
        standardDailyHours: const Duration(hours: 7, minutes: 12),
        mealVoucherThreshold: const Duration(hours: 6, minutes: 20),
        monthlyArt9Hours: 17,
        monthlyOvertimeHours: 0,
      );
    } else {
      state = state.copyWith(
        employmentType: type,
        monthlyArt9Hours: 0,
        monthlyOvertimeHours: 0,
      );
    }
  }

  void addDailyMinutes(int mins) {
    final newMins = state.standardDailyHours.inMinutes + mins;
    if (newMins >= 60 && newMins <= 1440) {
      state = state.copyWith(standardDailyHours: Duration(minutes: newMins));
    }
  }

  void addMealMinutes(int mins) {
    final newMins = state.mealVoucherThreshold.inMinutes + mins;
    if (newMins >= 60 && newMins <= 1440) {
      state = state.copyWith(mealVoucherThreshold: Duration(minutes: newMins));
    }
  }

  void addArt9Hours(int hours) {
    final newHours = state.monthlyArt9Hours + hours;
    if (newHours >= 0) {
      state = state.copyWith(monthlyArt9Hours: newHours);
    }
  }

  void addOvertimeHours(int hours) {
    final newHours = state.monthlyOvertimeHours + hours;
    if (newHours >= 0) {
      state = state.copyWith(monthlyOvertimeHours: newHours);
    }
  }

  void setThemePreference(ThemeMode mode) =>
      state = state.copyWith(themePreference: mode);

  void setDipartimento(String value) =>
      state = state.copyWith(dipartimento: value);

  void setOfficeLocation({
    required String id,
    required String dipartimento,
    required String sede,
    required String address,
    required double latitude,
    required double longitude,
  }) {
    state = state.copyWith(
      dipartimento: dipartimento,
      sede: sede,
      sedeId: id,
      sedeAddress: address,
      sedeLat: latitude,
      sedeLng: longitude,
    );
  }

  void setMonthlySliHours(int hours) =>
      state = state.copyWith(monthlySliHours: hours);

  void setMonthlySboHours(int hours) =>
      state = state.copyWith(monthlySboHours: hours);

  void setGender(String g) => state = state.copyWith(gender: g);
}
