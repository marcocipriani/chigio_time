// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider per l'orario di ingresso (Mutable, quindi usiamo una classe)

@ProviderFor(EntryTime)
final entryTimeProvider = EntryTimeProvider._();

/// Provider per l'orario di ingresso (Mutable, quindi usiamo una classe)
final class EntryTimeProvider extends $NotifierProvider<EntryTime, DateTime> {
  /// Provider per l'orario di ingresso (Mutable, quindi usiamo una classe)
  EntryTimeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'entryTimeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$entryTimeHash();

  @$internal
  @override
  EntryTime create() => EntryTime();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$entryTimeHash() => r'2f2f3dbd599de1f3154cb46af91cbc6cfe38d49b';

/// Provider per l'orario di ingresso (Mutable, quindi usiamo una classe)

abstract class _$EntryTime extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider per il tick corrente (Stream funzionale)

@ProviderFor(currentTick)
final currentTickProvider = CurrentTickProvider._();

/// Provider per il tick corrente (Stream funzionale)

final class CurrentTickProvider
    extends
        $FunctionalProvider<AsyncValue<DateTime>, DateTime, Stream<DateTime>>
    with $FutureModifier<DateTime>, $StreamProvider<DateTime> {
  /// Provider per il tick corrente (Stream funzionale)
  CurrentTickProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentTickProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentTickHash();

  @$internal
  @override
  $StreamProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DateTime> create(Ref ref) {
    return currentTick(ref);
  }
}

String _$currentTickHash() => r'ba43898083eecad285f3dfe8336c859b131a0308';

/// Provider calcolato

@ProviderFor(timesheetResult)
final timesheetResultProvider = TimesheetResultProvider._();

/// Provider calcolato

final class TimesheetResultProvider
    extends
        $FunctionalProvider<TimesheetResult, TimesheetResult, TimesheetResult>
    with $Provider<TimesheetResult> {
  /// Provider calcolato
  TimesheetResultProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'timesheetResultProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$timesheetResultHash();

  @$internal
  @override
  $ProviderElement<TimesheetResult> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TimesheetResult create(Ref ref) {
    return timesheetResult(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TimesheetResult value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TimesheetResult>(value),
    );
  }
}

String _$timesheetResultHash() => r'c75e80b74ef1aedd235b78b20825801ffd16d38a';
