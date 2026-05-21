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

String _$totalizzatoriHash() => r'8a89b3a0c6ae1881559aa56b8aae7a58e59866d4';
