import 'package:flutter/material.dart';

class MoreOptionsScreen extends StatelessWidget {
  const MoreOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Admin Settings',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            )),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        children: [
          _buildSectionHeader('System Management'),
          const SizedBox(height: 12),
          _buildSettingsTile(icon: Icons.assignment_turned_in_outlined, title: 'Manage Consent Letters'),
          _buildSettingsTile(icon: Icons.workspace_premium_outlined, title: 'Certificate Templates'),
          _buildSettingsTile(icon: Icons.history_edu_outlined, title: 'Academic Terms Config'),
          
          const SizedBox(height: 32),
          _buildSectionHeader('Account & Security'),
          const SizedBox(height: 12),
          _buildSettingsTile(icon: Icons.manage_accounts_outlined, title: 'Admin Account Settings'),
          _buildSettingsTile(icon: Icons.shield_outlined, title: 'Security Overview'),
          
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: TextButton.icon(
              onPressed: () {
                // Return to login screen
                Navigator.of(context).pushReplacementNamed('/');
              },
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
              label: const Text('Logout from Admin Portal', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingsTile({required IconData icon, required String title}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0F172A)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A), fontSize: 15)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {},
      ),
    );
  }
}
