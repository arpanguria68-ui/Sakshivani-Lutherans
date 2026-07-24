import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../services/sync_service.dart';
import '../domain/app_user.dart';
import '../domain/auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._authRepository, this._syncService) : super(AuthState.loading);

  final AuthRepository _authRepository;
  final SyncService _syncService;

  StreamSubscription<AppUser>? _subscription;

  Future<void> initialize() async {
    final AppUser user = await _authRepository.getCurrentUser();
    state = _stateFromUser(user);

    _subscription = _authRepository.authStateChanges().listen((AppUser user) async {
      state = _stateFromUser(user);
      if (state.isAuthenticated) {
        await _syncService.flushPendingQueue();
      }
    });

    if (state.isAuthenticated) {
      await _syncService.flushPendingQueue();
    }
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

  Future<void> sendPasswordReset(String email) async {
    try {
      await _authRepository.sendPasswordResetEmail(email);
      state = state.copyWith(errorMessage: null);
    } catch (_) {
      state = state.copyWith(
        status: state.status,
        errorMessage: 'Password reset email could not be sent.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      final AppUser user = await _authRepository.getCurrentUser();
      state = _stateFromUser(user);
    } catch (_) {
      state = state.copyWith(errorMessage: 'Could not sign out right now.');
    }
  }

  Future<void> _runAuthAction(Future<AppUser> Function() action) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final AppUser user = await action();
      state = _stateFromUser(user);
      if (state.isAuthenticated) {
        await _syncService.flushPendingQueue();
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _humanizeError(e.toString()),
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

  String _humanizeError(String raw) {
    final String lower = raw.toLowerCase();
    if (lower.contains('wrong-password') || lower.contains('invalid-credential')) {
      return 'Incorrect email or password.';
    }
    if (lower.contains('user-not-found')) {
      return 'No account exists for this email.';
    }
    if (lower.contains('email-already-in-use')) {
      return 'This email is already registered.';
    }
    if (lower.contains('network')) {
      return 'Network unavailable. Please try again.';
    }
    if (lower.contains('not configured')) {
      return 'Firebase is not configured. Add firebase options first.';
    }
    return 'Authentication failed. Please try again.';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
