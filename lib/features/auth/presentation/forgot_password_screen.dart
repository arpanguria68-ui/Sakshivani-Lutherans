import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final TextEditingController _email = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text('Reset password', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              'Enter your email address. If an account exists, a reset link will be sent.',
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
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _send,
              icon: const Icon(Icons.send),
              label: const Text('Send reset link'),
            ),
            if (_submitted)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'If this email exists, password reset instructions have been sent.',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    final String email = _email.text.trim();
    if (email.isEmpty) {
      return;
    }
    await ref.read(authControllerProvider.notifier).sendPasswordReset(email);
    if (!mounted) {
      return;
    }
    setState(() {
      _submitted = true;
    });
  }
}
