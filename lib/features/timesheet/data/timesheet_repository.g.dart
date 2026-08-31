// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timesheet_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(timesheetRepository)
final timesheetRepositoryProvider = TimesheetRepositoryProvider._();

final class TimesheetRepositoryProvider
    extends
        $FunctionalProvider<
          TimesheetRepository,
          TimesheetRepository,
          TimesheetRepository
        >
    with $Provider<TimesheetRepository> {
  TimesheetRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'timesheetRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$timesheetRepositoryHash();

  @$internal
  @override
  $ProviderElement<TimesheetRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TimesheetRepository create(Ref ref) {
    return timesheetRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TimesheetRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TimesheetRepository>(value),
    );
  }
}

String _$timesheetRepositoryHash() =>
    r'cfe399655d5e838bbf5b1cf3fa73076923b2a6d2';
