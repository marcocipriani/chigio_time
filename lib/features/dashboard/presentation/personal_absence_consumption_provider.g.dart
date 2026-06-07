// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_absence_consumption_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Consumo personale annuo dei permessi orari piu' usati (P1, vedi
/// docs/ccnl/permessi-assenze-congedi.md), calcolato dalle entries `leave`
/// con `absenceKind` valorizzato. Usato per confrontare il consumo
/// tracciato in app coi residui del portale (tabella "Integrazione con
/// totalizzatori") — il portale resta sorgente di verita'.

@ProviderFor(personalAbsenceConsumption)
final personalAbsenceConsumptionProvider =
    PersonalAbsenceConsumptionProvider._();

/// Consumo personale annuo dei permessi orari piu' usati (P1, vedi
/// docs/ccnl/permessi-assenze-congedi.md), calcolato dalle entries `leave`
/// con `absenceKind` valorizzato. Usato per confrontare il consumo
/// tracciato in app coi residui del portale (tabella "Integrazione con
/// totalizzatori") — il portale resta sorgente di verita'.

final class PersonalAbsenceConsumptionProvider
    extends
        $FunctionalProvider<
          AsyncValue<AbsenceConsumption?>,
          AbsenceConsumption?,
          FutureOr<AbsenceConsumption?>
        >
    with
        $FutureModifier<AbsenceConsumption?>,
        $FutureProvider<AbsenceConsumption?> {
  /// Consumo personale annuo dei permessi orari piu' usati (P1, vedi
  /// docs/ccnl/permessi-assenze-congedi.md), calcolato dalle entries `leave`
  /// con `absenceKind` valorizzato. Usato per confrontare il consumo
  /// tracciato in app coi residui del portale (tabella "Integrazione con
  /// totalizzatori") — il portale resta sorgente di verita'.
  PersonalAbsenceConsumptionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'personalAbsenceConsumptionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$personalAbsenceConsumptionHash();

  @$internal
  @override
  $FutureProviderElement<AbsenceConsumption?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AbsenceConsumption?> create(Ref ref) {
    return personalAbsenceConsumption(ref);
  }
}

String _$personalAbsenceConsumptionHash() =>
    r'5d4deeca70e10b08eb1462a256a1445c5e6bdb3e';
