import 'package:flutter/material.dart';

class SecurityPasswordScreen extends StatefulWidget {
  const SecurityPasswordScreen({super.key});

  @override
  State<SecurityPasswordScreen> createState() => _SecurityPasswordScreenState();
}

enum VerificationMode { password, otp, passkey }

class _SecurityPasswordScreenState extends State<SecurityPasswordScreen> {
  bool _isVerified = false;
  VerificationMode _activeMode = VerificationMode.password;

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passkeyController = TextEditingController();
  
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  void _handleVerification() {
    bool success = false;
    String error = 'Verification failed';

    switch (_activeMode) {
      case VerificationMode.password:
        if (_currentPasswordController.text == 'password123') success = true;
        error = 'Incorrect password. Try "password123"';
        break;
      case VerificationMode.otp:
        if (_otpController.text == '123456') success = true;
        error = 'Invalid OTP. Try "123456"';
        break;
      case VerificationMode.passkey:
        if (_passkeyController.text.length > 10) success = true;
        error = 'Invalid passkey. Key must be at least 10 characters.';
        break;
    }

    if (success) {
      setState(() => _isVerified = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _updatePassword() {
    if (_newPasswordController.text == _confirmPasswordController.text && _newPasswordController.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Color(0xFF10B981)),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Security & Password', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _isVerified ? _buildSecuritySettings() : _buildVerificationStep(),
      ),
    );
  }

  Widget _buildVerificationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_moon_rounded, size: 64, color: Color(0xFF3B82F6)),
          const SizedBox(height: 24),
          const Text('Identity Verification', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          const Text('Choose a method to verify your identity before accessing security settings.', 
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5)),
          const SizedBox(height: 32),

          // Verification Mode Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _modeChip('Password', VerificationMode.password, Icons.password_rounded),
                const SizedBox(width: 8),
                _modeChip('Email OTP', VerificationMode.otp, Icons.mark_email_read_rounded),
                const SizedBox(width: 8),
                _modeChip('Passkey', VerificationMode.passkey, Icons.vpn_key_rounded),
              ],
            ),
          ),
          const SizedBox(height: 40),

          if (_activeMode == VerificationMode.password) ...[
            _inputLabel('Current Password'),
            _textField(_currentPasswordController, 'Enter password', obscure: !_showCurrentPassword, 
              suffix: IconButton(
                icon: Icon(_showCurrentPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20, color: const Color(0xFF94A3B8)),
                onPressed: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
              )
            ),
          ] else if (_activeMode == VerificationMode.otp) ...[
             _inputLabel('Email OTP (sent to arjun.mehta@college.edu)'),
             _textField(_otpController, 'Enter 6-digit code', keyboardType: TextInputType.number),
             const SizedBox(height: 8),
             TextButton(onPressed: () {}, child: const Text('Resend OTP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
          ] else ...[
            _inputLabel('Paste Passkey'),
            _textField(_passkeyController, 'Paste your security passkey here', maxLines: 3),
          ],

          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _handleVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('CONTINUE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(String label, VerificationMode mode, IconData icon) {
    final isSelected = _activeMode == mode;
    return InkWell(
      onTap: () => setState(() => _activeMode = mode),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isSelected ? Colors.white : const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profile Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1)),
          const SizedBox(height: 24),
          _inputLabel('New Password'),
          _textField(_newPasswordController, 'Create a strong password', obscure: !_showNewPassword, 
            suffix: IconButton(
              icon: Icon(_showNewPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20, color: const Color(0xFF94A3B8)),
              onPressed: () => setState(() => _showNewPassword = !_showNewPassword),
            )
          ),
          const SizedBox(height: 24),
          _inputLabel('Confirm New Password'),
          _textField(_confirmPasswordController, 'Repeat new password', obscure: !_showConfirmPassword,
             suffix: IconButton(
              icon: Icon(_showConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20, color: const Color(0xFF94A3B8)),
              onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
            )
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _updatePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
          const SizedBox(height: 32),
          const Center(
            child: Text(
              'Your password must be at least 8 characters long and include a mix of letters, numbers, and symbols.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
    );
  }

  Widget _textField(TextEditingController controller, String hint, {bool obscure = false, Widget? suffix, int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
        suffixIcon: suffix,
      ),
    );
  }
}
