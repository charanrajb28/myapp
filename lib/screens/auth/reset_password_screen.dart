import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String oobCode;

  const ResetPasswordScreen({super.key, required this.oobCode});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _checkingLink = true;
  bool _saving = false;
  bool _validLink = false;
  bool _completed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _verifyLink();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _verifyLink() async {
    try {
      await FirebaseAuth.instance.verifyPasswordResetCode(widget.oobCode);
      if (mounted) {
        setState(() {
          _checkingLink = false;
          _validLink = true;
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _checkingLink = false;
          _error = _messageForCode(e.code);
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    final confirmation = _confirmController.text;

    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters long.');
      return;
    }
    if (password != confirmation) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.confirmPasswordReset(
        code: widget.oobCode,
        newPassword: password,
      );
      if (mounted) setState(() => _completed = true);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _messageForCode(e.code));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _messageForCode(String code) {
    switch (code) {
      case 'expired-action-code':
        return 'This password reset link has expired. Request a new one.';
      case 'invalid-action-code':
        return 'This password reset link is invalid or has already been used.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      default:
        return 'This password reset link cannot be used. Please request a new one.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Card(
            margin: const EdgeInsets.all(24),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: _checkingLink
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Checking reset link...'),
                      ],
                    )
                  : _completed
                      ? _successContent(context)
                      : !_validLink
                          ? _errorContent(context)
                          : _formContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_reset_rounded, size: 46, color: Color(0xFF2563EB)),
        const SizedBox(height: 18),
        const Text('Create a new password', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('Choose a new password for your ScholarBridge account.'),
        const SizedBox(height: 24),
        _passwordField('New password', _passwordController),
        const SizedBox(height: 14),
        _passwordField('Confirm password', _confirmController),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _saving ? null : _resetPassword,
            child: _saving ? const CircularProgressIndicator() : const Text('Update password'),
          ),
        ),
      ],
    );
  }

  Widget _passwordField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _errorContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.link_off_rounded, size: 54, color: Colors.red),
        const SizedBox(height: 16),
        Text(_error ?? 'Invalid reset link', textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: () => Navigator.pushReplacementNamed(context, '/forgot-password'), child: const Text('Request new link')),
      ],
    );
  }

  Widget _successContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded, size: 54, color: Colors.green),
        const SizedBox(height: 16),
        const Text('Password updated successfully.', textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'), child: const Text('Go to login')),
      ],
    );
  }
}
