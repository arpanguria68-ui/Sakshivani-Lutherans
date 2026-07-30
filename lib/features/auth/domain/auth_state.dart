import 'app_user.dart';

enum AuthStatus {
  loading,
  localGuest,
  anonymous,
  authenticated,
  error,
}

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;

  bool get canSync => status == AuthStatus.authenticated;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  static const AuthState loading = AuthState(status: AuthStatus.loading);
}
