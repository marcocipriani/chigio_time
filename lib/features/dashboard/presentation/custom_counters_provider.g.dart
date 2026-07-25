// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_counters_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(customCounters)
final customCountersProvider = CustomCountersProvider._();

final class CustomCountersProvider
    extends
        $FunctionalProvider<
          List<CustomCounter>,
          List<CustomCounter>,
          List<CustomCounter>
        >
    with $Provider<List<CustomCounter>> {
  CustomCountersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customCountersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customCountersHash();

  @$internal
  @override
  $ProviderElement<List<CustomCounter>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<CustomCounter> create(Ref ref) {
    return customCounters(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<CustomCounter> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<CustomCounter>>(value),
    );
  }
}

String _$customCountersHash() => r'eccfafceffb55a99587ab7a8793e677d8ca09242';
