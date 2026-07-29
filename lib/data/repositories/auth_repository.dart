import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
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

  /// Starts phone-number verification: Firebase sends an SMS. On some
  /// Android devices it auto-detects the code via SMS Retriever/Play
  /// Integrity without the user typing anything — [onAutoVerified] covers
  /// that case. Otherwise [onCodeSent] hands back the verification ID
  /// [signInWithSmsCode] needs once the user types the code themselves.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(AppUser user) onAutoVerified,
    required void Function(Object error) onError,
  }) async {
    if (!_firebaseEnabled) {
      onError(StateError('Firebase is not configured yet.'));
      return;
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          onAutoVerified(await _signInWithPhoneCredential(credential));
        } catch (e) {
          onError(e);
        }
      },
      verificationFailed: (FirebaseAuthException e) => onError(e),
      codeSent: (String verificationId, int? resendToken) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  /// Completes phone sign-in with the user-entered SMS code.
  Future<AppUser> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    if (!_firebaseEnabled) {
      throw StateError('Firebase is not configured yet.');
    }
    return _signInWithPhoneCredential(
      PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode),
    );
  }

  /// Links to the current anonymous session when possible (preserving its
  /// uid/local data continuity), else falls back to a fresh credential
  /// sign-in — same pattern as [signInWithGoogle].
  Future<AppUser> _signInWithPhoneCredential(PhoneAuthCredential credential) async {
    final User? current = FirebaseAuth.instance.currentUser;
    if (current != null && current.isAnonymous) {
      try {
        final UserCredential linked = await current.linkWithCredential(credential);
        return _mapFirebaseUser(linked.user!);
      } on FirebaseAuthException catch (e) {
        if (e.code != 'credential-already-in-use') {
          rethrow;
        }
      }
    }

    final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    return _mapFirebaseUser(userCredential.user!);
  }

  /// Asks the `cloudflare/email-otp-worker` deployment to email a 6-digit
  /// code to [email] (via Resend). Throws [StateError] on any failure —
  /// the worker itself is the thing sending the email, not Firebase.
  Future<void> requestEmailCode(String email) async {
    final Uri uri = Uri.parse('${AppConstants.emailOtpWorkerUrl}/send-code');
    final http.Response res = await http
        .post(
          uri,
          headers: <String, String>{'Content-Type': 'application/json'},
          body: json.encode(<String, String>{'email': email}),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw StateError('Could not send the code. Please try again.');
    }
  }

  /// Verifies [code] against the worker, then signs in with the Firebase
  /// custom token it returns. Unlike Google/Phone sign-in, this always
  /// resolves to a fixed uid derived from [email] — it does not link to an
  /// existing anonymous session (see the worker's README for why).
  Future<AppUser> confirmEmailCode({required String email, required String code}) async {
    if (!_firebaseEnabled) {
      throw StateError('Firebase is not configured yet.');
    }
    final Uri uri = Uri.parse('${AppConstants.emailOtpWorkerUrl}/verify-code');
    final http.Response res = await http
        .post(
          uri,
          headers: <String, String>{'Content-Type': 'application/json'},
          body: json.encode(<String, String>{'email': email, 'code': code}),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw StateError('Incorrect or expired code. Please try again.');
    }
    final Map<String, dynamic> body = json.decode(res.body) as Map<String, dynamic>;
    final String? token = body['token'] as String?;
    if (token == null || token.isEmpty) {
      throw StateError('Incorrect or expired code. Please try again.');
    }
    final UserCredential credential = await FirebaseAuth.instance.signInWithCustomToken(token);
    return _mapFirebaseUser(credential.user!);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (!_firebaseEnabled) {
      throw StateError('Firebase is not configured yet.');
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
    if (!_firebaseEnabled) {
      return;
    }
    await FirebaseAuth.instance.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Not signed in via Google, or the plugin has no session — fine either way.
    }
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (_) {
      // Leave the user fully signed-out; getCurrentUser()'s local-guest
      // fallback covers this on next read rather than leaving signOut() throw.
    }
  }

  /// Re-proves identity before a sensitive action (account deletion).
  /// No-op for anonymous/local-only users — nothing to re-prove.
  Future<void> reauthenticate({String? password}) async {
    if (!_firebaseEnabled) {
      return;
    }
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return;
    }
    final String providerId =
        user.providerData.isNotEmpty ? user.providerData.first.providerId : '';

    if (providerId == 'password') {
      final String? email = user.email;
      if (email == null || password == null || password.isEmpty) {
        throw StateError('Password required to confirm this action.');
      }
      final AuthCredential credential =
          EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);
      return;
    }

    if (providerId == 'google.com') {
      final GoogleSignInAccount? account = await GoogleSignIn().signIn();
      if (account == null) {
        throw StateError('Google re-authentication cancelled.');
      }
      final GoogleSignInAuthentication auth = await account.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      await user.reauthenticateWithCredential(credential);
    }
  }

  /// Permanently deletes the Firebase Auth user. Call [reauthenticate] first
  /// and wipe Firestore/local data before this — it cannot be undone.
  Future<void> deleteFirebaseAccount() async {
    if (!_firebaseEnabled) {
      return;
    }
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.delete();
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
