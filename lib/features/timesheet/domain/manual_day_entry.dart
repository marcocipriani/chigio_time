import 'absence_kind.dart';
import 'daily_timesheet.dart';
import 'day_segment.dart';

/// Esito della costruzione manuale: la giornata da salvare, oppure il motivo
/// per cui non e' salvabile (stesso messaggio che mostra la timeline).
typedef ManualDayResult = ({DailyTimesheet? entry, String? error});

/// Costruisce la giornata dallo sheet di modifica manuale. Pura: nessun
/// repository e nessun Firestore, cosi' il salvataggio e' verificabile da un
/// test di comportamento invece che da un contratto sul sorgente.
///
/// I segmenti non-`work` di [existing] sopravvivono: correggere l'orario di
/// uscita e' un'azione ordinaria, e sostituire l'intera lista cancellava in
/// silenzio permessi, pause ed esoneri della giornata. Il solo segmento di
/// lavoro viene riscritto dagli orari del form.
ManualDayResult buildManualDayEntry({
  required String dateId,
  required DateTime start,
  required DateTime end,
  required String workType,
  required int stdMins,
  DailyTimesheet? existing,
  String? absenceKind,
  String absenceUnit = AbsenceUnit.hourly,
  int absenceMins = 0,
  double absenceDays = 0,
  DateTime? periodStart,
  DateTime? periodEnd,
  bool sensitive = false,
  bool hasDocumentation = false,
  String personalNote = '',
}) {
  if (workType == WorkType.remote) {
    // Smart working: orario dichiarato, non un timbro reale — nessuna pausa
    // pranzo si applica e la giornata non ha segmenti.
    final from = DateTime(start.year, start.month, start.day, 9, 0);
    return (
      entry: DailyTimesheet(
        dateId: dateId,
        startTime: from,
        endTime: from.add(Duration(minutes: stdMins)),
        standardPauseMins: 0,
        lunchPauseMins: 0,
        netWorkedMins: stdMins,
        extraMins: 0,
        workType: WorkType.remote,
      ),
      error: null,
    );
  }

  final isPresence = workType == WorkType.presence;
  final isLeaveDetail = workType == WorkType.leave && absenceKind != null;

  // I segmenti si conservano solo se sono di questa giornata: lo sheet
  // permette di cambiare giorno, e i segmenti portano date assolute.
  final kept = existing != null && existing.dateId == dateId
      ? existing.segments.where((s) => s.type != DaySegment.work)
      : const <DaySegment>[];
  final segments = isPresence
      ? [
          DaySegment(type: DaySegment.work, start: start, end: end),
          ...kept,
        ]
      : const <DaySegment>[];

  if (isPresence) {
    // Stessa regola dell'import e della timeline: quello che l'import
    // rifiuta l'editor non lo salva. Senza, i nuovi orari di lavoro
    // potrebbero non contenere piu' una pausa gia' registrata.
    final invalid = DaySegment.validationError(segments);
    if (invalid != null) return (entry: null, error: invalid);
  }

  final entry = DailyTimesheet(
    dateId: dateId,
    startTime: start,
    endTime: end,
    standardPauseMins: 0,
    lunchPauseMins: 0,
    netWorkedMins: 0,
    extraMins: 0,
    workType: workType,
    segments: segments,
    absenceKind: isLeaveDetail ? absenceKind : null,
    absenceUnit: isLeaveDetail ? absenceUnit : null,
    absenceMins:
        isLeaveDetail && absenceUnit == AbsenceUnit.hourly ? absenceMins : 0,
    absenceDays:
        isLeaveDetail && absenceUnit == AbsenceUnit.daily ? absenceDays : 0,
    periodStart: isLeaveDetail && absenceUnit == AbsenceUnit.period
        ? periodStart?.toIso8601String().split('T').first
        : null,
    periodEnd: isLeaveDetail && absenceUnit == AbsenceUnit.period
        ? periodEnd?.toIso8601String().split('T').first
        : null,
    quotaYear: isLeaveDetail ? start.year : null,
    countsAsSicknessPeriod:
        isLeaveDetail &&
        (absenceKind == AbsenceKind.sickness ||
            absenceKind == AbsenceKind.workInjury),
    sensitive: isLeaveDetail && sensitive,
    personalNote: isLeaveDetail && personalNote.isNotEmpty ? personalNote : null,
    hasDocumentation: isLeaveDetail && hasDocumentation,
  );

  return (
    entry: isPresence ? entry.recomputedFromSegments(stdMins: stdMins) : entry,
    error: null,
  );
}
