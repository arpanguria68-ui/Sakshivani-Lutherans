import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/local_storage_service.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../services/sync_service.dart';
import '../domain/app_user.dart';
import '../domain/auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._authRepository, this._syncService, this._localStorage)
      : super(AuthState.loading);

  final AuthRepository _authRepository;
  final SyncService _syncService;
  final LocalStorageService _localStorage;

  StreamSubscription<AppUser>? _subscription;

  /// Sets [state] from [user], mirrors the "cloud sync unlocked" entitlement
  /// locally, and — only for a genuinely authenticated (non-anonymous,
  /// non-guest) user — flushes/pulls cloud sync and mirrors the entitlement
  /// onto Firestore too. This is the single place that decides whether sync
  /// is allowed, so every auth transition (initial load, live auth-state
  /// changes, sign-in/up/Google/anonymous) goes through it.
  Future<void> _applyState(AppUser user) async {
    state = _stateFromUser(user);
    final bool entitled = state.isAuthenticated;
    await _localStorage.setCloudSyncEntitlement(entitled);
    if (entitled) {
      await _syncService.flushPendingQueue();
      await _syncService.pullFromCloud();
      await _syncService.setSyncEnabled(true);
    }
  }

  Future<void> initialize() async {
    final AppUser user = await _authRepository.getCurrentUser();
    await _applyState(user);

    _subscription = _authRepository.authStateChanges().listen(_applyState);
  }

  Future<void> signInEmail({required String email, required String password}) async {
    await _runAuthAction(() => _authRepository.signInWithEmail(email: email, password: password));
  }

  Future<void> signUpEmail({required String email, required String password}) async {
    await _runAuthAction(() => _authRepository.signUpWithEmail(email: email, password: password));
  }

  Future<void> signInGoogle() async {
    await _runAuthAction(_authRepository.signInWithGoogle);
  }

  Future<void> continueAnonymous() async {
    await _runAuthAction(_authRepository.signInAnonymously);
  }

  /// Sends the OTP SMS. Returns the verification ID for [confirmPhoneCode]
  /// on success, or null on failure (check [state].errorMessage). Some
  /// Android devices auto-verify without any code entry — in that case this
  /// completes sign-in directly and also returns null (there's no code step
  /// left to confirm), so callers should check [state] after either way.
  Future<String?> sendPhoneCode(String phoneNumber) async {
    final AuthStatus previousStatus = state.status;
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    final Completer<String?> verificationId = Completer<String?>();
    await _authRepository.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      onCodeSent: (String id) {
        // Clears the loading spinner (code is sent; the OTP screen takes
        // over from here) without pretending the user is now authenticated.
        state = state.copyWith(status: previousStatus);
        if (!verificationId.isCompleted) verificationId.complete(id);
      },
      onAutoVerified: (AppUser user) async {
        await _applyState(user);
        if (!verificationId.isCompleted) verificationId.complete(null);
      },
      onError: (Object e) {
        state = state.copyWith(status: AuthStatus.error, errorMessage: _humanizeError(e));
        if (!verificationId.isCompleted) verificationId.complete(null);
      },
    );
    return verificationId.future;
  }

  Future<void> confirmPhoneCode({required String verificationId, required String smsCode}) async {
    await _runAuthAction(
      () => _authRepository.signInWithSmsCode(verificationId: verificationId, smsCode: smsCode),
    );
  }

  /// Free (no SMS cost) alternative to phone sign-in: emails a 6-digit code
  /// via the `cloudflare/email-otp-worker` deployment. Returns true if the
  /// email was sent — check [state].errorMessage on false.
  Future<bool> sendEmailCode(String email) async {
    final AuthStatus previousStatus = state.status;
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _authRepository.requestEmailCode(email);
      state = state.copyWith(status: previousStatus);
      return true;
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: _humanizeError(e));
      return false;
    }
  }

  Future<void> confirmEmailCode({required String email, required String code}) async {
    await _runAuthAction(() => _authRepository.confirmEmailCode(email: email, code: code));
  }

  /// Returns true on success. The forgot-password screen should only show
  /// its "check your email" message when this returns true, not blindly.
  Future<bool> sendPasswordReset(String email) async {
    try {
      await _authRepository.sendPasswordResetEmail(email);
      state = state.copyWith(errorMessage: null);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: _humanizeError(e));
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      final AppUser user = await _authRepository.getCurrentUser();
      await _applyState(user);
    } catch (e) {
      state = state.copyWith(errorMessage: _humanizeError(e));
    }
  }

  /// Permanently deletes the account: re-auths if needed (email users need
  /// [password]; Google users get a re-consent prompt), wipes Firestore
  /// data, deletes the Firebase user, then wipes local data and resets
  /// onboarding so the app returns to a true first-run state. Returns true
  /// on success; check [state].errorMessage on failure.
  Future<bool> deleteAccount({String? password}) async {
    final AppUser? user = state.user;
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      if (user != null && !user.isLocalOnly && !user.isAnonymous) {
        await _authRepository.reauthenticate(password: password);
      }
      await _syncService.deleteCloudUserData();
      await _authRepository.deleteFirebaseAccount();
      return true;
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: _humanizeError(e));
      return false;
    }
  }

  Future<void> _runAuthAction(Future<AppUser> Function() action) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final AppUser user = await action();
      await _applyState(user);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _humanizeError(e),
      );
    }
  }

  AuthState _stateFromUser(AppUser user) {
    if (user.isLocalOnly) {
      return AuthState(status: AuthStatus.localGuest, user: user);
    }
    if (user.isAnonymous) {
      return AuthState(status: AuthStatus.anonymous, user: user);
    }
    return AuthState(status: AuthStatus.authenticated, user: user);
  }

  // Maps by exception type/code rather than matching on exception message
  // text, which is not a stable contract across firebase_auth SDK versions.
  String _humanizeError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'user-not-found':
          return 'No account exists for this email.';
        case 'email-already-in-use':
          return 'This email is already registered.';
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait and try again.';
        case 'network-request-failed':
          return 'Network unavailable. Please try again.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'requires-recent-login':
          return 'Please sign in again to confirm this action.';
        case 'credential-already-in-use':
          return 'That account is already linked to a different sign-in.';
        case 'invalid-phone-number':
          return 'That phone number looks invalid. Include the country code.';
        case 'invalid-verification-code':
          return 'Incorrect code. Please check and try again.';
        case 'session-expired':
          return 'That code expired. Request a new one.';
        case 'quota-exceeded':
          return 'SMS limit reached for now. Please try again later.';
        default:
          return 'Authentication failed. Please try again.';
      }
    }
    if (error is StateError) {
      return error.message;
    }
    return 'Authentication failed. Please try again.';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
