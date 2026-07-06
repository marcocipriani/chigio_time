import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final FirebaseFirestore _db;
  StreamSubscription<String>? _tokenRefreshSub;

  // VAPID key from Firebase Console → Project Settings → Cloud Messaging →
  // Web push certificates. Set before deploying to web.
  static const _vapidKey = 'BIqNFgyp2HyyknHHvFSjJFEcuGojQOh5LfaH7qcWWqEyxwzqEC6dc6o5rP8Lska_QqQuqK96aPDMbG5e2IZFYZQ';

  FcmService(this._db);

  void dispose() => _tokenRefreshSub?.cancel();

  // Call once per login session (uid just became available).
  Future<void> init(String uid) async {
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
    } catch (_) {}

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = messaging.onTokenRefresh.listen(
      (t) => _saveToken(uid, t),
    );
  }

  Future<void> _saveToken(String uid, String token) async {
    try {
      final batch = _db.batch();
      // C1 (review 2026-07-05): il token vive in private/ (owner-only), NON
      // sul doc utente leggibile dai colleghi della stessa amministrazione.
      batch.set(_db.doc('users/$uid/private/fcm'), {
        'token': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Migrazione lazy: rimuove il campo legacy esposto ai colleghi.
      batch.set(_db.collection('users').doc(uid), {
        'fcmToken': FieldValue.delete(),
      }, SetOptions(merge: true));
      await batch.commit();
    } catch (_) {}
  }

  // Navigate to /notifications when app is opened via a tap on a push
  // notification while the app was terminated. Call in app initState.
  Future<void> handleInitialMessage(
    void Function(String route) navigate,
  ) async {
    final msg = await FirebaseMessaging.instance.getInitialMessage();
    if (msg != null) navigate('/notifications');
  }

  // Navigate to /notifications when app is opened via a tap on a push
  // notification while the app was in the background.
  StreamSubscription<RemoteMessage> handleMessageOpenedApp(
    void Function(String route) navigate,
  ) => FirebaseMessaging.onMessageOpenedApp.listen(
    (_) => navigate('/notifications'),
  );

  // Stream of foreground messages for in-app display.
  Stream<RemoteMessage> get onForegroundMessage => FirebaseMessaging.onMessage;
}
