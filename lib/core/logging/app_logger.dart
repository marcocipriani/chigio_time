/// Minimal, dependency-free logging façade.
///
/// Replaces the scattered `debugPrint('[tag] …')` calls: every diagnostic
/// message goes through [AppLog], so the destination can be swapped once
/// (telemetry, crash reporting, an in-app console) instead of editing dozens
/// of call sites.
///
/// Default behaviour is deliberately identical to what the app did before:
/// records are printed with `debugPrint` in debug/profile, while in release
/// only `warning`/`error` survive (see [defaultMinLevel]).
///
/// Usage:
/// ```dart
/// AppLog.error('timesheet_repo', 'DB cache write failed', error: e);
/// ```
library;

import 'package:flutter/foundation.dart';

/// Severity of a [LogRecord], ordered from least to most severe.
enum LogLevel { debug, info, warning, error }

/// A single diagnostic event.
@immutable
class LogRecord {
  const LogRecord({
    required this.level,
    required this.tag,
    required this.message,
    required this.time,
    this.error,
    this.stackTrace,
  });

  final LogLevel level;

  /// Subsystem that emitted the record, e.g. `timesheet_repo`, `fcm`.
  final String tag;

  final String message;
  final DateTime time;
  final Object? error;
  final StackTrace? stackTrace;

  /// Single-line rendering used by the default sink.
  String format() {
    final buffer = StringBuffer('[$tag] $message');
    if (error != null) buffer.write(': $error');
    return buffer.toString();
  }

  @override
  String toString() => '${level.name.toUpperCase()} ${format()}';
}

/// Destination of log records. Swap it with [AppLog.useSink].
typedef LogSink = void Function(LogRecord record);

/// Prints through `debugPrint`, which is rate-limited and stripped from
/// release builds by the Flutter toolchain.
void debugPrintSink(LogRecord record) => debugPrint(record.format());

abstract final class AppLog {
  /// In release only warnings and errors are worth the cost.
  static const defaultMinLevel = kReleaseMode
      ? LogLevel.warning
      : LogLevel.debug;

  static LogSink _sink = debugPrintSink;
  static LogLevel _minLevel = defaultMinLevel;

  static LogLevel get minLevel => _minLevel;
  static set minLevel(LogLevel value) => _minLevel = value;

  /// Routes every subsequent record to [sink] (telemetry, tests, …).
  static void useSink(LogSink sink) => _sink = sink;

  /// Restores the `debugPrint` sink and the default threshold.
  static void reset() {
    _sink = debugPrintSink;
    _minLevel = defaultMinLevel;
  }

  static void debug(String tag, String message) =>
      _emit(LogLevel.debug, tag, message);

  static void info(String tag, String message) =>
      _emit(LogLevel.info, tag, message);

  static void warning(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) => _emit(
    LogLevel.warning,
    tag,
    message,
    error: error,
    stackTrace: stackTrace,
  );

  static void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _emit(LogLevel.error, tag, message, error: error, stackTrace: stackTrace);

  static void _emit(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < _minLevel.index) return;
    _sink(
      LogRecord(
        level: level,
        tag: tag,
        message: message,
        time: DateTime.now(),
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
