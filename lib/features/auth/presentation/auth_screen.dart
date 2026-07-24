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
              onPressed: state.status == AuthStatus.loading
                  ? null
                  : () => ref.read(authControllerProvider.notifier).signInGoogle(),
              icon: const Icon(Icons.account_circle_outlined),
              label: const Text('Continue with Google'),
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: state.status == AuthStatus.loading
                  ? null
                  : () => ref.read(authControllerProvider.notifier).continueAnonymous(),
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

    if (!mounted) {
      return;
    }

    final AuthState state = ref.read(authControllerProvider);
    if (state.isAuthenticated || state.status == AuthStatus.anonymous || state.status == AuthStatus.localGuest) {
      context.go('/');
    }
  }
}
