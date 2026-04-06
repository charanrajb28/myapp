import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/mail_config.dart';

enum VerificationMode { password, otp }

class SecurityPasswordScreen extends StatefulWidget {
  const SecurityPasswordScreen({super.key});

  @override
  State<SecurityPasswordScreen> createState() => _SecurityPasswordScreenState();
}

class _SecurityPasswordScreenState extends State<SecurityPasswordScreen> {
  final _supabase = Supabase.instance.client;
  final _currentPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = true;
  bool _isVerified = false;
  bool _isVerifying = false;
  bool _isUpdating = false;
  bool _isSendingOtp = false;
  bool _otpSent = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  VerificationMode _activeMode = VerificationMode.password;
  User? _user;
  String _email = 'Not available';
  String _createdAt = 'Not available';
  String _lastSignInAt = 'Not available';

  @override
  void initState() {
    super.initState();
    _loadAccountState();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadAccountState() async {
    final user = _supabase.auth.currentUser;
    if (!mounted) return;

    setState(() {
      _user = user;
      _email = user?.email ?? 'Not available';
      _createdAt = _formatDateTime(user?.createdAt);
      _lastSignInAt = _formatDateTime(user?.lastSignInAt);
      _isLoading = false;
    });
  }

  Future<void> _handleVerification() async {
    if (_activeMode == VerificationMode.password) {
      await _verifyCurrentPassword();
      return;
    }
    await _verifyOtp();
  }

  Future<void> _verifyCurrentPassword() async {
    final user = _user;
    final password = _currentPasswordController.text.trim();

    if (user == null || (user.email ?? '').isEmpty) {
      _showMessage('Unable to find the logged-in user.', isError: true);
      return;
    }
    if (password.isEmpty) {
      _showMessage('Enter your current password to continue.', isError: true);
      return;
    }

    setState(() => _isVerifying = true);
    try {
      await _supabase.auth.signInWithPassword(
        email: user.email!,
        password: password,
      );

      if (!mounted) return;
      setState(() {
        _isVerified = true;
        _isVerifying = false;
      });
      _showMessage('Identity verified successfully.');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      _showMessage(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      _showMessage('Unable to verify password: $e', isError: true);
    }
  }

  Future<void> _sendOtp() async {
    final user = _user;
    final email = user?.email?.trim() ?? '';
    if (email.isEmpty) {
      _showMessage('Signed-in email is not available.', isError: true);
      return;
    }

    setState(() => _isSendingOtp = true);
    try {
      final otp = _generateOtp();
      await _supabase.rpc(
        'create_password_reset_otp',
        params: {
          'p_email': email,
          'p_otp': otp,
        },
      );
      await _sendOtpMail(email: email, otp: otp);

      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _isSendingOtp = false;
      });
      _showMessage('OTP sent to $email');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSendingOtp = false);
      _showMessage('Unable to send OTP: $e', isError: true);
    }
  }

  Future<void> _verifyOtp() async {
    final email = _user?.email?.trim() ?? '';
    final otp = _otpController.text.trim();

    if (email.isEmpty) {
      _showMessage('Signed-in email is not available.', isError: true);
      return;
    }
    if (!_otpSent) {
      _showMessage('Send the OTP first.', isError: true);
      return;
    }
    if (otp.isEmpty) {
      _showMessage('Enter the OTP sent to your email.', isError: true);
      return;
    }

    setState(() => _isVerifying = true);
    try {
      await _supabase.rpc(
        'verify_password_reset_otp',
        params: {
          'p_email': email,
          'p_otp': otp,
        },
      );

      if (!mounted) return;
      setState(() {
        _isVerified = true;
        _isVerifying = false;
      });
      _showMessage('Email OTP verified successfully.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      _showMessage('Unable to verify OTP: $e', isError: true);
    }
  }

  Future<void> _updatePassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showMessage('Enter and confirm your new password.', isError: true);
      return;
    }
    if (newPassword.length < 8) {
      _showMessage(
        'Your password must be at least 8 characters long.',
        isError: true,
      );
      return;
    }
    if (newPassword != confirmPassword) {
      _showMessage('Passwords do not match.', isError: true);
      return;
    }

    setState(() => _isUpdating = true);
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      if (!mounted) return;
      setState(() => _isUpdating = false);
      _showMessage('Password updated successfully.');
      Navigator.pop(context);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isUpdating = false);
      _showMessage(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdating = false);
      _showMessage('Unable to update password: $e', isError: true);
    }
  }

  Future<void> _sendOtpMail({
    required String email,
    required String otp,
  }) async {
    final smtpServer =
        gmail(MailConfig.senderEmail, MailConfig.senderAppPassword);

    final message = Message()
      ..from = Address(MailConfig.senderEmail, MailConfig.senderName)
      ..recipients.add(email)
      ..subject = 'ScholarBridge Security Verification OTP'
      ..html = """
        <div style='font-family: Arial, sans-serif; padding: 24px; color: #0F172A;'>
          <h2 style='margin: 0 0 12px;'>Security Verification</h2>
          <p style='margin: 0 0 16px; color: #475569;'>
            Use the OTP below to verify your identity before changing your password.
          </p>
          <div style='font-size: 28px; font-weight: 700; letter-spacing: 6px; background: #EEF2FF; color: #4338CA; padding: 18px 20px; border-radius: 12px; display: inline-block;'>
            $otp
          </div>
          <p style='margin: 20px 0 0; color: #64748B;'>
            This OTP expires in 10 minutes. If you did not request this, you can ignore this email.
          </p>
        </div>
      """;

    await send(message, smtpServer);
  }

  String _generateOtp() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF10B981),
      ),
    );
  }

  String _formatDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return 'Not available';
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }
    return DateFormat('dd MMM yyyy, hh:mm a').format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Security & Password',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _isVerified
                  ? _buildPasswordUpdateStep()
                  : _buildVerificationStep(),
            ),
    );
  }

  Widget _buildVerificationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _accountCard(),
          const SizedBox(height: 24),
          const Text(
            'Verify Identity',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose how you want to verify before unlocking password settings.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _modeChip(
                  label: 'Password',
                  mode: VerificationMode.password,
                  icon: Icons.password_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _modeChip(
                  label: 'Email OTP',
                  mode: VerificationMode.otp,
                  icon: Icons.mark_email_read_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_activeMode == VerificationMode.password) ...[
            _inputLabel('Signed-in Email'),
            _readonlyField(_email),
            const SizedBox(height: 20),
            _inputLabel('Current Password'),
            _textField(
              _currentPasswordController,
              'Enter your current password',
              obscure: !_showCurrentPassword,
              suffix: IconButton(
                icon: Icon(
                  _showCurrentPassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 20,
                  color: const Color(0xFF94A3B8),
                ),
                onPressed: () {
                  setState(() => _showCurrentPassword = !_showCurrentPassword);
                },
              ),
            ),
          ] else ...[
            _inputLabel('Signed-in Email'),
            _readonlyField(_email),
            const SizedBox(height: 20),
            _inputLabel('Email OTP'),
            _textField(
              _otpController,
              'Enter the 6-digit OTP',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isSendingOtp ? null : _sendOtp,
                icon: _isSendingOtp
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(_otpSent ? 'Resend OTP' : 'Send OTP'),
              ),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (_isVerifying || _isSendingOtp) ? null : _handleVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _isVerifying ? 'VERIFYING...' : 'CONTINUE',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordUpdateStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _accountCard(),
          const SizedBox(height: 24),
          const Text(
            'Update Password',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your new password will be applied to the current logged-in account immediately.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _inputLabel('New Password'),
          _textField(
            _newPasswordController,
            'Create a strong password',
            obscure: !_showNewPassword,
            suffix: IconButton(
              icon: Icon(
                _showNewPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 20,
                color: const Color(0xFF94A3B8),
              ),
              onPressed: () {
                setState(() => _showNewPassword = !_showNewPassword);
              },
            ),
          ),
          const SizedBox(height: 20),
          _inputLabel('Confirm New Password'),
          _textField(
            _confirmPasswordController,
            'Repeat your new password',
            obscure: !_showConfirmPassword,
            suffix: IconButton(
              icon: Icon(
                _showConfirmPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 20,
                color: const Color(0xFF94A3B8),
              ),
              onPressed: () {
                setState(() => _showConfirmPassword = !_showConfirmPassword);
              },
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isUpdating ? null : _updatePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _isUpdating ? 'SAVING...' : 'SAVE CHANGES',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Use at least 8 characters and prefer a mix of uppercase, lowercase, numbers, and symbols.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF1D4ED8),
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                'Account Security',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _detailRow('Email', _email),
          const SizedBox(height: 12),
          _detailRow('Account Created', _createdAt),
          const SizedBox(height: 12),
          _detailRow('Last Sign In', _lastSignInAt),
        ],
      ),
    );
  }

  Widget _modeChip({
    required String label,
    required VerificationMode mode,
    required IconData icon,
  }) {
    final isSelected = _activeMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _activeMode = mode;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F172A)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _inputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _readonlyField(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String hint, {
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
        suffixIcon: suffix,
      ),
    );
  }
}
