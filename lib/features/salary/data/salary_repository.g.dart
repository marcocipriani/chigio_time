// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'salary_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(salaryRepository)
final salaryRepositoryProvider = SalaryRepositoryProvider._();

final class SalaryRepositoryProvider
    extends
        $FunctionalProvider<
          SalaryRepository,
          SalaryRepository,
          SalaryRepository
        >
    with $Provider<SalaryRepository> {
  SalaryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'salaryRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$salaryRepositoryHash();

  @$internal
  @override
  $ProviderElement<SalaryRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SalaryRepository create(Ref ref) {
    return salaryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SalaryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SalaryRepository>(value),
    );
  }
}

String _$salaryRepositoryHash() => r'3a0b34ad38051a2d046798a5d4fd5e231d4f5136';

@ProviderFor(salaryPaymentsStream)
final salaryPaymentsStreamProvider = SalaryPaymentsStreamProvider._();

final class SalaryPaymentsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SalaryPayment>>,
          List<SalaryPayment>,
          Stream<List<SalaryPayment>>
        >
    with
        $FutureModifier<List<SalaryPayment>>,
        $StreamProvider<List<SalaryPayment>> {
  SalaryPaymentsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'salaryPaymentsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$salaryPaymentsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<SalaryPayment>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SalaryPayment>> create(Ref ref) {
    return salaryPaymentsStream(ref);
  }
}

String _$salaryPaymentsStreamHash() =>
    r'9285ee3d65f10a0a4e8966b24b5f459e203d7d59';
