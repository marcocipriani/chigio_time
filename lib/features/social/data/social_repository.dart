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
      //
      // A `whereIn(documentId)` query is rule-checked per returned doc: se anche
      // un solo collega ha un profilo non leggibile (es. profilo privato, F2),
      // Firestore rifiuta l'INTERO batch → tutta la lista colleghi andava in
      // errore. Fallback per-doc che salta i profili negati.
      final profiles = <String, Map<String, dynamic>>{};
      for (var i = 0; i < ids.length; i += 30) {
        final chunk = ids.sublist(i, (i + 30).clamp(0, ids.length));
        try {
          final profileSnap = await _db
              .collection('users')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
          for (final doc in profileSnap.docs) {
            profiles[doc.id] = doc.data();
          }
        } catch (_) {
          for (final id in chunk) {
            try {
              final doc = await _db.collection('users').doc(id).get();
              if (doc.exists) profiles[id] = doc.data()!;
            } catch (_) {
              // Profilo non leggibile (privato/permessi) → salta.
            }
          }
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
          statusMessage: p['statusMessage'] as String?,
          statusMessageUntil: DateTime.tryParse(
            p['statusMessageUntil'] as String? ?? '',
          ),
          photoURL: p['photoURL'] as String?,
        );
      }).toList();

      results.sort((a, b) {
        if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
        return a.name.compareTo(b.name);
      });

      return results;
    });
  }

  /// F1 — collegamento "amichevole" reciproco e auto-accettato.
  /// Le security rules vietano di scrivere nella sotto-collezione colleagues
  /// di un altro utente, quindi la reciprocità avviene così:
  ///  1. aggiungo il collega alla MIA lista;
  ///  2. invio una notifica `colleague_added` all'altro, il cui client (vedi
  ///     [reconcileIncomingConnections]) aggiunge me alla SUA lista.
  Future<void> addColleague(String colleagueUid) async {
    final uid = _uid;
    if (uid == null || colleagueUid == uid) return;
    await _addColleagueLocal(colleagueUid);

    final me = await _db.collection('users').doc(uid).get();
    final myName = me.data()?['name'] as String? ?? 'Un collega';
    await _db.collection('users/$colleagueUid/notifications').add({
      'type': 'colleague_added',
      'fromUid': uid,
      'fromName': myName,
      'sentAt': FieldValue.serverTimestamp(),
      'status': 'info',
      'read': false,
    });
  }

  /// Aggiunta locale silenziosa (nessuna notifica) — usata per la reciprocità.
  Future<void> _addColleagueLocal(String colleagueUid) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('users/$uid/colleagues').doc(colleagueUid).set({
      'isFavorite': false,
      'addedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Scorre le notifiche `colleague_added` ricevute e si assicura che ogni
  /// mittente sia presente tra i miei Collegati (reciprocità auto-accettata).
  Future<void> reconcileIncomingConnections() async {
    final uid = _uid;
    if (uid == null) return;
    final notifs = await _db
        .collection('users/$uid/notifications')
        .where('type', isEqualTo: 'colleague_added')
        .get();
    if (notifs.docs.isEmpty) return;
    final existing = await _db.collection('users/$uid/colleagues').get();
    final have = existing.docs.map((d) => d.id).toSet();
    for (final n in notifs.docs) {
      final from = n.data()['fromUid'] as String?;
      if (from == null || from == uid || have.contains(from)) continue;
      // Sicurezza: chiunque può creare una notifica 'colleague_added' (anche di
      // un'altra amministrazione, spoofando fromUid) → eviterebbe il consenso.
      // Auto-accetta SOLO se il profilo del mittente è leggibile, cioè della
      // stessa amministrazione (le rules negano la lettura cross-amministrazione).
      try {
        final sender = await _db.collection('users').doc(from).get();
        if (sender.exists) await _addColleagueLocal(from);
      } catch (_) {
        // Profilo non leggibile (altra amministrazione / permessi) → ignora.
      }
    }
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
        // F2 — i profili privati non compaiono nella ricerca / non sono
        // aggiungibili da altri colleghi.
        .where(
          (d) =>
              d.id != uid &&
              !excludeUids.contains(d.id) &&
              (d.data()['isPrivate'] != true),
        )
        .map((d) => {'uid': d.id, ...d.data()})
        .toList()
      ..sort(
        (a, b) =>
            (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''),
      );
  }

  /// F2 — imposta la visibilità del proprio profilo. Privato = invisibile agli
  /// altri colleghi (non in ricerca, non aggiungibile, feed nascosto).
  Future<void> setPrivate(bool isPrivate) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({'isPrivate': isPrivate});
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

  // Anti-spam client-side: minimo 60s tra inviti allo stesso destinatario.
  // ponytail: mappa in-memory (si azzera al riavvio) — l'enforcement vero
  // del cap è nella Function; le rules onorano solo eventuali ban legacy già
  // esistenti e non ne creano di nuovi. Questo throttle resta solo UX.
  static final _lastInviteAt = <String, DateTime>{};

  Future<void> sendCoffeeInvite({
    required String toUid,
    required String fromName,
    String? scheduledAt,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final last = _lastInviteAt[toUid];
    if (last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 60)) {
      return; // invito duplicato ravvicinato: ignora in silenzio
    }
    _lastInviteAt[toUid] = DateTime.now();
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
        // ponytail: 200 copre inbox + statistiche caffè del mese; se un
        // utente supera 200 notifiche/mese le stats sottostimano — in quel
        // caso passare a query dedicate con range sul mese.
        .limit(200)
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
    // Notifica appena cancellata (es. da un altro device): update lancerebbe.
    if (!snap.exists) return;
    await docRef.update({'status': responseType, 'read': true});

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

  Future<void> renameGroup(String groupId, String newName) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('users/$uid/groups').doc(groupId).update({
      'name': newName.trim(),
    });
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
        if (n.type == 'coffee_accepted' && n.responseType == 'accepted') {
          accepted++;
        }
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
