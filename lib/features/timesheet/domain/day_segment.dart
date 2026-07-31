// A slice of a day: work, hourly leave, hours-bank exemption or a pause.
// Behaviour is declared in a table so a new institute is data, not a branch.
class DaySegment {
  static const work = 'work';
  static const leave = 'leave';
  static const bancaOre = 'banca_ore';
  static const lunch = 'lunch';
  static const pause = 'pause';

  // worked:    conta come tempo lavorato
  // covers:    copre l'orario dovuto della giornata
  // insideSpan: se il segmento non ha orari, cade dentro lo span timbrato
  static const _behaviour = <String, ({bool worked, bool covers, bool insideSpan})>{
    work: (worked: true, covers: false, insideSpan: true),
    leave: (worked: false, covers: true, insideSpan: true),
    bancaOre: (worked: false, covers: true, insideSpan: false),
    lunch: (worked: false, covers: false, insideSpan: true),
    pause: (worked: false, covers: false, insideSpan: true),
  };

  static bool isWork(String type) => _behaviour[type]?.worked ?? false;
  static bool coversDuty(String type) => _behaviour[type]?.covers ?? false;
  static bool insideSpanWhenUnpositioned(String type) =>
      type != work && (_behaviour[type]?.insideSpan ?? false);

  /// Etichette leggibili dei tipi, per la timeline e il suo editor.
  static const typeLabels = <String, String>{
    work: 'Lavoro',
    leave: 'Permesso',
    bancaOre: 'Banca ore',
    lunch: 'Pausa pranzo',
    pause: 'Pausa',
  };

  static String labelFor(String type) => typeLabels[type] ?? 'Segmento';

  /// Ordina per inizio, in coda i segmenti senza posizione. Non muta [segments].
  static List<DaySegment> sorted(List<DaySegment> segments) =>
      [...segments]..sort((a, b) {
        if (a.start == null) return b.start == null ? 0 : 1;
        if (b.start == null) return -1;
        return a.start!.compareTo(b.start!);
      });

  /// Motivo per cui [segments] non forma una giornata valida (ADR-0018),
  /// `null` se la giornata e' valida. Regola unica per l'import CSV e per la
  /// timeline: quello che l'import rifiuta l'interfaccia non lo salva.
  static String? validationError(List<DaySegment> segments) {
    // Non basta che un `work` esista: lo span viene dai soli work posizionati,
    // e senza nessuno di essi non c'e' giornata da calcolare (un `work` con i
    // soli minuti non ha una posizione da cui partire).
    if (!segments.any((s) => s.type == work && s.start != null && s.end != null)) {
      return 'La giornata non ha segmenti di lavoro con orari';
    }

    final positioned = sorted(
      segments.where((s) => s.start != null && s.end != null).toList(),
    );

    // Due segmenti dello stesso ruolo non possono occupare gli stessi minuti:
    // due `work` sono una timbratura doppia, due non-work la stessa pausa
    // contata due volte. Con la lista ordinata per inizio basta confrontare
    // coppie consecutive dentro ciascun gruppo: se una coppia non adiacente
    // si sovrapponesse, si sovrapporrebbe anche quella adiacente fra loro.
    for (final group in [
      positioned.where((s) => s.type == work),
      positioned.where((s) => s.type != work),
    ]) {
      final list = group.toList();
      for (var i = 0; i < list.length - 1; i++) {
        if (list[i].end!.isAfter(list[i + 1].start!)) {
          return 'Segmenti sovrapposti';
        }
      }
    }

    // Un segmento non-`work` sta *dentro* un `work` — e' la giornata che
    // scrive il timer, lo span timbrato piu' le pause che lo interrompono, e
    // il calcolo le sottrae dallo span invece di sommarle — oppure ne sta
    // fuori del tutto (giornata a `work` spezzati, come il CSV del portale).
    // Quello che non puo' fare e' scavalcare un confine: mezza pausa dentro
    // il turno e mezza fuori non e' una giornata rappresentabile.
    // ponytail: doppio ciclo, i segmenti di una giornata sono una manciata.
    for (final s in positioned.where((s) => s.type != work)) {
      for (final w in positioned.where((s) => s.type == work)) {
        final touches = s.start!.isBefore(w.end!) && s.end!.isAfter(w.start!);
        final inside = !s.start!.isBefore(w.start!) && !s.end!.isAfter(w.end!);
        if (touches && !inside) return 'Segmenti sovrapposti';
      }
    }

    // lunch e pause cadono solo dentro lo span di lavoro, a differenza di
    // leave e banca ore che possono cadere anche fuori. La guardia iniziale
    // garantisce almeno un work posizionato, quindi il controllo non si
    // disattiva mai da solo.
    final workSegs = positioned.where((s) => s.type == work);
    var spanStart = workSegs.first.start!;
    var spanEnd = workSegs.first.end!;
    for (final s in workSegs) {
      if (s.start!.isBefore(spanStart)) spanStart = s.start!;
      if (s.end!.isAfter(spanEnd)) spanEnd = s.end!;
    }
    for (final s in positioned) {
      if ((s.type == lunch || s.type == pause) &&
          (s.start!.isBefore(spanStart) || s.end!.isAfter(spanEnd))) {
        // Il tipo resta nel messaggio: con piu' pause in giornata, sapere
        // quale e' fuori span e' meta' della diagnosi di un CSV rifiutato.
        return '${labelFor(s.type)} fuori dallo span di lavoro';
      }
    }
    return null;
  }

