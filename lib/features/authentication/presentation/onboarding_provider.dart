import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/app_constants.dart';
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
  final String scheduleVariant; // 'uniform' | 'mixed'
  final List<int>
  longWorkDays; // weekday ints 1=Mon…5=Fri, exactly 2 when mixed
  final DateTime? hireDate; // data presa servizio (mai nel futuro)

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
    this.gender = 'A',
    this.scheduleVariant = AppConstants.scheduleUniform,
    this.longWorkDays = const [],
    this.hireDate,
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
    String? scheduleVariant,
    List<int>? longWorkDays,
    DateTime? hireDate,
    bool clearOfficeLocation = false,
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
      sede: clearOfficeLocation ? '' : sede ?? this.sede,
      sedeId: clearOfficeLocation ? '' : sedeId ?? this.sedeId,
      sedeAddress: clearOfficeLocation ? '' : sedeAddress ?? this.sedeAddress,
      sedeLat: clearOfficeLocation ? null : sedeLat ?? this.sedeLat,
      sedeLng: clearOfficeLocation ? null : sedeLng ?? this.sedeLng,
      monthlySliHours: monthlySliHours ?? this.monthlySliHours,
      monthlySboHours: monthlySboHours ?? this.monthlySboHours,
      gender: gender ?? this.gender,
      scheduleVariant: scheduleVariant ?? this.scheduleVariant,
      longWorkDays: longWorkDays ?? this.longWorkDays,
      hireDate: hireDate ?? this.hireDate,
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
        scheduleVariant: AppConstants.scheduleUniform,
        longWorkDays: [],
      );
    } else if (type == AppStrings.etComando) {
      state = state.copyWith(
        employmentType: type,
        standardDailyHours: const Duration(hours: 7, minutes: 12),
        mealVoucherThreshold: const Duration(hours: 6, minutes: 20),
        monthlyArt9Hours: 17,
        monthlyOvertimeHours: 0,
        scheduleVariant: AppConstants.scheduleUniform,
        longWorkDays: [],
      );
    } else {
      state = state.copyWith(
        employmentType: type,
        monthlyArt9Hours: 0,
        monthlyOvertimeHours: 0,
        scheduleVariant: AppConstants.scheduleUniform,
        longWorkDays: [],
      );
    }
  }

  void setScheduleVariant(String variant) {
    state = state.copyWith(scheduleVariant: variant, longWorkDays: []);
  }

  void toggleLongWorkDay(int weekday) {
    final days = List<int>.from(state.longWorkDays);
    if (days.contains(weekday)) {
      days.remove(weekday);
    } else if (days.length < 2) {
      days.add(weekday);
    }
    state = state.copyWith(longWorkDays: days);
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

  void setDipartimento(String value) {
    state = state.copyWith(
      dipartimento: value,
      clearOfficeLocation: value != state.dipartimento,
    );
  }

  void setOfficeLocation({
    required String id,
    required String sede,
    required String address,
    required double latitude,
    required double longitude,
  }) {
    state = state.copyWith(
      sede: sede,
      sedeId: id,
      sedeAddress: address,
      sedeLat: latitude,
      sedeLng: longitude,
    );
  }

  void setMonthlySliHours(int hours) {
    final newSli = hours.clamp(0, 50);
    state = state.copyWith(
      monthlySliHours: newSli,
      monthlyOvertimeHours: newSli + state.monthlySboHours,
    );
  }

  void setMonthlySboHours(int hours) {
    final newSbo = hours.clamp(0, 50);
    state = state.copyWith(
      monthlySboHours: newSbo,
      monthlyOvertimeHours: state.monthlySliHours + newSbo,
    );
  }

  void setGender(String g) => state = state.copyWith(gender: g);

  void setHireDate(DateTime d) {
    final today = DateTime.now();
    // Mai nel futuro (troncata al giorno).
    final clamped = d.isAfter(today) ? today : d;
    state = state.copyWith(
      hireDate: DateTime(clamped.year, clamped.month, clamped.day),
    );
  }
}
