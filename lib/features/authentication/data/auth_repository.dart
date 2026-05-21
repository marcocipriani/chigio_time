import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

@riverpod
FirebaseAuth firebaseAuth(Ref ref) => FirebaseAuth.instance;

@riverpod
Stream<User?> authStateChanges(Ref ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
}

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(ref.watch(firebaseAuthProvider));
}

class AuthRepository {
  final FirebaseAuth _auth;

  // GoogleSignIn v7: singleton, initialize() must be called exactly once.
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _googleSignInInitialized = false;

  AuthRepository(this._auth);

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // SOLUZIONE WEB: La documentazione Firebase richiede l'uso del Popup integrato
        // per evitare i blocchi di sicurezza del nuovo standard Google su Chrome.
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        return await _auth.signInWithPopup(googleProvider);
      } else {
        // SOLUZIONE MOBILE (Android/iOS)

        // initialize() must be called exactly once per app lifecycle.
        if (!_googleSignInInitialized) {
          await _googleSignIn.initialize();
          _googleSignInInitialized = true;
        }

        final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
          scopeHint: ['email', 'profile'],
        );

        final authorization = await googleUser.authorizationClient
            .authorizeScopes(['email', 'profile']);

        final authentication = googleUser.authentication;
        final idToken = authentication.idToken;
        if (idToken == null) {
          throw Exception('Google sign-in failed: ID token is null');
        }

        final credential = GoogleAuthProvider.credential(
          idToken: idToken,
          accessToken: authorization.accessToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      debugPrint("Errore durante l'accesso con Google: $e");
      rethrow;
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      debugPrint('Errore accesso email: $e');
      rethrow;
    }
  }

  Future<UserCredential?> registerWithEmail(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      debugPrint('Errore registrazione email: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      debugPrint('Errore reset password: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      // disconnect() revokes server-side OAuth grants; errors are non-fatal.
      try {
        await _googleSignIn.disconnect();
      } catch (e) {
        debugPrint('Google disconnect failed (non-fatal): $e');
      }
    }
    // Always clear the Firebase session, even if disconnect() threw.
    await _auth.signOut();
  }
}
