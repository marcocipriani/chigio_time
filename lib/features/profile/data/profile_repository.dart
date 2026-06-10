import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../authentication/data/auth_repository.dart';
import '../../authentication/presentation/onboarding_provider.dart';
import '../domain/monthly_sau.dart';

part 'profile_repository.g.dart';

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

  Future<void> savePortaleData(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('User not authenticated');
    await _firestore.collection('users').doc(user.uid).update({
      'portaleJson': data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
    await _firestore.collection('users').doc(user.uid).set(
      {'photoURL': photoUrl},
      SetOptions(merge: true),
    );
  }

  Future<void> updateCurrentStatus(String status) async {
    final user = _auth.currentUser;
    if (user == null) return; // fire-and-forget caller; no-op when signed out
    final d = DateTime.now().toUtc();
    final date =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    await _firestore.collection('users').doc(user.uid).update({
      'currentStatus': status,
      'statusDate': date,
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
    final fromId =
        '${from.year}-${from.month.toString().padLeft(2, '0')}';
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
    final ref = FirebaseStorage.instance.ref(
      'profile_photos/${user.uid}.jpg',
    );
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
      'hasCompletedOnboarding': true,
      if (user.photoURL != null) 'photoURL': user.photoURL!,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

@riverpod
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
}

@riverpod
Stream<List<MonthlySau>> monthlySauHistoryStream(Ref ref) =>
    ref.watch(profileRepositoryProvider).monthlySauHistoryStream(months: 12);

// Returns true when the user has a complete profile.
//
// Two conditions are accepted (the second handles documents written before
// the hasCompletedOnboarding flag was introduced — backward-compat):
//   A) hasCompletedOnboarding == true
//   B) doc exists AND has the three minimum fields from onboarding
//      (name, employmentType, standardDailyMins)
//
// When condition B fires, the flag is back-filled so subsequent checks
// always use the faster path A. The back-fill fires at most once per auth
// session to avoid repeated writes for offline users.
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

    // Path A — explicit flag (new documents)
    if (data['hasCompletedOnboarding'] == true) return true;

    // Path B — backwards-compat: doc has required onboarding fields
    final hasMinFields =
        (data['name'] as String? ?? '').isNotEmpty &&
        (data['employmentType'] as String? ?? '').isNotEmpty &&
        data.containsKey('standardDailyMins');

    if (hasMinFields) {
      if (!backfilled) {
        backfilled = true;
        docRef.update({'hasCompletedOnboarding': true}).ignore();
      }
      return true;
    }

    return false;
  });
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
