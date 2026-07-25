/// Typed application failures.
///
/// The app used to classify errors by sniffing `e.toString()` for substrings
/// (`'permission-denied'`, `'network'`, …), which breaks as soon as a plugin
/// rewords a message. [AppFailure] classifies **once**, at the boundary where
/// the error is still typed (Firebase codes, `TimeoutException`, …), and
/// carries both a stable [kind] for the code and a ready, human Italian
/// [message] for the UI.
///
/// Usage in the `data/` layer:
/// ```dart
/// final user = _auth.currentUser;
/// if (user == null) throw const AuthenticationFailure();
/// ```
///
/// Usage in `presentation/`:
/// ```dart
/// catch (e) { showSnack(AppStrings.errorSave(e)); }
/// ```
/// — `AppStrings` routes through [AppFailure.from], so a typed failure keeps
/// its precise message and anything else still gets the generic fallback.
library;

import 'package:firebase_core/firebase_core.dart';

/// Stable classification of a failure, safe to branch on.
enum FailureKind {
  /// No connectivity, backend unreachable, request timed out.
  network,

  /// Signed-out, expired session, missing credential.
  authentication,

  /// Authenticated but not allowed (Firestore rules, OS permission).
  permission,

  /// The requested document/resource does not exist.
  notFound,

  /// Input rejected before or by the backend.
  validation,

  /// Anything not classified.
  unknown,
}

/// Base class of every failure raised by the `data/` layer.
///
/// Implements [Exception] so existing `throw`/`catch` sites keep working.
sealed class AppFailure implements Exception {
  const AppFailure({
    required this.kind,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  /// Stable classification for the code.
  final FailureKind kind;

  /// Human, Italian, user-facing text. Never the raw error.
  final String message;

  /// Original error, kept for logs — never shown to the user.
  final Object? cause;

  final StackTrace? stackTrace;

  /// Classifies [error] into the matching failure.
  ///
  /// Already-typed failures are returned untouched, so wrapping twice is
  /// harmless.
  static AppFailure from(Object error, {StackTrace? stackTrace}) {
    if (error is AppFailure) return error;

    if (error is FirebaseException) {
      return _fromFirebaseCode(error.code, error, stackTrace);
    }

    return _fromText(error.toString(), error, stackTrace);
  }

  static AppFailure _fromFirebaseCode(
    String code,
    Object cause,
    StackTrace? stackTrace,
  ) {
    // Some plugins namespace their codes (`auth/user-not-found`).
    final normalized = code.contains('/') ? code.split('/').last : code;
    return switch (normalized) {
      'unavailable' ||
      'deadline-exceeded' ||
      'network-request-failed' => NetworkFailure(
        cause: cause,
        stackTrace: stackTrace,
      ),
      'permission-denied' => PermissionFailure(
        cause: cause,
        stackTrace: stackTrace,
      ),
      'unauthenticated' ||
      'user-token-expired' ||
      'user-disabled' ||
      'requires-recent-login' => AuthenticationFailure(
        cause: cause,
        stackTrace: stackTrace,
      ),
      'not-found' || 'object-not-found' => NotFoundFailure(
        cause: cause,
        stackTrace: stackTrace,
      ),
      'invalid-argument' ||
      'invalid-email' ||
      'weak-password' ||
      'failed-precondition' => ValidationFailure(
        cause: cause,
        stackTrace: stackTrace,
      ),
      _ => UnknownFailure(cause: cause, stackTrace: stackTrace),
    };
  }

  /// Last-resort heuristics for untyped errors (plain `Exception`, platform
  /// channels, `SocketException`): plugins still throw those.
  static AppFailure _fromText(
    String text,
    Object cause,
    StackTrace? stackTrace,
  ) {
    final s = text.toLowerCase();
    if (s.contains('network') ||
        s.contains('unavailable') ||
        s.contains('socketexception') ||
        s.contains('timeout')) {
      return NetworkFailure(cause: cause, stackTrace: stackTrace);
    }
    if (s.contains('permission-denied') || s.contains('permission denied')) {
      return PermissionFailure(cause: cause, stackTrace: stackTrace);
    }
    if (s.contains('non autenticato') || s.contains('unauthenticated')) {
      return AuthenticationFailure(cause: cause, stackTrace: stackTrace);
    }
    return UnknownFailure(cause: cause, stackTrace: stackTrace);
  }

  @override
  String toString() {
    final detail = cause == null ? '' : ' (cause: $cause)';
    return '$runtimeType[${kind.name}]: $message$detail';
  }
}

/// No connectivity / backend unreachable.
final class NetworkFailure extends AppFailure {
  const NetworkFailure({
    super.message =
        'Connessione assente o instabile. Riprova quando sei online.',
    super.cause,
    super.stackTrace,
  }) : super(kind: FailureKind.network);
}

/// Session missing or expired.
final class AuthenticationFailure extends AppFailure {
  const AuthenticationFailure({
    super.message = 'Sessione scaduta: esci e accedi di nuovo.',
    super.cause,
    super.stackTrace,
  }) : super(kind: FailureKind.authentication);
}

/// Authenticated but not allowed.
final class PermissionFailure extends AppFailure {
  const PermissionFailure({
    super.message = 'Non hai i permessi per questa operazione.',
    super.cause,
    super.stackTrace,
  }) : super(kind: FailureKind.permission);
}

/// The requested resource does not exist.
final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({
    super.message = 'Dato non trovato.',
    super.cause,
    super.stackTrace,
  }) : super(kind: FailureKind.notFound);
}

/// Input rejected before or by the backend.
final class ValidationFailure extends AppFailure {
  const ValidationFailure({
    super.message = 'Dati non validi. Controlla e riprova.',
    super.cause,
    super.stackTrace,
  }) : super(kind: FailureKind.validation);
}

/// Everything else.
final class UnknownFailure extends AppFailure {
  const UnknownFailure({
    super.message = 'Qualcosa è andato storto. Riprova.',
    super.cause,
    super.stackTrace,
  }) : super(kind: FailureKind.unknown);
}
