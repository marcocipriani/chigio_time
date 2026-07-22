// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(profileRepository)
final profileRepositoryProvider = ProfileRepositoryProvider._();

final class ProfileRepositoryProvider
    extends
        $FunctionalProvider<
          ProfileRepository,
          ProfileRepository,
          ProfileRepository
        >
    with $Provider<ProfileRepository> {
  ProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProfileRepository create(Ref ref) {
    return profileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileRepository>(value),
    );
  }
}

String _$profileRepositoryHash() => r'dcb6d810e966c7ed5a722485e215a4244ef1d889';

@ProviderFor(monthlySauHistoryStream)
final monthlySauHistoryStreamProvider = MonthlySauHistoryStreamProvider._();

final class MonthlySauHistoryStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MonthlySau>>,
          List<MonthlySau>,
          Stream<List<MonthlySau>>
        >
    with $FutureModifier<List<MonthlySau>>, $StreamProvider<List<MonthlySau>> {
  MonthlySauHistoryStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthlySauHistoryStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthlySauHistoryStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<MonthlySau>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MonthlySau>> create(Ref ref) {
    return monthlySauHistoryStream(ref);
  }
}

String _$monthlySauHistoryStreamHash() =>
    r'2b51a75e0f5f1ba0e6b4bc41a4cdc240a3db5ce3';

@ProviderFor(capPeriodsStream)
final capPeriodsStreamProvider = CapPeriodsStreamProvider._();

final class CapPeriodsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CapPeriod>>,
          List<CapPeriod>,
          Stream<List<CapPeriod>>
        >
    with $FutureModifier<List<CapPeriod>>, $StreamProvider<List<CapPeriod>> {
  CapPeriodsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'capPeriodsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$capPeriodsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<CapPeriod>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CapPeriod>> create(Ref ref) {
    return capPeriodsStream(ref);
  }
}

String _$capPeriodsStreamHash() => r'b4c917eb188d5c1c39be40a48838b3251d0e5d78';

@ProviderFor(profileGate)
final profileGateProvider = ProfileGateProvider._();

final class ProfileGateProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProfileGateResult>,
          ProfileGateResult,
          Stream<ProfileGateResult>
        >
    with
        $FutureModifier<ProfileGateResult>,
        $StreamProvider<ProfileGateResult> {
  ProfileGateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileGateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileGateHash();

  @$internal
  @override
  $StreamProviderElement<ProfileGateResult> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ProfileGateResult> create(Ref ref) {
    return profileGate(ref);
  }
}

String _$profileGateHash() => r'999cca8b5371728fe2b11a47f606ff5dc3e71a67';

@ProviderFor(privatePortaleStream)
final privatePortaleStreamProvider = PrivatePortaleStreamProvider._();

final class PrivatePortaleStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>?>,
          Map<String, dynamic>?,
          Stream<Map<String, dynamic>?>
        >
    with
        $FutureModifier<Map<String, dynamic>?>,
        $StreamProvider<Map<String, dynamic>?> {
  PrivatePortaleStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'privatePortaleStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$privatePortaleStreamHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, dynamic>?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, dynamic>?> create(Ref ref) {
    return privatePortaleStream(ref);
  }
}

String _$privatePortaleStreamHash() =>
    r'42cc4bc48d201220be1e644a95e15fed30cc5fc9';

/// Dati portale correnti: nuova posizione privata, con fallback sul campo
/// legacy `portaleJson` del doc utente per gli account non ancora migrati.
/// La migrazione avviene al primo salvataggio (vedi [ProfileRepository.savePortaleData]).

@ProviderFor(portaleRaw)
final portaleRawProvider = PortaleRawProvider._();

/// Dati portale correnti: nuova posizione privata, con fallback sul campo
/// legacy `portaleJson` del doc utente per gli account non ancora migrati.
/// La migrazione avviene al primo salvataggio (vedi [ProfileRepository.savePortaleData]).

final class PortaleRawProvider
    extends
        $FunctionalProvider<
          Map<String, dynamic>?,
          Map<String, dynamic>?,
          Map<String, dynamic>?
        >
    with $Provider<Map<String, dynamic>?> {
  /// Dati portale correnti: nuova posizione privata, con fallback sul campo
  /// legacy `portaleJson` del doc utente per gli account non ancora migrati.
  /// La migrazione avviene al primo salvataggio (vedi [ProfileRepository.savePortaleData]).
  PortaleRawProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'portaleRawProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$portaleRawHash();

  @$internal
  @override
  $ProviderElement<Map<String, dynamic>?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, dynamic>? create(Ref ref) {
    return portaleRaw(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, dynamic>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, dynamic>?>(value),
    );
  }
}

String _$portaleRawHash() => r'8199add768b496d37664a9542febe160623cbda4';

@ProviderFor(userProfileStream)
final userProfileStreamProvider = UserProfileStreamProvider._();

final class UserProfileStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>?>,
          Map<String, dynamic>?,
          Stream<Map<String, dynamic>?>
        >
    with
        $FutureModifier<Map<String, dynamic>?>,
        $StreamProvider<Map<String, dynamic>?> {
  UserProfileStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userProfileStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userProfileStreamHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, dynamic>?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, dynamic>?> create(Ref ref) {
    return userProfileStream(ref);
  }
}

String _$userProfileStreamHash() => r'c756b19ba4ee7c9c3732da6ce81a62cf0773060e';
