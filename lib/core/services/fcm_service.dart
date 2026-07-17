import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'notification_routing.dart';

// Must be top-level: handles push in background/terminated state.
// The OS shows the notification automatically from the FCM payload.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage _) async {}

final fcmServiceProvider = Provider<FcmService>((ref) {
  final svc = FcmService(FirebaseFirestore.instance);
  ref.onDispose(svc.dispose);
  return svc;
});

class FcmService {
  static const _installationIdKey = 'fcm_installation_id';

  final FirebaseFirestore _db;
  StreamSubscription<String>? _tokenRefreshSub;
  Future<String>? _installationIdFuture;

  // VAPID key from Firebase Console → Project Settings → Cloud Messaging →
  // Web push certificates. Set before deploying to web.
  static const _vapidKey =
      'BIqNFgyp2HyyknHHvFSjJFEcuGojQOh5LfaH7qcWWqEyxwzqEC6dc6o5rP8Lska_QqQuqK96aPDMbG5e2IZFYZQ';

  FcmService(this._db);

  void dispose() => _tokenRefreshSub?.cancel();

  // Call once per login session (uid just became available).
  Future<void> init(String uid) async {
    if (!_isSupported) return;

    await _stopTokenRefresh();
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    try {
      final token = await messaging.getToken(
        vapidKey: kIsWeb ? _vapidKey : null,
      );
      if (token != null) await _saveToken(uid, token);
    } catch (e) {
      // Push non disponibili (permessi/VAPID/rete): l'app funziona comunque,
      // ma il fallimento non deve più essere invisibile (review B5).
      debugPrint('[fcm] getToken failed: $e');
    }

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = messaging.onTokenRefresh.listen(
      (t) => _saveToken(uid, t),
    );
  }

  Future<void> _saveToken(String uid, String token) async {
    try {
      final installationId = await _installationId();
      final batch = _db.batch();
      // C1 (review 2026-07-05): il token vive in private/ (owner-only), NON
      // sul doc utente leggibile dai colleghi della stessa amministrazione.
      batch.set(_db.doc('users/$uid/private/fcm'), {
        'installations': {
          installationId: {
            'token': token,
            'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      // Migrazione lazy: rimuove il campo legacy esposto ai colleghi.
      batch.set(_db.doc('users/$uid'), {
        'fcmToken': FieldValue.delete(),
      }, SetOptions(merge: true));
      await batch.commit();
    } catch (e) {
      debugPrint('[fcm] token save failed: $e');
    }
  }

  Future<String> _installationId() =>
      _installationIdFuture ??= _loadOrCreateInstallationId();

  Future<String> _loadOrCreateInstallationId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_installationIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final installationId = const Uuid().v4();
    await prefs.setString(_installationIdKey, installationId);
    return installationId;
  }

  Future<void> _stopTokenRefresh() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
  }

  Future<void> unregister(String uid) async {
    await _stopTokenRefresh();
    if (!_isSupported) return;

    final installationId = await _installationId();
    try {
      await _db.doc('users/$uid/private/fcm').update({
        'installations.$installationId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[fcm] unregister failed: $e');
    }

    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('[fcm] deleteToken failed: $e');
    }
  }

  // Navigate to the allowlisted payload route after a terminated-state tap.
  // Call in app initState.
  Future<void> handleInitialMessage(
    void Function(String route) navigate,
  ) async {
    if (!_isSupported) return;
    final msg = await FirebaseMessaging.instance.getInitialMessage();
    if (msg != null) navigate(notificationRoute(msg.data));
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

  bool get _isSupported => supportsFcm(defaultTargetPlatform, isWeb: kIsWeb);
}
