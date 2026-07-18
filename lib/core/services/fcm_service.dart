import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'notification_routing.dart';

const _installationIdKey = 'fcm_installation_id';
const _vapidKey =
    'BIqNFgyp2HyyknHHvFSjJFEcuGojQOh5LfaH7qcWWqEyxwzqEC6dc6o5rP8Lska_QqQuqK96aPDMbG5e2IZFYZQ';

// Must be top-level: handles push in background/terminated state.
// The OS shows the notification automatically from the FCM payload.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage _) async {}

final fcmServiceProvider = Provider<FcmService>((ref) {
  final service = FcmService.firebase(FirebaseFirestore.instance);
  ref.onDispose(service.dispose);
  return service;
});

typedef SaveFcmRegistration =
    Future<void> Function({
      required String uid,
      required String installationId,
      required String token,
      required String platform,
    });

typedef DeleteFcmRegistration =
    Future<void> Function({
      required String uid,
      required String installationId,
    });

/// Small injectable seam for the async token lifecycle. Notification routing
/// keeps using Firebase's concrete [RemoteMessage] API.
class FcmLifecycleOperations {
  const FcmLifecycleOperations({
    required this.requestPermission,
    required this.getToken,
    required this.tokenRefreshes,
    required this.installationId,
    required this.saveRegistration,
    required this.deleteRegistration,
    required this.deleteToken,
  });

  final Future<bool> Function() requestPermission;
  final Future<String?> Function() getToken;
  final Stream<String> Function() tokenRefreshes;
  final Future<String> Function() installationId;
  final SaveFcmRegistration saveRegistration;
  final DeleteFcmRegistration deleteRegistration;
  final Future<void> Function() deleteToken;
}

class FcmService {
  FcmService({
    required FcmLifecycleOperations operations,
    required bool isSupported,
    required String platform,
    this.cleanupTimeout = const Duration(seconds: 3),
  }) : _operations = operations,
       _isSupported = isSupported,
       _platform = platform;

