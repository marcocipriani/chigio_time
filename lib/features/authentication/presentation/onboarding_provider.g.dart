// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Onboarding)
final onboardingProvider = OnboardingProvider._();

final class OnboardingProvider
    extends $NotifierProvider<Onboarding, OnboardingState> {
  OnboardingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingHash();

  @$internal
  @override
  Onboarding create() => Onboarding();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnboardingState>(value),
    );
  }
}

String _$onboardingHash() => r'3474882b43044da864f29917b995c5f96836f026';

abstract class _$Onboarding extends $Notifier<OnboardingState> {
  OnboardingState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<OnboardingState, OnboardingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OnboardingState, OnboardingState>,
              OnboardingState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
