import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../domain/auth_state.dart';

/// Two-step phone sign-in: enter a number, then the SMS code. On some
/// Android devices Firebase auto-verifies without any code step at all
/// (SMS Retriever) — [_verificationId] simply never gets set in that case,
/// and the router's own auth-state redirect takes the user to '/' anyway.
class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _code = TextEditingController();
  String? _verificationId;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final String phone = _phone.text.trim();
    if (phone.isEmpty) {
      return;
    }
    final String? id = await ref.read(authControllerProvider.notifier).sendPhoneCode(phone);
    if (!mounted) {
      return;
    }
    if (id != null) {
      setState(() => _verificationId = id);
    } else {
      _leaveIfSignedIn();
    }
  }

  Future<void> _confirmCode() async {
    final String id = _verificationId ?? '';
    final String code = _code.text.trim();
    if (id.isEmpty || code.isEmpty) {
      return;
    }
    await ref
        .read(authControllerProvider.notifier)
        .confirmPhoneCode(verificationId: id, smsCode: code);
    _leaveIfSignedIn();
  }

  void _leaveIfSignedIn() {
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
    final bool codeSent = _verificationId != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in with Phone')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              codeSent ? 'Enter the code' : 'Enter your phone number',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              codeSent
                  ? 'We texted a code to ${_phone.text.trim()}.'
                  : 'Include the country code, e.g. +91 98765 43210.',
            ),
            const SizedBox(height: 14),
            if (!codeSent) ...<Widget>[
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                enabled: !loading,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '+91 98765 43210',
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
                  prefixIcon: Icon(Icons.sms_outlined),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: loading ? null : _confirmCode,
                child: const Text('Verify'),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: loading ? null : () => setState(() => _verificationId = null),
                child: const Text('Use a different number'),
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