  final String type;
  final DateTime? start;
  final DateTime? end;
  final int mins; // durata quando start/end mancano
  final String? absenceKind; // CCNL causale for leave

  const DaySegment({
    required this.type,
    this.start,
    this.end,
    this.mins = 0,
    this.absenceKind,
  });

  /// Durata del segmento: dagli orari se presenti, altrimenti da [mins].
  int get durationMins {
    if (start == null || end == null) return mins > 0 ? mins : 0;
    final d = end!.difference(start!).inMinutes;
    return d > 0 ? d : 0;
  }

  /// Minuti che cadono dentro lo span timbrato. Un segmento senza orari
  /// segue la regola del suo tipo: una pausa interrompe il lavoro, un
  /// esonero da banca ore e' un credito e non occupa tempo.
  int overlapMins(DateTime spanStart, DateTime spanEnd) {
    if (start == null || end == null) {
      return insideSpanWhenUnpositioned(type) ? durationMins : 0;
    }
    final from = start!.isAfter(spanStart) ? start! : spanStart;
    final to = end!.isBefore(spanEnd) ? end! : spanEnd;
    final d = to.difference(from).inMinutes;
    return d > 0 ? d : 0;
  }

  /// Worked minutes contributed by this segment (0 for non-work).
  int get workMins => type == work ? durationMins : 0;

  /// Leave minutes contributed by this segment (0 otherwise).
  int get leaveMins => type == leave ? durationMins : 0;

  Map<String, dynamic> toMap() => {
    'type': type,
    if (start != null) 'start': start!.toIso8601String(),
    if (end != null) 'end': end!.toIso8601String(),
    if (mins > 0) 'mins': mins,
    if (absenceKind != null) 'absenceKind': absenceKind,
  };

  // Tolerant: garbage fields degrade to an inert segment, never throw.
  factory DaySegment.fromMap(Map<String, dynamic> map) => DaySegment(
    type: map['type'] is String ? map['type'] as String : work,
    start: map['start'] is String
        ? DateTime.tryParse(map['start'] as String)
        : null,
    end: map['end'] is String
        ? DateTime.tryParse(map['end'] as String)
        : null,
    mins: map['mins'] is num ? (map['mins'] as num).toInt() : 0,
    absenceKind: map['absenceKind'] is String
        ? map['absenceKind'] as String
        : null,
  );
}
