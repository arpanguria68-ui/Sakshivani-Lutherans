import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../domain/auth_state.dart';

/// Free (no SMS cost) alternative to phone sign-in: a 6-digit code emailed
/// via the `cloudflare/email-otp-worker` deployment. Two steps, same shape
/// as `PhoneAuthScreen` — enter the address, then the code.
class EmailCodeAuthScreen extends ConsumerStatefulWidget {
  const EmailCodeAuthScreen({super.key});

  @override
  ConsumerState<EmailCodeAuthScreen> createState() => _EmailCodeAuthScreenState();
}

class _EmailCodeAuthScreenState extends ConsumerState<EmailCodeAuthScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _code = TextEditingController();
  bool _codeSent = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final String email = _email.text.trim();
    if (email.isEmpty) {
      return;
    }
    final bool ok = await ref.read(authControllerProvider.notifier).sendEmailCode(email);
    if (!mounted) {
      return;
    }
    if (ok) {
      setState(() => _codeSent = true);
    }
  }

  Future<void> _confirmCode() async {
    final String email = _email.text.trim();
    final String code = _code.text.trim();
    if (email.isEmpty || code.isEmpty) {
      return;
    }
    await ref.read(authControllerProvider.notifier).confirmEmailCode(email: email, code: code);
    if (!mounted) {
      return;
    }
    final AuthState state = ref.read(authControllerProvider);
    if (state.isAuthenticated) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthState state = ref.watch(authControllerProvider);
    final bool loading = state.status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in with Email Code')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              _codeSent ? 'Enter the code' : 'Enter your email',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _codeSent
                  ? 'We emailed a code to ${_email.text.trim()}.'
                  : 'We\'ll email you a 6-digit code — no password needed.',
            ),
            const SizedBox(height: 14),
            if (!_codeSent) ...<Widget>[
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                enabled: !loading,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: loading ? null : _sendCode,
                child: const Text('Send code'),
              ),
            ] else ...<Widget>[
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                enabled: !loading,
                decoration: const InputDecoration(
                  labelText: '6-digit code',
                  prefixIcon: Icon(Icons.mark_email_read_outlined),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: loading ? null : _confirmCode,
                child: const Text('Verify'),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: loading ? null : () => setState(() => _codeSent = false),
                child: const Text('Use a different email'),
              ),
            ],
            if (state.errorMessage != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                state.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (loading)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
