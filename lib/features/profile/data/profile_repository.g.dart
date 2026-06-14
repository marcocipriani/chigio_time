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

String _$profileRepositoryHash() => r'3aa54b7cf9d7220e922d36cee297e850f9941d06';

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

@ProviderFor(hasProfileStream)
final hasProfileStreamProvider = HasProfileStreamProvider._();

final class HasProfileStreamProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  HasProfileStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasProfileStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasProfileStreamHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return hasProfileStream(ref);
  }
}

String _$hasProfileStreamHash() => r'f432e6c912e66ca6785742b28bc08ee28bfa4b52';

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
