// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_timer_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(activeTimerRepository)
final activeTimerRepositoryProvider = ActiveTimerRepositoryProvider._();

final class ActiveTimerRepositoryProvider
    extends
        $FunctionalProvider<
          ActiveTimerRepository,
          ActiveTimerRepository,
          ActiveTimerRepository
        >
    with $Provider<ActiveTimerRepository> {
  ActiveTimerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeTimerRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeTimerRepositoryHash();

  @$internal
  @override
  $ProviderElement<ActiveTimerRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ActiveTimerRepository create(Ref ref) {
    return activeTimerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActiveTimerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActiveTimerRepository>(value),
    );
  }
}

String _$activeTimerRepositoryHash() =>
    r'ad05328ad59e2b75b93ddedee2d3aad781ceedbb';
