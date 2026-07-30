import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:sakshi_vani/data/local/local_storage_service.dart';
import 'package:sakshi_vani/data/repositories/auth_repository.dart';
import 'package:sakshi_vani/features/auth/controller/auth_controller.dart';
import 'package:sakshi_vani/features/auth/domain/app_user.dart';
import 'package:sakshi_vani/features/auth/domain/auth_state.dart';
import 'package:sakshi_vani/services/sync_service.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSyncService extends Mock implements SyncService {}

class MockLocalStorageService extends Mock implements LocalStorageService {}

/// [FirebaseAuthException]'s constructor is `@protected` (subclass-only) in
/// firebase_auth_platform_interface; building one here to drive
/// [AuthController]'s error mapping is the standard workaround.
// ignore: invalid_use_of_protected_member
FirebaseAuthException _authException(String code) => FirebaseAuthException(code: code);

const AppUser _localGuest =
    AppUser(uid: 'guest-1', isAnonymous: false, isLocalOnly: true, displayName: 'Local Guest');

void main() {
  late MockAuthRepository authRepository;
  late MockSyncService syncService;
  late MockLocalStorageService localStorage;
  late AuthController controller;

  setUp(() async {
    authRepository = MockAuthRepository();
    syncService = MockSyncService();
    localStorage = MockLocalStorageService();

    when(() => authRepository.authStateChanges()).thenAnswer((_) => const Stream<AppUser>.empty());
    when(() => syncService.flushPendingQueue()).thenAnswer((_) async {});
    when(() => syncService.pullFromCloud()).thenAnswer((_) async {});
    when(() => syncService.setSyncEnabled(any())).thenAnswer((_) async {});
    when(() => localStorage.setCloudSyncEntitlement(any())).thenAnswer((_) async {});
    when(() => authRepository.getCurrentUser()).thenAnswer((_) async => _localGuest);

    controller = AuthController(authRepository, syncService, localStorage);
    await controller.initialize();
  });

  tearDown(() {
    controller.dispose();
  });

  test('initialize resolves to local guest and does not trigger a sync', () async {
    expect(controller.state.status, AuthStatus.localGuest);
    verifyNever(() => syncService.flushPendingQueue());
    verifyNever(() => syncService.pullFromCloud());
    verify(() => localStorage.setCloudSyncEntitlement(false)).called(1);
  });

  test('signInEmail success authenticates and flushes + pulls sync', () async {
    const AppUser signedIn = AppUser(uid: 'u1', isAnonymous: false, isLocalOnly: false, email: 'a@b.com');
    when(() => authRepository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => signedIn);

    await controller.signInEmail(email: 'a@b.com', password: 'secret');

    expect(controller.state.status, AuthStatus.authenticated);
    expect(controller.state.user?.uid, 'u1');
    expect(controller.state.errorMessage, isNull);
    verify(() => syncService.flushPendingQueue()).called(1);
    verify(() => syncService.pullFromCloud()).called(1);
    verify(() => syncService.setSyncEnabled(true)).called(1);
    verify(() => localStorage.setCloudSyncEntitlement(true)).called(1);
  });

  test('signInEmail maps wrong-password to a friendly message without syncing', () async {
    when(() => authRepository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(_authException('wrong-password'));

    await controller.signInEmail(email: 'a@b.com', password: 'bad');

    expect(controller.state.status, AuthStatus.error);
    expect(controller.state.errorMessage, 'Incorrect email or password.');
    verifyNever(() => syncService.flushPendingQueue());
  });

  test('signInEmail maps network-request-failed to a friendly message', () async {
    when(() => authRepository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(_authException('network-request-failed'));

    await controller.signInEmail(email: 'a@b.com', password: 'x');

    expect(controller.state.errorMessage, 'Network unavailable. Please try again.');
  });

  test('signInGoogle cancellation surfaces the StateError message as-is', () async {
    when(() => authRepository.signInWithGoogle())
        .thenThrow(StateError('Google sign-in cancelled.'));

    await controller.signInGoogle();

    expect(controller.state.status, AuthStatus.error);
    expect(controller.state.errorMessage, 'Google sign-in cancelled.');
  });

  test('continueAnonymous authenticates as anonymous', () async {
    const AppUser anon = AppUser(uid: 'anon-1', isAnonymous: true, isLocalOnly: false);
    when(() => authRepository.signInAnonymously()).thenAnswer((_) async => anon);

    await controller.continueAnonymous();

    expect(controller.state.status, AuthStatus.anonymous);
    verifyNever(() => syncService.setSyncEnabled(any()));
  });

  test('sendPasswordReset returns true and clears errors on success', () async {
    when(() => authRepository.sendPasswordResetEmail(any())).thenAnswer((_) async {});

    final bool result = await controller.sendPasswordReset('a@b.com');

    expect(result, isTrue);
    expect(controller.state.errorMessage, isNull);
  });

  test('sendPasswordReset returns false and humanizes the error on failure', () async {
    when(() => authRepository.sendPasswordResetEmail(any()))
        .thenThrow(_authException('user-not-found'));

    final bool result = await controller.sendPasswordReset('missing@b.com');

    expect(result, isFalse);
    expect(controller.state.errorMessage, 'No account exists for this email.');
  });

  test('signOut falls back to local guest and clears the session', () async {
    when(() => authRepository.signOut()).thenAnswer((_) async {});

    await controller.signOut();

    expect(controller.state.status, AuthStatus.localGuest);
  });
}
