import 'package:flutter/material.dart';

/// Modello di input per il calcolo (configurazione utente)
class UserWorkProfile {
  final Duration standardDailyHours; // Default 7h 36m [cite: 99]
  final Duration mealVoucherThreshold; // Default 6h 20m [cite: 102]
  final Duration overtimeThreshold; // Default 9h [cite: 103]
  final Duration lunchBreakAfterOvertime; // Default 30m [cite: 104]

  const UserWorkProfile({
    this.standardDailyHours = const Duration(hours: 7, minutes: 36),
    this.mealVoucherThreshold = const Duration(hours: 6, minutes: 20),
    this.overtimeThreshold = const Duration(hours: 9),
    this.lunchBreakAfterOvertime = const Duration(minutes: 30),
  });
}

/// Risultato del calcolo del timesheet [cite: 249]
class TimesheetResult {
  final DateTime entryTime;
  final DateTime? exitTime; // Null se la giornata non è finita
  
  // Cancelli Calcolati
  final DateTime mealVoucherTime;    // Orario maturazione buono pasto
  final DateTime normalExitTime;     // Orario uscita teorica (7h 36m)
  final DateTime overtimeStart;      // Inizio straordinario (dopo le 9h)
  final DateTime? lunchBreakStart;   // Inizio pausa obbligatoria (se superate le 9h)
  final DateTime? lunchBreakEnd;     // Fine pausa obbligatoria

  // Totali
  final Duration workedHours;        // Ore effettive lavorate
  final Duration overtimeHours;      // Ore di straordinario
  final bool mealVoucherEarned;      // Ha diritto al buono?

  TimesheetResult({
    required this.entryTime,
    this.exitTime,
    required this.mealVoucherTime,
    required this.normalExitTime,
    required this.overtimeStart,
    this.lunchBreakStart,
    this.lunchBreakEnd,
    required this.workedHours,
    required this.overtimeHours,
    required this.mealVoucherEarned,
  });
}

class TimesheetCalculator {
  /// Calcola tutti i cancelli e i totali basandosi su ingresso e profilo
  TimesheetResult calculate({
    required DateTime entryTime,
    DateTime? exitTime,
    UserWorkProfile profile = const UserWorkProfile(),
  }) {
    // 1. Calcolo Cancelli (Previsionale)
    final mealVoucherTime = entryTime.add(profile.mealVoucherThreshold);
    final normalExitTime = entryTime.add(profile.standardDailyHours);
    final overtimeStart = entryTime.add(profile.overtimeThreshold);
    
    // La pausa scatta DOPO la soglia straordinario (es. dopo 9 ore)
    final lunchBreakStart = overtimeStart; 
    final lunchBreakEnd = lunchBreakStart.add(profile.lunchBreakAfterOvertime);

    // 2. Calcolo Consuntivo (se c'è exitTime) o Parziale (rispetto a ora)
    final now = DateTime.now();
    final effectiveExit = exitTime ?? now; // Se non è uscito, calcoliamo fino ad "adesso"

    // Calcolo durata grezza
    Duration rawDuration = effectiveExit.difference(entryTime);
    if (rawDuration.isNegative) rawDuration = Duration.zero;

    // Logica Pausa Pranzo Obbligatoria [cite: 104]
    // Se ha lavorato oltre la soglia (9h), dobbiamo sottrarre la pausa (30m)
    // O se siamo "dentro" la pausa, il tempo non avanza
    Duration actualWorked = rawDuration;
    
    if (rawDuration > profile.overtimeThreshold) {
      // Ha superato le 9 ore?
      final timeBeyondThreshold = rawDuration - profile.overtimeThreshold;
      
      if (timeBeyondThreshold < profile.lunchBreakAfterOvertime) {
        // È DURANTE la pausa (es. 9h 15m di presenza -> 9h lavorate)
        actualWorked = profile.overtimeThreshold;
      } else {
        // Ha FINITO la pausa (es. 9h 45m di presenza -> 9h 15m lavorate)
        actualWorked = rawDuration - profile.lunchBreakAfterOvertime;
      }
    }

    // Calcolo Straordinario
    Duration overtime = Duration.zero;
    if (actualWorked > profile.standardDailyHours) {
      overtime = actualWorked - profile.standardDailyHours;
    }

    // Verifica Buono Pasto [cite: 225-227]
    final earnedVoucher = actualWorked >= profile.mealVoucherThreshold;

    return TimesheetResult(
      entryTime: entryTime,
      exitTime: exitTime,
      mealVoucherTime: mealVoucherTime,
      normalExitTime: normalExitTime,
      overtimeStart: overtimeStart,
      lunchBreakStart: lunchBreakStart,
      lunchBreakEnd: lunchBreakEnd,
      workedHours: actualWorked,
      overtimeHours: overtime,
      mealVoucherEarned: earnedVoucher,
    );
  }
}