import 'package:chigio_time/core/constants/app_strings.dart';
import 'package:chigio_time/core/errors/failures.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

FirebaseException _firebase(String code) =>
    FirebaseException(plugin: 'test', code: code, message: 'boom');

void main() {
  group('AppFailure.from — Firebase codes', () {
    test('maps transport codes to a network failure', () {
      for (final code in [
        'unavailable',
        'deadline-exceeded',
        'network-request-failed',
      ]) {
        final failure = AppFailure.from(_firebase(code));
        expect(failure, isA<NetworkFailure>(), reason: code);
        expect(failure.kind, FailureKind.network, reason: code);
      }
    });

    test('maps permission-denied to a permission failure', () {
      final failure = AppFailure.from(_firebase('permission-denied'));
      expect(failure, isA<PermissionFailure>());
      expect(failure.kind, FailureKind.permission);
    });

    test('maps session codes to an authentication failure', () {
      for (final code in [
        'unauthenticated',
        'user-token-expired',
        'user-disabled',
        'requires-recent-login',
      ]) {
        expect(
          AppFailure.from(_firebase(code)),
          isA<AuthenticationFailure>(),
          reason: code,
        );
      }
    });

    test('maps missing documents to a not-found failure', () {
      expect(AppFailure.from(_firebase('not-found')), isA<NotFoundFailure>());
      expect(
        AppFailure.from(_firebase('object-not-found')),
        isA<NotFoundFailure>(),
      );
    });

    test('maps rejected input to a validation failure', () {
      for (final code in [
        'invalid-argument',
        'invalid-email',
        'weak-password',
        'failed-precondition',
      ]) {
        expect(
          AppFailure.from(_firebase(code)),
          isA<ValidationFailure>(),
          reason: code,
        );
      }
    });

    test('strips the plugin namespace from the code', () {
      // firebase_auth prefixes some codes with `auth/`.
      expect(
        AppFailure.from(_firebase('auth/network-request-failed')),
        isA<NetworkFailure>(),
      );
    });

    test('falls back to unknown for an unmapped code', () {
      final failure = AppFailure.from(_firebase('quota-exceeded'));
      expect(failure, isA<UnknownFailure>());
      expect(failure.kind, FailureKind.unknown);
    });
  });

  group('AppFailure.from — untyped errors', () {
    test('classifies transport wording', () {
      expect(
        AppFailure.from(Exception('SocketException: failed host lookup')),
        isA<NetworkFailure>(),
      );
      expect(
        AppFailure.from(Exception('operation timeout')),
        isA<NetworkFailure>(),
      );
    });

    test('classifies permission and session wording', () {
      expect(
        AppFailure.from(Exception('permission-denied on /users/1')),
        isA<PermissionFailure>(),
      );
      expect(
        AppFailure.from(Exception('Utente non autenticato')),
        isA<AuthenticationFailure>(),
      );
    });

    test('falls back to unknown', () {
      expect(AppFailure.from(Exception('boom')), isA<UnknownFailure>());
    });
  });

  group('AppFailure contract', () {
    test('is idempotent: wrapping a failure returns the same instance', () {
      const original = PermissionFailure();
      expect(identical(AppFailure.from(original), original), isTrue);
    });

    test('keeps the cause for the logs, out of the message', () {
      final cause = _firebase('permission-denied');
      final failure = AppFailure.from(cause, stackTrace: StackTrace.current);

      expect(failure.cause, same(cause));
      expect(failure.stackTrace, isNotNull);
      expect(failure.message, isNot(contains('boom')));
      expect(failure.toString(), contains('permission'));
    });

    test('every failure carries a non-empty Italian message', () {
      const failures = <AppFailure>[
        NetworkFailure(),
        AuthenticationFailure(),
        PermissionFailure(),
        NotFoundFailure(),
        ValidationFailure(),
        UnknownFailure(),
      ];

      for (final failure in failures) {
        expect(failure.message, isNotEmpty, reason: '$failure');
        expect(failure.message.endsWith('.'), isTrue, reason: '$failure');
      }
      expect(
        failures.map((f) => f.kind).toSet(),
        hasLength(FailureKind.values.length),
      );
    });

    test('is catchable as an Exception', () {
      Object? caught;
      try {
        throw const AuthenticationFailure();
      } on Exception catch (e) {
        caught = e;
      }
      expect(caught, isA<AuthenticationFailure>());
    });
  });

  group('AppStrings routing', () {
    test('shows the typed message and never the raw error', () {
      final message = AppStrings.errorGeneric(_firebase('unavailable'));
      expect(message, const NetworkFailure().message);
      expect(message, isNot(contains('boom')));
    });

    test('prefixes the save error while keeping the classification', () {
      final message = AppStrings.errorSave(_firebase('permission-denied'));
      expect(message, startsWith('Salvataggio non riuscito.'));
      expect(message, contains(const PermissionFailure().message));
    });

    test('keeps the generic fallback for anything unclassified', () {
      expect(
        AppStrings.errorGeneric(Exception('boom')),
        const UnknownFailure().message,
      );
    });
  });
}
