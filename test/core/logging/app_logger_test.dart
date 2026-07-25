import 'package:chigio_time/core/logging/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<LogRecord> records;

  setUp(() {
    records = [];
    AppLog.useSink(records.add);
    AppLog.minLevel = LogLevel.debug;
  });

  tearDown(AppLog.reset);

  test('routes every level to the installed sink', () {
    AppLog.debug('tag', 'd');
    AppLog.info('tag', 'i');
    AppLog.warning('tag', 'w');
    AppLog.error('tag', 'e');

    expect(records.map((r) => r.level), [
      LogLevel.debug,
      LogLevel.info,
      LogLevel.warning,
      LogLevel.error,
    ]);
  });

  test('drops records below the threshold', () {
    AppLog.minLevel = LogLevel.warning;

    AppLog.debug('tag', 'd');
    AppLog.info('tag', 'i');
    AppLog.warning('tag', 'w');
    AppLog.error('tag', 'e');

    expect(records.map((r) => r.message), ['w', 'e']);
  });

  test('keeps error and stack trace on the record', () {
    final error = StateError('boom');
    final stack = StackTrace.current;

    AppLog.error('repo', 'save failed', error: error, stackTrace: stack);

    final record = records.single;
    expect(record.tag, 'repo');
    expect(record.message, 'save failed');
    expect(record.error, same(error));
    expect(record.stackTrace, same(stack));
  });

  test('formats as the legacy debugPrint line', () {
    AppLog.warning('timesheet_repo', 'DB cache write failed', error: 'disk');

    expect(
      records.single.format(),
      '[timesheet_repo] DB cache write failed: disk',
    );
  });

  test('omits the error section when there is none', () {
    AppLog.info('fcm', 'registered');

    expect(records.single.format(), '[fcm] registered');
    expect(records.single.toString(), 'INFO [fcm] registered');
  });

  test('reset restores the default sink and threshold', () {
    AppLog.reset();
    AppLog.error('tag', 'goes to debugPrint');

    expect(records, isEmpty);
    expect(AppLog.minLevel, AppLog.defaultMinLevel);
  });

  test('debug and profile builds keep every level enabled', () {
    // Il gate release (solo warning/error) non deve nascondere nulla mentre
    // si sviluppa: la suite gira in debug.
    expect(AppLog.defaultMinLevel, LogLevel.debug);
  });
}
