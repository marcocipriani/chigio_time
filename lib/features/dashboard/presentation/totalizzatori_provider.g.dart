// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'totalizzatori_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(totalizzatori)
final totalizzatoriProvider = TotalizzatoriProvider._();

final class TotalizzatoriProvider
    extends $FunctionalProvider<Totalizzatori?, Totalizzatori?, Totalizzatori?>
    with $Provider<Totalizzatori?> {
  TotalizzatoriProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalizzatoriProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalizzatoriHash();

  @$internal
  @override
  $ProviderElement<Totalizzatori?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Totalizzatori? create(Ref ref) {
    return totalizzatori(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Totalizzatori? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Totalizzatori?>(value),
    );
  }
}

String _$totalizzatoriHash() => r'01ca496d7d849f1b95216f03e08b5c7d1aa0d868';
