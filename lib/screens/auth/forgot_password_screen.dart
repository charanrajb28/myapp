import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/mail_config.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _codeSent = false;
  bool _isSubmitting = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Enter your registered email first.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final otp = _generateOtp();

      await Supabase.instance.client.rpc(
        'create_password_reset_otp',
        params: {
          'p_email': email,
          'p_otp': otp,
        },
      );

      await _sendOtpMail(email: email, otp: otp);

      if (!mounted) return;
      setState(() => _codeSent = true);
      _showSuccess('OTP sent to $email');
    } catch (e) {
      if (!mounted) return;
      _showError('Unable to send OTP: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final password = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || code.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError('Fill in all fields to continue.');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match.');
      return;
    }

    if (password.length < 8) {
      _showError('Password must be at least 8 characters long.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await Supabase.instance.client.rpc(
        'complete_password_reset',
        params: {
          'p_email': email,
          'p_otp': code,
          'p_new_password': password,
        },
      );

      if (!mounted) return;
      _showSuccess('Password updated successfully. Please sign in again.');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showError('Unable to reset password: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
      ..subject = 'ScholarBridge Password Reset OTP'
      ..html = """
        <div style='font-family: Arial, sans-serif; padding: 24px; color: #0F172A;'>
          <h2 style='margin: 0 0 12px;'>Password Reset Verification</h2>
          <p style='margin: 0 0 16px; color: #475569;'>
            Use the OTP below to reset your ScholarBridge account password.
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F172A);
    const accentColor = Color(0xFF6366F1);
    const textSecondary = Color(0xFF64748B);
    const borderColor = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.mark_email_read_rounded,
                      size: 34,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Forgot Password',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _codeSent
                        ? 'Enter the OTP from your email and choose a new password.'
                        : 'We will send a 6-digit OTP to your registered email using your configured Gmail sender.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Email Address'),
                        const SizedBox(height: 10),
                        _field(
                          controller: _emailController,
                          hintText: 'Enter your registered email',
                          prefixIcon: Icons.alternate_email_rounded,
                          enabled: !_codeSent && !_isSubmitting,
                        ),
                        const SizedBox(height: 24),
                        if (_codeSent) ...[
                          _label('OTP Code'),
                          const SizedBox(height: 10),
                          _field(
                            controller: _codeController,
                            hintText: 'Enter the 6-digit OTP',
                            prefixIcon: Icons.verified_user_rounded,
                            keyboardType: TextInputType.number,
                            enabled: !_isSubmitting,
                          ),
                          const SizedBox(height: 24),
                          _label('New Password'),
                          const SizedBox(height: 10),
                          _field(
                            controller: _newPasswordController,
                            hintText: 'Create a new password',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: !_showNewPassword,
                            enabled: !_isSubmitting,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showNewPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: textSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showNewPassword = !_showNewPassword;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          _label('Confirm Password'),
                          const SizedBox(height: 10),
                          _field(
                            controller: _confirmPasswordController,
                            hintText: 'Repeat your new password',
                            prefixIcon: Icons.lock_reset_rounded,
                            obscureText: !_showConfirmPassword,
                            enabled: !_isSubmitting,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: textSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showConfirmPassword = !_showConfirmPassword;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isSubmitting ? null : _sendVerificationCode,
                              child: const Text(
                                'Resend OTP',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSubmitting
                                ? null
                                : (_codeSent ? _resetPassword : _sendVerificationCode),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _codeSent
                                        ? 'Verify OTP & Reset Password'
                                        : 'Send OTP',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    bool enabled = true,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF64748B), size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0F172A), width: 2),
        ),
      ),
    );
  }
}
