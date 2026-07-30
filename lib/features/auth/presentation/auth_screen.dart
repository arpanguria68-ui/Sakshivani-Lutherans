import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../domain/auth_state.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoginMode = true;
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthState state = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sign In & Sync')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              _isLoginMode ? 'Welcome back' : 'Create account',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to sync prayer logs, favorites, reflections and progress across devices.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _password,
              obscureText: _hidePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(_hidePassword ? Icons.visibility_off : Icons.visibility),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: state.status == AuthStatus.loading ? null : _submitEmail,
              child: Text(_isLoginMode ? 'Sign In' : 'Create Account'),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
              child: Text(_isLoginMode ? 'Need an account? Sign up' : 'Already have an account? Sign in'),
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: state.status == AuthStatus.loading ? null : _submitGoogle,
              icon: const Icon(Icons.account_circle_outlined),
              label: const Text('Continue with Google'),
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: state.status == AuthStatus.loading
                  ? null
                  : () => context.push('/auth/phone'),
              icon: const Icon(Icons.phone_outlined),
              label: const Text('Continue with Phone'),
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: state.status == AuthStatus.loading
                  ? null
                  : () => context.push('/auth/email-code'),
              icon: const Icon(Icons.mark_email_read_outlined),
              label: const Text('Sign in with Email Code'),
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: state.status == AuthStatus.loading ? null : _submitAnonymous,
              icon: const Icon(Icons.person_outline),
              label: const Text('Use Anonymous Cloud Session'),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => context.push('/auth/forgot'),
              child: const Text('Forgot password?'),
            ),
            if (state.errorMessage != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                state.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (state.status == AuthStatus.loading)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                style: Theme.of(context).textTheme.bodySmall,
                children: <InlineSpan>[
                  const TextSpan(
                    text:
                        'By creating an account or signing in, you agree to our ',
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: () => context.push('/legal/terms'),
                      child: Text(
                        'Terms',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: () => context.push('/legal/privacy'),
                      child: Text(
                        'Privacy Policy',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' (EN / हिंदी · US · EU · India).'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Free-tier note: This app uses Firebase Spark limits and keeps static content offline so costs remain \$0 in early stages.',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitEmail() async {
    final String email = _email.text.trim();
    final String password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      return;
    }

    final controller = ref.read(authControllerProvider.notifier);
    if (_isLoginMode) {
      await controller.signInEmail(email: email, password: password);
    } else {
      await controller.signUpEmail(email: email, password: password);
    }
    _leaveIfSignedIn();
  }

  Future<void> _submitGoogle() async {
    await ref.read(authControllerProvider.notifier).signInGoogle();
    _leaveIfSignedIn();
  }

  Future<void> _submitAnonymous() async {
    await ref.read(authControllerProvider.notifier).continueAnonymous();
    _leaveIfSignedIn();
  }

  /// The router's own redirect only leaves `/auth` for `AuthStatus.authenticated`
  /// (a real account) — anonymous/local-guest sign-in succeeds but wouldn't
  /// otherwise navigate anywhere, leaving the user stuck on this screen with
  /// no error and no visible feedback. This covers those cases explicitly.
  void _leaveIfSignedIn() {
    if (!mounted) {
      return;
    }
    final AuthState state = ref.read(authControllerProvider);
    if (state.isAuthenticated || state.status == AuthStatus.anonymous || state.status == AuthStatus.localGuest) {
      context.go('/');
    }
  }
}
