import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/colleague.dart';
import '../domain/app_notification.dart';
import '../domain/colleague_group.dart';

class SocialRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  const SocialRepository(this._db, this._auth);

  String? get _uid => _auth.currentUser?.uid;

  // ── Colleagues ───────────────────────────────────────────────────────

  Stream<List<ColleagueProfile>> watchColleagues() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    return _db.collection('users/$uid/colleagues').snapshots().asyncMap((
      snap,
    ) async {
      if (snap.docs.isEmpty) return <ColleagueProfile>[];

      // isFavorite comes from the colleague sub-doc, profiles from users collection.
      final favMap = {
        for (final doc in snap.docs)
          doc.id: doc['isFavorite'] as bool? ?? false,
      };
      final ids = snap.docs.map((d) => d.id).toList();

      // Batch profile reads with whereIn (max 30 per query) instead of N
      // individual gets — reduces reads from N to ceil(N/30).
      final profiles = <String, Map<String, dynamic>>{};
      for (var i = 0; i < ids.length; i += 30) {
        final chunk = ids.sublist(i, (i + 30).clamp(0, ids.length));
        final profileSnap = await _db
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in profileSnap.docs) {
          profiles[doc.id] = doc.data();
        }
      }

      final results = ids.map((id) {
        final p = profiles[id] ?? {};
        return ColleagueProfile(
          uid: id,
          name: p['name'] as String? ?? 'Collega',
          administration: p['administration'] as String? ?? '',
          employmentType: p['employmentType'] as String? ?? '',
          phoneNumber: p['phoneNumber'] as String?,
          dipartimento: p['dipartimento'] as String?,
          interno: p['interno'] as String?,
          sede: p['sede'] as String?,
          isFavorite: favMap[id] ?? false,
          rawStatus: p['currentStatus'] as String? ?? 'notStarted',
          statusDate: p['statusDate'] as String?,
          coffeeAvailable: p['coffeeAvailable'] as bool?,
          piano: p['piano'] as String?,
          stanza: p['stanza'] as String?,
        );
      }).toList();

      results.sort((a, b) {
        if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
        return a.name.compareTo(b.name);
      });

      return results;
    });
  }

  Future<void> addColleague(String colleagueUid) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('users/$uid/colleagues').doc(colleagueUid).set({
      'isFavorite': false,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeColleague(String colleagueUid) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('users/$uid/colleagues').doc(colleagueUid).delete();
  }

  Future<void> setFavorite(
    String colleagueUid, {
    required bool isFavorite,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('users/$uid/colleagues').doc(colleagueUid).update({
      'isFavorite': isFavorite,
    });
  }

  // ── User discovery (same administration) ────────────────────────────

  Future<List<Map<String, dynamic>>> getUsersInAdministration(
    String administration,
    Set<String> excludeUids,
  ) async {
    final uid = _uid;
    if (uid == null || administration.isEmpty) return [];

    final snap = await _db
        .collection('users')
        .where('administration', isEqualTo: administration)
        .where('hasCompletedOnboarding', isEqualTo: true)
        .get();

    return snap.docs
        .where((d) => d.id != uid && !excludeUids.contains(d.id))
        .map((d) => {'uid': d.id, ...d.data()})
        .toList()
      ..sort(
        (a, b) =>
            (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''),
      );
  }

  // ── Coffee availability ──────────────────────────────────────────────

  Future<void> setCoffeeAvailable(bool available) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      'coffeeAvailable': available,
    });
  }

  // ── Coffee invite ────────────────────────────────────────────────────

  Future<void> sendCoffeeInvite({
    required String toUid,
    required String fromName,
    String? scheduledAt,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final payload = <String, dynamic>{
      'type': 'coffee_invite',
      'fromUid': uid,
      'fromName': fromName,
      'sentAt': FieldValue.serverTimestamp(),
      'status': 'pending',
      'read': false,
    };
    if (scheduledAt != null && scheduledAt.isNotEmpty) {
      payload['scheduledAt'] = scheduledAt;
    }
    await _db.collection('users/$toUid/notifications').add(payload);
    await _db.collection('users/$uid/coffeeLog').add({
      'toUid': toUid,
      'sentAt': FieldValue.serverTimestamp(),
      if (scheduledAt != null && scheduledAt.isNotEmpty)
        'scheduledAt': scheduledAt,
    });
  }

  Future<void> sendGroupCoffee(
    String groupId, {
    required String fromName,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final groupSnap = await _db
        .collection('users/$uid/groups')
        .doc(groupId)
        .get();
    if (!groupSnap.exists) return;
    final memberUids = List<String>.from(groupSnap.data()?['memberUids'] ?? []);
    await Future.wait(
      memberUids.map(
        (memberUid) => sendCoffeeInvite(toUid: memberUid, fromName: fromName),
      ),
    );
  }

  // ── Notifications ────────────────────────────────────────────────────

  Stream<List<AppNotification>> watchNotifications() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    return _db
        .collection('users/$uid/notifications')
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final data = doc.data();
            final ts = data['sentAt'];
            final sentAt = ts is Timestamp ? ts.toDate() : DateTime.now();
            return AppNotification.fromMap(doc.id, {...data, 'sentAt': sentAt});
          }).toList(),
        );
  }

  // responseType: 'accepted' | 'declined' | 'maybe' | 'arriving'
  Future<void> respondToInvite(
    String notifId, {
    required String responseType,
    String? message,
    int? etaMinutes,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final docRef = _db.collection('users/$uid/notifications').doc(notifId);
    final snap = await docRef.get();
    await docRef.update({'status': responseType, 'read': true});

    if (!snap.exists) return;
    final data = snap.data()!;
    final fromUid = data['fromUid'] as String?;
    if (fromUid == null || fromUid.isEmpty) return;

    final myProfile = await _db.collection('users').doc(uid).get();
    final myName = myProfile.data()?['name'] as String? ?? 'Un collega';

    final payload = <String, dynamic>{
      'type': 'coffee_accepted',
      'fromUid': uid,
      'fromName': myName,
      'sentAt': FieldValue.serverTimestamp(),
      'status': 'info',
      'responseType': responseType,
      'read': false,
    };
    if (message != null && message.isNotEmpty) payload['message'] = message;
    if (etaMinutes != null) payload['etaMinutes'] = etaMinutes;
    await _db.collection('users/$fromUid/notifications').add(payload);
  }

  Future<void> markAllRead() async {
    final uid = _uid;
    if (uid == null) return;
    final snap = await _db
        .collection('users/$uid/notifications')
        .where('read', isEqualTo: false)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  // ── Groups ───────────────────────────────────────────────────────────

  Stream<List<ColleagueGroup>> watchGroups() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _db
        .collection('users/$uid/groups')
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map(ColleagueGroup.fromFirestore).toList());
  }

  Future<void> createGroup(String name) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('users/$uid/groups').add({
      'name': name.trim(),
      'memberUids': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteGroup(String groupId) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('users/$uid/groups').doc(groupId).delete();
  }

  Future<void> addMemberToGroup(String groupId, String memberUid) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('users/$uid/groups').doc(groupId).update({
      'memberUids': FieldValue.arrayUnion([memberUid]),
    });
  }

  Future<void> removeMemberFromGroup(String groupId, String memberUid) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('users/$uid/groups').doc(groupId).update({
      'memberUids': FieldValue.arrayRemove([memberUid]),
    });
  }

  // ── Coffee log (sent tracking) ───────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchCoffeeLog() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _db
        .collection('users/$uid/coffeeLog')
        .orderBy('sentAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }
}

