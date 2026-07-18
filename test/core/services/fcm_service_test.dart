import 'dart:async';

import 'package:chigio_time/core/services/fcm_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'due init concorrenti registrano solo la sessione piu recente',
    () async {
      final firstPermission = Completer<bool>();
      final messaging = _FakeMessaging(
        permissionResults: [firstPermission.future, Future.value(true)],
        tokenResults: [Future.value('token-b')],
      );
      final registrations = _FakeRegistrations();
      final service = _service(messaging, registrations);

      final initA = service.init('uid-a');
      await _waitUntil(() => messaging.permissionCalls == 1);
      final initB = service.init('uid-b');
      await initB;
      firstPermission.complete(true);
      await initA;

      expect(registrations.saves, [
        const _Save('uid-b', 'installation-id', 'token-b', 'test'),
      ]);
      expect(messaging.refreshController.hasListener, isTrue);
    },
  );

  test('auth null durante init invalida token e listener stale', () async {
    final permission = Completer<bool>();
    final messaging = _FakeMessaging(
      permissionResults: [permission.future],
      tokenResults: [Future.value('stale-token')],
    );
    final registrations = _FakeRegistrations();
    final service = _service(messaging, registrations);

    final init = service.init('uid-a');
    await _waitUntil(() => messaging.permissionCalls == 1);
    service.deactivate();
    permission.complete(true);
    await init;

    expect(registrations.saves, isEmpty);
    expect(messaging.tokenCalls, 0);
    expect(messaging.refreshController.hasListener, isFalse);
  });

  test(
    'refresh iniziato dalla sessione precedente non viene salvato',
    () async {
      final messaging = _FakeMessaging(
        permissionResults: [Future.value(true), Future.value(true)],
        tokenResults: [Future.value('token-a'), Future.value('token-b')],
      );
      final registrations = _FakeRegistrations();
      final service = _service(messaging, registrations);
      await service.init('uid-a');

      messaging.refreshController.add('refresh-a');
      await service.init('uid-b');
      await Future<void>.delayed(Duration.zero);

      expect(registrations.saves, [
        const _Save('uid-a', 'installation-id', 'token-a', 'test'),
        const _Save('uid-b', 'installation-id', 'token-b', 'test'),
      ]);
    },
  );

  test('unregister accoda delete dopo un save gia iniziato', () async {
    final saveCompleter = Completer<void>();
    final messaging = _FakeMessaging(
      permissionResults: [Future.value(true)],
      tokenResults: [Future.value('token-a')],
    );
    final registrations = _FakeRegistrations(saveCompleter: saveCompleter);
    final service = _service(
      messaging,
      registrations,
      cleanupTimeout: const Duration(milliseconds: 10),
    );

    final init = service.init('uid-a');
    await _waitUntil(() => registrations.events.contains('save:start'));
    await service.unregister('uid-a');
    expect(registrations.events, ['save:start']);

    saveCompleter.complete();
    await init;
    await _waitUntil(() => registrations.events.contains('delete'));
    expect(registrations.events, ['save:start', 'save:end', 'delete']);
    expect(messaging.refreshController.hasListener, isFalse);
  });

  test(
    'unregister termina se Firestore e deleteToken non rispondono',
    () async {
      final messaging = _FakeMessaging(
        deleteTokenResult: Completer<void>().future,
      );
      final registrations = _FakeRegistrations(
        deleteCompleter: Completer<void>(),
      );
      final service = _service(
        messaging,
        registrations,
        cleanupTimeout: const Duration(milliseconds: 5),
      );

      await service.unregister('uid-a').timeout(const Duration(seconds: 1));

      expect(registrations.deleteCalls, 1);
      expect(messaging.deleteTokenCalls, 1);
    },
  );

  test('sign out avviene anche se cleanup FCM va in timeout', () async {
    var signedOut = false;

    await signOutAfterFcmCleanup(
      unregister: () => Completer<void>().future,
      signOut: () async => signedOut = true,
      timeout: const Duration(milliseconds: 5),
    ).timeout(const Duration(seconds: 1));

    expect(signedOut, isTrue);
  });
}

FcmService _service(
  _FakeMessaging messaging,
  _FakeRegistrations registrations, {
  Duration cleanupTimeout = const Duration(seconds: 1),
}) {
  return FcmService(
    operations: FcmLifecycleOperations(
      requestPermission: messaging.requestPermission,
      getToken: messaging.getToken,
      tokenRefreshes: () => messaging.refreshController.stream,
      installationId: () async => 'installation-id',
      saveRegistration: registrations.save,
      deleteRegistration: registrations.delete,
      deleteToken: messaging.deleteToken,
    ),
    isSupported: true,
    platform: 'test',
    cleanupTimeout: cleanupTimeout,
  );
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Condition not reached');
}

class _FakeMessaging {
  _FakeMessaging({
    List<Future<bool>>? permissionResults,
    List<Future<String?>>? tokenResults,
    Future<void>? deleteTokenResult,
  }) : permissionResults = permissionResults ?? const [],
       tokenResults = tokenResults ?? const [],
       deleteTokenResult = deleteTokenResult ?? Future.value();

  final List<Future<bool>> permissionResults;
  final List<Future<String?>> tokenResults;
  final Future<void> deleteTokenResult;
  final refreshController = StreamController<String>.broadcast(sync: true);
  var permissionCalls = 0;
  var tokenCalls = 0;
  var deleteTokenCalls = 0;

  Future<bool> requestPermission() {
    final result = permissionResults[permissionCalls];
    permissionCalls++;
    return result;
  }

  Future<String?> getToken() {
    final result = tokenResults[tokenCalls];
    tokenCalls++;
    return result;
  }

  Future<void> deleteToken() {
    deleteTokenCalls++;
    return deleteTokenResult;
  }
}

class _FakeRegistrations {
  _FakeRegistrations({this.saveCompleter, this.deleteCompleter});

  final Completer<void>? saveCompleter;
  final Completer<void>? deleteCompleter;
  final saves = <_Save>[];
  final events = <String>[];
  var deleteCalls = 0;

  Future<void> save({
    required String uid,
    required String installationId,
    required String token,
    required String platform,
  }) async {
    saves.add(_Save(uid, installationId, token, platform));
    events.add('save:start');
    if (saveCompleter != null) await saveCompleter!.future;
    events.add('save:end');
  }

  Future<void> delete({
    required String uid,
    required String installationId,
  }) async {
    deleteCalls++;
    events.add('delete');
    if (deleteCompleter != null) await deleteCompleter!.future;
  }
}

class _Save {
  const _Save(this.uid, this.installationId, this.token, this.platform);

  final String uid;
  final String installationId;
  final String token;
  final String platform;

  @override
  bool operator ==(Object other) =>
      other is _Save &&
      other.uid == uid &&
      other.installationId == installationId &&
      other.token == token &&
      other.platform == platform;

  @override
  int get hashCode => Object.hash(uid, installationId, token, platform);
}
