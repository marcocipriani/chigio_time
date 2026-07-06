import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../authentication/data/auth_repository.dart';
import '../../authentication/presentation/onboarding_provider.dart';
import '../domain/monthly_sau.dart';
import '../domain/cap_period.dart';

part 'profile_repository.g.dart';

/// Single source of truth for "is this user's onboarding complete?".
///
/// Two accepted conditions (B handles documents written before the
/// `hasCompletedOnboarding` flag existed — backward-compat):
///   A) hasCompletedOnboarding == true
///   B) doc has the core onboarding fields (name + employmentType)
///
/// NOTE: the previous B variant also required `containsKey('standardDailyMins')`.
/// That key was occasionally absent on otherwise-completed accounts, causing the
/// router to wrongly re-trigger onboarding on a fresh device (no local prefs
/// cache). Dropped. `name`/`employmentType` are written only by onboarding
/// completion (NOT by the login-time `syncPhotoUrl`, which sets only
/// `photoURL`), so a doc with a name reliably means the user has onboarded —
/// while brand-new users (photoURL-only or no doc) still go through onboarding.
///
/// Used by both the router redirect and [hasProfileStream] so the two
/// checks can never diverge.
bool profileDocIsComplete(Map<String, dynamic>? data) {
  if (data == null) return false;
  if (data['hasCompletedOnboarding'] == true) return true;
  return (data['name'] as String? ?? '').trim().isNotEmpty &&
      (data['employmentType'] as String? ?? '').trim().isNotEmpty;
}

class ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ProfileRepository(this._firestore, this._auth);

  Future<void> updateProfileFields(Map<String, dynamic> fields) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('User not authenticated');
    await _firestore.collection('users').doc(user.uid).update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// C1 (review 2026-07-05): i totalizzatori del portale sono dati HR
  /// personali (matricola, ferie, straordinari) → vivono in private/
  /// (owner-only), NON sul doc utente leggibile dai colleghi della stessa
  /// amministrazione. Il salvataggio rimuove anche il blob legacy
  /// `portaleJson` dal doc utente (migrazione lazy al primo save).
  Future<void> savePortaleData(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('User not authenticated');
    final batch = _firestore.batch();
    batch.set(_firestore.doc('users/${user.uid}/private/portale'), data);
    batch.set(_firestore.collection('users').doc(user.uid), {
      'portaleJson': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> saveCustomCounters(List<Map<String, dynamic>> counters) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('User not authenticated');
    await _firestore.collection('users').doc(user.uid).update({
      'customCounters': counters,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePhoneNumber(String phone) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('User not authenticated');
    final trimmed = phone.trim();
    await _firestore.collection('users').doc(user.uid).update({
      'phoneNumber': trimmed.isEmpty ? FieldValue.delete() : trimmed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> syncPhotoUrl(String photoUrl) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).set({
      'photoURL': photoUrl,
    }, SetOptions(merge: true));
  }

  Future<void> updateCurrentStatus(String status) async {
    final user = _auth.currentUser;
    if (user == null) return; // fire-and-forget caller; no-op when signed out
    // M1: data LOCALE come tutto il resto dell'app (era UTC → status con la
    // data di ieri tra la mezzanotte UTC e quella italiana).
    await _firestore.collection('users').doc(user.uid).update({
      'currentStatus': status,
      'statusDate': todayId(),
    });
  }

  // ── SAU monthly history ──────────────────────────────────────────────────

  Future<void> saveMonthlySau({
    required int year,
    required int month,
    required int sliHours,
    required int sboHours,
    String? note,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final monthId = '$year-${month.toString().padLeft(2, '0')}';
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sau_monthly')
        .doc(monthId)
        .set({
          'sliHours': sliHours,
          'sboHours': sboHours,
          'sauHours': sliHours + sboHours,
          if (note != null && note.isNotEmpty) 'note': note,
          'recordedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Stream<List<MonthlySau>> monthlySauHistoryStream({int months = 12}) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    final now = DateTime.now();
    final from = DateTime(now.year, now.month - months + 1);
    final fromId = '${from.year}-${from.month.toString().padLeft(2, '0')}';
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sau_monthly')
        .orderBy(FieldPath.documentId)
        .startAt([fromId])
        .snapshots()
        .map((s) => s.docs.map(MonthlySau.fromFirestore).toList());
  }

  // ── Profile photo upload ─────────────────────────────────────────────────

  Future<String?> uploadProfilePhoto(XFile imageFile) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final bytes = await imageFile.readAsBytes();
    final ref = FirebaseStorage.instance.ref('profile_photos/${user.uid}.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();
    await _firestore.collection('users').doc(user.uid).update({
      'photoURL': url,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return url;
  }

  Future<void> saveOnboardingData(OnboardingState state) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('User not authenticated');
    await _firestore.collection('users').doc(user.uid).set({
      'name': state.name,
      'administration': state.administration,
      'employmentType': state.employmentType,
      'standardDailyMins': state.standardDailyHours.inMinutes,
      'mealVoucherThresholdMins': state.mealVoucherThreshold.inMinutes,
      'monthlyArt9Hours': state.monthlyArt9Hours,
      'monthlyOvertimeHours': state.monthlyOvertimeHours,
      'themePreference': state.themePreference.toString(),
      'dipartimento': state.dipartimento,
      'sede': state.sede,
      'sedeId': state.sedeId,
      'sedeAddress': state.sedeAddress,
      if (state.sedeLat != null) 'sedeLat': state.sedeLat,
      if (state.sedeLng != null) 'sedeLng': state.sedeLng,
      'monthlySliHours': state.monthlySliHours,
      'monthlySboHours': state.monthlySboHours,
      'gender': state.gender,
      'scheduleVariant': state.scheduleVariant,
      'longWorkDays': state.longWorkDays,
      if (state.hireDate != null) 'hireDate': dateIdOf(state.hireDate!),
      // Nuovi account: Home con la sola timbratura; i widget si aggiungono
      // dalla CTA in Home o da Profilo › Widget e visibilità.
      'hiddenHomeWidgets': AppConstants.homeWidgetIds,
      'hasCompletedOnboarding': true,
      if (user.photoURL != null) 'photoURL': user.photoURL!,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Export "Scarica i miei dati" (M2/M3, review 2026-07-05) ──────────────

  /// Converte ricorsivamente i Timestamp Firestore in stringhe ISO: senza
  /// questo `jsonEncode` lancia su qualunque doc con serverTimestamp
  /// (l'export era rotto per ogni profilo con `updatedAt`).
  static dynamic _jsonSafe(dynamic v) {
    if (v is Timestamp) return v.toDate().toIso8601String();
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), _jsonSafe(val)));
    }
    if (v is List) return v.map(_jsonSafe).toList();
    return v;
  }

  /// Raccoglie tutti i dati dell'utente per l'export: profilo (incluso il
  /// portale privato, senza token FCM), timesheet completi e ultime 500
  /// notifiche. Tutti i valori sono JSON-encodabili.
  Future<
    ({
      Map<String, dynamic> profile,
      List<Map<String, dynamic>> timesheets,
      List<Map<String, dynamic>> notifications,
    })
  >
  fetchMyData() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('User not authenticated');
    final uid = user.uid;

    final profile =
        (await _firestore.collection('users').doc(uid).get()).data() ?? {};
    profile.remove('fcmToken');
    final portale = (await _firestore
            .doc('users/$uid/private/portale')
            .get())
        .data();
    if (portale != null && portale.isNotEmpty) {
      profile['portaleJson'] = portale;
    }

    final timesheets = await _firestore
        .collection('users')
        .doc(uid)
        .collection('timesheets')
        .orderBy(FieldPath.documentId)
        .get();

    // M2: NIENTE orderBy qui — `createdAt` esiste solo sugli exit_reminder e
    // Firestore esclude dal result set i doc senza il campo ordinato: con
    // l'orderBy l'export perdeva tutte le notifiche social.
    final notifications = await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .limit(500)
        .get();

    return (
      profile: _jsonSafe(profile) as Map<String, dynamic>,
      timesheets: [
        for (final d in timesheets.docs)
          {'id': d.id, ...(_jsonSafe(d.data()) as Map<String, dynamic>)},
      ],
      notifications: [
        for (final d in notifications.docs)
          {'id': d.id, ...(_jsonSafe(d.data()) as Map<String, dynamic>)},
      ],
    );
  }

  // ── Cap periods (effective-dated inquadramento/caps — ADR-0009) ──────────

  static String monthId(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  static String nextMonthId(DateTime d) {
    final n = d.month == 12
        ? DateTime(d.year + 1, 1)
        : DateTime(d.year, d.month + 1);
    return monthId(n);
  }

  CollectionReference<Map<String, dynamic>> _capPeriodsCol(String uid) =>
      _firestore.collection('users/$uid/capPeriods');

  Stream<List<CapPeriod>> capPeriodsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(const []);
    return _capPeriodsCol(user.uid)
        .orderBy('fromMonth', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => CapPeriod.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<List<CapPeriod>> _fetchPeriods(String uid) async {
    final snap = await _capPeriodsCol(uid).get();
    return snap.docs.map((d) => CapPeriod.fromMap(d.id, d.data())).toList();
  }

  /// Ensure a baseline open period exists (lazy migration for users that signed
  /// up before ADR-0009). Seeds it from the current flat fields.
  Future<CapPeriod?> _ensureBaselinePeriod(
    String uid,
    List<CapPeriod> periods,
  ) async {
    if (periods.isNotEmpty) return null;
    final u =
        (await _firestore.collection('users').doc(uid).get()).data() ?? {};
    final ref = await _capPeriodsCol(uid).add({
      'fromMonth': monthId(DateTime.now()),
      'toMonth': null,
      'inquadramento': u['employmentType'] ?? '',
      'standardDailyMins': u['standardDailyMins'] ?? 456,
      'mealVoucherThresholdMins': u['mealVoucherThresholdMins'] ?? 380,
      'monthlyArt9Hours': u['monthlyArt9Hours'] ?? 0,
      'monthlySliHours': u['monthlySliHours'] ?? 0,
      'monthlySboHours': u['monthlySboHours'] ?? 0,
      'scheduleVariant': u['scheduleVariant'] ?? 'uniform',
      'longWorkDays': u['longWorkDays'] ?? <int>[],
    });
    final doc = await ref.get();
    return CapPeriod.fromMap(doc.id, doc.data()!);
  }

  /// Change inquadramento with historization: the currently-open period is
  /// closed at the current month and a new open period starts next month, so
  /// past months keep their caps. If a change was already made this month (an
  /// open period that only takes effect next month), it is overwritten in place
  /// instead of creating a degenerate empty range.
  Future<void> changeInquadramento(Map<String, dynamic> newCaps) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final periods = await _fetchPeriods(user.uid);
    final now = DateTime.now();
    final thisMonth = monthId(now);
    final nextMonth = nextMonthId(now);
    final col = _capPeriodsCol(user.uid);
    final batch = _firestore.batch();

    CapPeriod? open;
    for (final p in periods) {
      if (p.isOpen) open = p;
    }

    if (open != null && open.fromMonth.compareTo(thisMonth) > 0) {
      // A pending future period (created earlier this month): overwrite it.
      batch.set(col.doc(open.id), {
        ...newCaps,
        'fromMonth': open.fromMonth,
        'toMonth': null,
      });
    } else {
      if (open != null) {
        batch.update(col.doc(open.id), {'toMonth': thisMonth});
      }
      batch.set(col.doc(), {
        ...newCaps,
        'fromMonth': nextMonth,
        'toMonth': null,
      });
    }
    // Flat fields stay = current month's (old) caps until next month.
    batch.update(_firestore.collection('users').doc(user.uid), {
      'employmentType': newCaps['inquadramento'],
    });
    await batch.commit();
  }

  /// Apply a fine-grained cap edit (SLI/SBO/Art.9/meal/orario) to the period in
  /// force for the CURRENT month AND mirror it onto the flat user-doc fields
  /// (live/back-compat source). Self-fetches periods; seeds a baseline period
  /// for pre-migration users.
  Future<void> updateCaps(Map<String, dynamic> capFields) async {
    final user = _auth.currentUser;
    if (user == null) return;
    var periods = await _fetchPeriods(user.uid);
    final seeded = await _ensureBaselinePeriod(user.uid, periods);
    if (seeded != null) periods = [seeded];

    CapPeriod? open;
    for (final p in periods) {
      if (p.isOpen) open = p;
    }
    final target = capsForMonth(periods, monthId(DateTime.now())) ?? open;
    final batch = _firestore.batch();
    if (target != null) {
      batch.update(_capPeriodsCol(user.uid).doc(target.id), capFields);
    }
    batch.update(_firestore.collection('users').doc(user.uid), capFields);
    await batch.commit();
  }
}

@riverpod
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
}

@riverpod
Stream<List<MonthlySau>> monthlySauHistoryStream(Ref ref) =>
    ref.watch(profileRepositoryProvider).monthlySauHistoryStream(months: 12);

@riverpod
Stream<List<CapPeriod>> capPeriodsStream(Ref ref) =>
    ref.watch(profileRepositoryProvider).capPeriodsStream();

// Returns true when the user has a complete profile (see [profileDocIsComplete]).
//
// When the doc qualifies via the backward-compat path (min fields but no
// explicit flag), the flag is back-filled so subsequent checks use the faster
// path. The back-fill fires at most once per auth session to avoid repeated
// writes for offline users.
@riverpod
Stream<bool> hasProfileStream(Ref ref) {
  // Rebuild when auth state changes — Riverpod cancels the old Firestore
  // stream and starts a new one for the new user, equivalent to switchMap.
  final authState = ref.watch(authStateChangesProvider);
  if (authState.isLoading) return const Stream.empty();
  final user = authState.asData?.value;
  if (user == null) return Stream.value(false);

  final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
  var backfilled = false;

  return docRef.snapshots().map((snap) {
    if (!snap.exists) return false;
    final data = snap.data()!;

    if (!profileDocIsComplete(data)) return false;

    // Complete via backward-compat path (min fields, no explicit flag):
    // back-fill the flag once so later checks take the fast path.
    if (data['hasCompletedOnboarding'] != true && !backfilled) {
      backfilled = true;
      docRef.update({'hasCompletedOnboarding': true}).ignore();
    }
    return true;
  });
}

// C1: stream del doc privato users/{uid}/private/portale (totalizzatori HR).
@riverpod
Stream<Map<String, dynamic>?> privatePortaleStream(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);
  if (authState.isLoading) return const Stream.empty();
  final user = authState.asData?.value;
  if (user == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .doc('users/${user.uid}/private/portale')
      .snapshots()
      .map((snap) => snap.data());
}

/// Dati portale correnti: nuova posizione privata, con fallback sul campo
/// legacy `portaleJson` del doc utente per gli account non ancora migrati.
/// La migrazione avviene al primo salvataggio (vedi [ProfileRepository.savePortaleData]).
@riverpod
Map<String, dynamic>? portaleRaw(Ref ref) {
  final private = ref.watch(privatePortaleStreamProvider).asData?.value;
  if (private != null && private.isNotEmpty) return private;
  final legacy = ref.watch(userProfileStreamProvider).asData?.value?['portaleJson'];
  return legacy is Map ? Map<String, dynamic>.from(legacy) : null;
}

// Stream to fetch full profile data, reactive to auth state changes.
@riverpod
Stream<Map<String, dynamic>?> userProfileStream(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);
  if (authState.isLoading) return const Stream.empty();
  final user = authState.asData?.value;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snap) => snap.data());
}