  factory FcmService.firebase(FirebaseFirestore db) {
    Future<String>? installationIdFuture;

    Future<String> loadOrCreateInstallationId() async {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString(_installationIdKey);
      if (existing != null && existing.isNotEmpty) return existing;

      final installationId = const Uuid().v4();
      await prefs.setString(_installationIdKey, installationId);
      return installationId;
    }

    return FcmService(
      operations: FcmLifecycleOperations(
        requestPermission: () async {
          final settings = await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );
          return settings.authorizationStatus != AuthorizationStatus.denied;
        },
        getToken: () => FirebaseMessaging.instance.getToken(
          vapidKey: kIsWeb ? _vapidKey : null,
        ),
        tokenRefreshes: () => FirebaseMessaging.instance.onTokenRefresh,
        installationId: () =>
            installationIdFuture ??= loadOrCreateInstallationId(),
        saveRegistration:
            ({
              required uid,
              required installationId,
              required token,
              required platform,
            }) async {
              final batch = db.batch();
              batch.set(db.doc('users/$uid/private/fcm'), {
                'installations': {
                  installationId: {
                    'token': token,
                    'platform': platform,
                    'updatedAt': FieldValue.serverTimestamp(),
                  },
                },
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
              // Migrazione lazy: rimuove il campo legacy esposto ai colleghi.
              batch.set(db.doc('users/$uid'), {
                'fcmToken': FieldValue.delete(),
              }, SetOptions(merge: true));
              await batch.commit();
            },
        deleteRegistration: ({required uid, required installationId}) =>
            db.doc('users/$uid/private/fcm').update({
              'installations.$installationId': FieldValue.delete(),
              'updatedAt': FieldValue.serverTimestamp(),
            }),
        deleteToken: () => FirebaseMessaging.instance.deleteToken(),
      ),
      isSupported: supportsFcm(defaultTargetPlatform, isWeb: kIsWeb),
      platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
    );
  }

  final FcmLifecycleOperations _operations;
  final bool _isSupported;
  final String _platform;
  final Duration cleanupTimeout;

  StreamSubscription<String>? _tokenRefreshSub;
  int _generation = 0;
  String? _activeUid;

  void dispose() {
    _invalidateSession();
    unawaited(_bestEffort(_stopTokenRefresh(), 'token listener cancel'));
  }

  void deactivate() {
    final previousUid = _invalidateSession();
    final stopListener = _bestEffort(
      _stopTokenRefresh(),
      'token listener cancel',
    );
    if (!_isSupported || previousUid == null) {
      unawaited(stopListener);
      return;
    }

    unawaited(Future.wait([stopListener, _deleteRegistration(previousUid)]));
  }

  // Call once per login session (uid just became available).
  Future<void> init(String uid) async {
    final previousUid = _activeUid;
    final generation = _activate(uid);
    if (!_isSupported) return;

    try {
      final stopListener = _stopTokenRefresh();
      final previousCleanup = previousUid != null && previousUid != uid
          ? _deleteRegistration(previousUid)
          : null;

      await stopListener;
      if (!_isCurrent(generation, uid)) return;

      if (previousCleanup != null) {
        await previousCleanup;
        if (!_isCurrent(generation, uid)) return;
      }

      final permissionGranted = await _operations.requestPermission();
      if (!_isCurrent(generation, uid) || !permissionGranted) return;

      final token = await _operations.getToken();
      if (!_isCurrent(generation, uid)) return;

      if (token != null) {
        await _saveToken(generation, uid, token);
        if (!_isCurrent(generation, uid)) return;
      }

      final subscription = _operations.tokenRefreshes().listen(
        (refreshedToken) {
          if (!_isCurrent(generation, uid)) return;
          unawaited(_saveToken(generation, uid, refreshedToken));
        },
        onError: (Object error) {
          if (_isCurrent(generation, uid)) {
            debugPrint('[fcm] token refresh failed: $error');
          }
        },
      );
      if (!_isCurrent(generation, uid)) {
        await subscription.cancel();
        return;
      }
      _tokenRefreshSub = subscription;
    } catch (error) {
      if (_isCurrent(generation, uid)) {
        debugPrint('[fcm] init failed: $error');
      }
    }
  }

  Future<void> _saveToken(int generation, String uid, String token) async {
    if (!_isCurrent(generation, uid)) return;

    try {
      final installationId = await _operations.installationId();
      if (!_isCurrent(generation, uid)) return;

      // Calling saveRegistration emits the Firestore mutation immediately;
      // awaiting only tracks remote completion and must not gate logout delete.
      final save = _operations.saveRegistration(
        uid: uid,
        installationId: installationId,
        token: token,
        platform: _platform,
      );
      await save;
      if (!_isCurrent(generation, uid)) return;
    } catch (error) {
      debugPrint('[fcm] token save failed: $error');
    }
  }

  Future<void> unregister(String uid) async {
    _invalidateSession();
    final stopListener = _bestEffort(
      _stopTokenRefresh(),
      'token listener cancel',
    );
    if (!_isSupported) {
      await stopListener;
      return;
    }

    try {
      // Start both immediately. deleteRegistration is invoked independently
      // from pending save Futures, after their Firestore mutation invocation.
      final deleteRegistration = _deleteRegistration(uid);
      await Future.wait([stopListener, deleteRegistration]);
    } finally {
      await _bestEffort(_operations.deleteToken(), 'deleteToken');
    }
  }

  Future<void> _deleteRegistration(String uid) async {
    try {
      final installationId = await _operations.installationId().timeout(
        cleanupTimeout,
      );
      final deletion = _operations.deleteRegistration(
        uid: uid,
        installationId: installationId,
      );
      await deletion.timeout(cleanupTimeout);
    } catch (error) {
      debugPrint('[fcm] unregister failed: $error');
    }
  }

  Future<void> _bestEffort(Future<void> operation, String label) async {
    try {
      await operation.timeout(cleanupTimeout);
    } catch (error) {
      debugPrint('[fcm] $label failed: $error');
    }
  }

  int _activate(String uid) {
    _generation++;
    _activeUid = uid;
    return _generation;
  }

  String? _invalidateSession() {
    final previousUid = _activeUid;
    _generation++;
    _activeUid = null;
    return previousUid;
  }

  bool _isCurrent(int generation, String uid) =>
      _generation == generation && _activeUid == uid;

  Future<void> _stopTokenRefresh() {
    final subscription = _tokenRefreshSub;
    _tokenRefreshSub = null;
    return subscription?.cancel() ?? Future<void>.value();
  }

  // Navigate to the allowlisted payload route after a terminated-state tap.
  // Call in app initState.
  Future<void> handleInitialMessage(
    void Function(String route) navigate,
  ) async {
    if (!_isSupported) return;
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) navigate(notificationRoute(message.data));
  }

  // Navigate to the allowlisted payload route after a background-state tap.
  StreamSubscription<RemoteMessage> handleMessageOpenedApp(
    void Function(String route) navigate,
  ) {
    if (!_isSupported) return const Stream<RemoteMessage>.empty().listen(null);
    return FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => navigate(notificationRoute(message.data)),
    );
  }

  // Stream of foreground messages for in-app display.
  Stream<RemoteMessage> get onForegroundMessage => _isSupported
      ? FirebaseMessaging.onMessage
      : const Stream<RemoteMessage>.empty();
}

Future<void> signOutAfterFcmCleanup({
  required Future<void> Function() unregister,
  required Future<void> Function() signOut,
  Duration timeout = const Duration(seconds: 5),
}) async {
  try {
    await unregister().timeout(timeout);
  } catch (error) {
    debugPrint('[fcm] cleanup before signOut failed: $error');
  } finally {
    await signOut();
  }
}
