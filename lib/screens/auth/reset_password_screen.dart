import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatefulWidget {
  final Uri actionUri;

  const ResetPasswordScreen({super.key, required this.actionUri});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = true;
  bool _saving = false;
  String? _email;
  String? _oobCode;
  String? _error;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _prepareAction();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _prepareAction() async {
    final params = widget.actionUri.queryParameters;
    final mode = params['mode'];
    final code = params['oobCode'];

    if (mode != 'resetPassword' || code == null || code.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'This password reset link is invalid or incomplete.';
        });
      }
      return;
    }

    try {
      final email = await FirebaseAuth.instance.verifyPasswordResetCode(code);
      if (!mounted) return;
      setState(() {
        _oobCode = code;
        _email = email;
        _loading = false;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _actionError(e.code);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to verify this password reset link.';
      });
    }
  }

  Future<void> _savePassword() async {
    final password = _passwordController.text;
    final confirmation = _confirmController.text;

    if (password.length < 6) {
      setState(() => _error = 'Use a password with at least 6 characters.');
      return;
    }
    if (password != confirmation) {
      setState(() => _error = 'The passwords do not match.');
      return;
    }
    final code = _oobCode;
    if (code == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.confirmPasswordReset(
        code: code,
        newPassword: password,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _completed = true;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _actionError(e.code);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Unable to update your password. Please try again.';
      });
    }
  }

  String _actionError(String code) {
    switch (code) {
      case 'expired-action-code':
      case 'invalid-action-code':
        return 'This password reset link has expired or was already used.';
      case 'user-disabled':
        return 'This account is currently disabled.';
      case 'weak-password':
        return 'Choose a stronger password.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      default:
        return 'This password reset link could not be verified.';
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _buildCard(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: CircularProgressIndicator()),
            )
          : _completed
              ? _successContent()
              : _error != null && _oobCode == null
                  ? _invalidContent()
                  : _formContent(),
    );
  }

  Widget _heading({required IconData icon, required Color color, required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 20),
        Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _formContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          icon: Icons.lock_reset_rounded,
          color: const Color(0xFF6366F1),
          title: 'Create a new password',
          subtitle: _email == null ? 'Choose a secure password for your account.' : 'Resetting the password for $_email.',
        ),
        const SizedBox(height: 28),
        if (_error != null) _errorBanner(),
        _passwordField(
          controller: _passwordController,
          label: 'New password',
          obscure: _obscurePassword,
          onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        const SizedBox(height: 16),
        _passwordField(
          controller: _confirmController,
          label: 'Confirm password',
          obscure: _obscureConfirm,
          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _saving ? null : _savePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _saving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Update password', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _passwordField({required TextEditingController controller, required String label, required bool obscure, required VoidCallback onToggle}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFECACA))),
      child: Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13, height: 1.35)),
    );
  }

  Widget _successContent() {
    return Column(
      children: [
        _heading(icon: Icons.check_circle_rounded, color: const Color(0xFF10B981), title: 'Password updated', subtitle: 'Your password has been changed successfully. You can now sign in with your new password.'),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: _goToLogin, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Go to sign in', style: TextStyle(fontWeight: FontWeight.w800)))),
      ],
    );
  }

  Widget _invalidContent() {
    return Column(
      children: [
        _heading(icon: Icons.link_off_rounded, color: const Color(0xFFEF4444), title: 'Link unavailable', subtitle: _error ?? 'This password reset link is invalid or has expired.'),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: _goToLogin, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Return to sign in', style: TextStyle(fontWeight: FontWeight.w800)))),
      ],
    );
  }
}
