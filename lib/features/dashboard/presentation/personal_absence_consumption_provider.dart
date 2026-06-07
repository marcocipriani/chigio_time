import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../authentication/data/auth_repository.dart';
import '../../timesheet/data/timesheet_repository.dart';
import '../../timesheet/domain/absence_consumption.dart';

part 'personal_absence_consumption_provider.g.dart';

/// Consumo personale annuo dei permessi orari piu' usati (P1, vedi
/// docs/ccnl/permessi-assenze-congedi.md), calcolato dalle entries `leave`
/// con `absenceKind` valorizzato. Usato per confrontare il consumo
/// tracciato in app coi residui del portale (tabella "Integrazione con
/// totalizzatori") — il portale resta sorgente di verita'.
@riverpod
Future<AbsenceConsumption?> personalAbsenceConsumption(Ref ref) async {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null) return null;

  final repo = ref.watch(timesheetRepositoryProvider);
  final year = DateTime.now().year;
  final entries = await repo.fetchRange(
    DateTime(year, 1, 1),
    DateTime(year, 12, 31),
  );

  return computeAbsenceConsumption(
    year: year,
    entries: entries.map(
      (e) => (
        dateId: e.dateId,
        absenceKind: e.absenceKind,
        absenceMins: e.absenceMins,
        hasDocumentation: e.hasDocumentation,
      ),
    ),
  );
}
