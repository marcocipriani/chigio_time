import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/salary_payment.dart';

part 'salary_repository.g.dart';

/// Firestore-only repository for salary credits.
///
/// Data lives under `users/{uid}/salaryPayments/{id}` (owner-only rules).
/// No Drift mirror yet — like `capPeriods`/`sau_monthly`, this is Firestore
/// canonical with offline handled by the SDK cache.
class SalaryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SalaryRepository(this._firestore, this._auth);

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users/$uid/salaryPayments');

  Stream<List<SalaryPayment>> paymentsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(const []);
    return _col(user.uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => SalaryPayment.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> addPayment(SalaryPayment p) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('User not authenticated');
    await _col(
      user.uid,
    ).add({...p.toMap(), 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> updatePayment(SalaryPayment p) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('User not authenticated');
    await _col(user.uid).doc(p.id).set(p.toMap(), SetOptions(merge: true));
  }

  Future<void> deletePayment(String id) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('User not authenticated');
    await _col(user.uid).doc(id).delete();
  }
}

@riverpod
SalaryRepository salaryRepository(Ref ref) =>
    SalaryRepository(FirebaseFirestore.instance, FirebaseAuth.instance);

@riverpod
Stream<List<SalaryPayment>> salaryPaymentsStream(Ref ref) =>
    ref.watch(salaryRepositoryProvider).paymentsStream();
