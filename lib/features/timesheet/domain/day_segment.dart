// A slice of a day: a work interval or an hourly leave (permesso).
// Lunch/coffee pauses stay as day-level fields on DailyTimesheet.
class DaySegment {
  static const work = 'work';
  static const leave = 'leave';

  final String type; // work | leave
  final DateTime? start; // work only
  final DateTime? end; // work only
  final int mins; // leave duration; ignored for work (derived)
  final String? absenceKind; // CCNL causale for leave

  const DaySegment({
    required this.type,
    this.start,
    this.end,
    this.mins = 0,
    this.absenceKind,
  });

  /// Worked minutes contributed by this segment (0 for leave/invalid).
  int get workMins {
    if (type != work || start == null || end == null) return 0;
    final d = end!.difference(start!).inMinutes;
    return d > 0 ? d : 0;
  }

  /// Leave minutes contributed by this segment (0 for work).
  int get leaveMins => type == leave ? mins : 0;

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
