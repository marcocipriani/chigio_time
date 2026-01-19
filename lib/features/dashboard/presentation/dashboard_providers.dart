import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../timesheet/domain/timesheet_calculator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'dashboard_providers.g.dart';

/// Provider per l'orario di ingresso (Mutable, quindi usiamo una classe)
@riverpod
class EntryTime extends _$EntryTime {
  @override
  DateTime build() {
    final now = DateTime.now();
    // Default alle 08:30 di oggi
    return DateTime(now.year, now.month, now.day, 8, 30);
  }

  void update(DateTime newTime) {
    state = newTime;
  }
}

/// Provider per il tick corrente (Stream funzionale)
@riverpod
Stream<DateTime> currentTick(Ref ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
}  

/// Provider calcolato
@riverpod
TimesheetResult timesheetResult(Ref ref) {
  final entryTime = ref.watch(entryTimeProvider);
  final nowAsync = ref.watch(currentTickProvider);
  
  final now = nowAsync.value ?? DateTime.now();
  
  return TimesheetCalculator().calculate(
    entryTime: entryTime,
    exitTime: now, 
    profile: const UserWorkProfile(),
  );
}