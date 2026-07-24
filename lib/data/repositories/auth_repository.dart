import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';

import '../../features/auth/domain/app_user.dart';
import '../local/local_storage_service.dart';

class AuthRepository {
  AuthRepository({
    required LocalStorageService localStorageService,
    required bool firebaseEnabled,
  })  : _localStorageService = localStorageService,
        _firebaseEnabled = firebaseEnabled;

  final LocalStorageService _localStorageService;
  final bool _firebaseEnabled;

  Stream<AppUser> authStateChanges() {
    if (!_firebaseEnabled) {
      return const Stream<AppUser>.empty();
    }

    return FirebaseAuth.instance.authStateChanges().asyncMap((User? user) async {
      if (user == null) {
        return _localGuestUser();
      }
      return _mapFirebaseUser(user);
    });
  }

  Future<AppUser> getCurrentUser() async {
    if (_firebaseEnabled) {
      final User? current = FirebaseAuth.instance.currentUser;
      if (current != null) {
        return _mapFirebaseUser(current);
      }

      try {
        final UserCredential credential = await FirebaseAuth.instance.signInAnonymously();
        final User? user = credential.user;
        if (user != null) {
          return _mapFirebaseUser(user);
        }
      } catch (_) {
        // Fallback to local mode.
      }
    }

    return _localGuestUser();
  }

  Future<AppUser> signInWithEmail({required String email, required String password}) async {
    if (!_firebaseEnabled) {
      throw StateError('Firebase is not configured yet.');
    }

    final User? current = FirebaseAuth.instance.currentUser;
    if (current != null && current.isAnonymous) {
      final AuthCredential credential =
          EmailAuthProvider.credential(email: email, password: password);
      try {
        final UserCredential linked = await current.linkWithCredential(credential);
        return _mapFirebaseUser(linked.user!);
      } on FirebaseAuthException catch (e) {
        if (e.code != 'credential-already-in-use') {
          rethrow;
        }
      }
    }

    final UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email.trim(), password: password);
    return _mapFirebaseUser(userCredential.user!);
  }

  Future<AppUser> signUpWithEmail({required String email, required String password}) async {
    if (!_firebaseEnabled) {
      throw StateError('Firebase is not configured yet.');
    }

    final User? current = FirebaseAuth.instance.currentUser;
    if (current != null && current.isAnonymous) {
      final AuthCredential credential =
          EmailAuthProvider.credential(email: email.trim(), password: password);
      final UserCredential linked = await current.linkWithCredential(credential);
      return _mapFirebaseUser(linked.user!);
    }

    final UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email.trim(), password: password);
    return _mapFirebaseUser(userCredential.user!);
  }

  Future<AppUser> signInWithGoogle() async {
    if (!_firebaseEnabled) {
      throw StateError('Firebase is not configured yet.');
    }

    final GoogleSignInAccount? account = await GoogleSignIn().signIn();
    if (account == null) {
      throw StateError('Google sign-in cancelled.');
    }

    final GoogleSignInAuthentication auth = await account.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );

    final User? current = FirebaseAuth.instance.currentUser;
    if (current != null && current.isAnonymous) {
      final UserCredential linked = await current.linkWithCredential(credential);
      return _mapFirebaseUser(linked.user!);
    }

    final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    return _mapFirebaseUser(userCredential.user!);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (!_firebaseEnabled) {
      return;
    }
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
  }

  Future<AppUser> signInAnonymously() async {
    if (_firebaseEnabled) {
      final UserCredential credential = await FirebaseAuth.instance.signInAnonymously();
      return _mapFirebaseUser(credential.user!);
    }

    return _localGuestUser();
  }

  Future<void> signOut() async {
    if (_firebaseEnabled) {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  Future<AppUser> _localGuestUser() async {
    String? uid = await _localStorageService.getLocalGuestUid();
    if (uid == null || uid.isEmpty) {
      uid = const Uuid().v4();
      await _localStorageService.setLocalGuestUid(uid);
    }

    return AppUser(
      uid: uid,
      isAnonymous: false,
      isLocalOnly: true,
      displayName: 'Local Guest',
    );
  }

  AppUser _mapFirebaseUser(User user) {
    return AppUser(
      uid: user.uid,
      isAnonymous: user.isAnonymous,
      isLocalOnly: false,
      email: user.email,
      displayName: user.displayName,
    );
  }
}