// ── Providers ─────────────────────────────────────────────────────────

final socialRepositoryProvider = Provider<SocialRepository>(
  (ref) => SocialRepository(FirebaseFirestore.instance, FirebaseAuth.instance),
);

final colleaguesStreamProvider =
    StreamProvider.autoDispose<List<ColleagueProfile>>(
      (ref) => ref.watch(socialRepositoryProvider).watchColleagues(),
    );

final notificationsStreamProvider =
    StreamProvider.autoDispose<List<AppNotification>>(
      (ref) => ref.watch(socialRepositoryProvider).watchNotifications(),
    );

final hasUnreadProvider = Provider<bool>((ref) {
  final notifs = ref.watch(notificationsStreamProvider).asData?.value ?? [];
  return notifs.any((n) => !n.read);
});

final groupsStreamProvider = StreamProvider.autoDispose<List<ColleagueGroup>>(
  (ref) => ref.watch(socialRepositoryProvider).watchGroups(),
);

final coffeeLogStreamProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>(
      (ref) => ref.watch(socialRepositoryProvider).watchCoffeeLog(),
    );

final coffeeStatsProvider =
    Provider.autoDispose<({int sent, int received, int accepted})>((ref) {
      final notifs = ref.watch(notificationsStreamProvider).asData?.value ?? [];
      final log = ref.watch(coffeeLogStreamProvider).asData?.value ?? [];
      final now = DateTime.now();
      int received = 0, accepted = 0;
      for (final n in notifs) {
        if (n.sentAt.month != now.month || n.sentAt.year != now.year) continue;
        if (n.type == 'coffee_invite') received++;
        if (n.type == 'coffee_accepted' && n.responseType == 'accepted')
          accepted++;
      }
      int sent = 0;
      for (final e in log) {
        final ts = e['sentAt'];
        if (ts is Timestamp) {
          final d = ts.toDate();
          if (d.month == now.month && d.year == now.year) sent++;
        }
      }
      return (sent: sent, received: received, accepted: accepted);
    });
