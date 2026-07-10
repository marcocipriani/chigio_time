// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WorkTimer)
final workTimerProvider = WorkTimerProvider._();

final class WorkTimerProvider extends $NotifierProvider<WorkTimer, TimerState> {
  WorkTimerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workTimerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workTimerHash();

  @$internal
  @override
  WorkTimer create() => WorkTimer();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TimerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TimerState>(value),
    );
  }
}

String _$workTimerHash() => r'1869ff62614f4b3b954e6bad1a73c55a9b6c4186';

abstract class _$WorkTimer extends $Notifier<TimerState> {
  TimerState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TimerState, TimerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TimerState, TimerState>,
              TimerState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
