// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'semester_promotion_screen.dart';

class MoreOptionsScreen extends StatefulWidget {
  const MoreOptionsScreen({super.key});
  @override
  State<MoreOptionsScreen> createState() => _MoreOptionsScreenState();
}

class _MoreOptionsScreenState extends State<MoreOptionsScreen> {
  final String _academicYear = '2024 – 2025';
  bool _notificationsEnabled = true;
  bool _autoRemindersEnabled = true;
  bool _reportLockEnabled = false;

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Export Data',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A))),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _ExportOption(icon: Icons.people_alt_rounded,   color: const Color(0xFF3B82F6), label: 'Student Records'),
          _ExportOption(icon: Icons.domain_rounded,        color: const Color(0xFF8B5CF6), label: 'Company & Roles'),
          _ExportOption(icon: Icons.work_rounded,          color: const Color(0xFF10B981), label: 'Internship Reports'),
          _ExportOption(icon: Icons.warning_amber_rounded, color: const Color(0xFFEF4444), label: 'Alert Logs'),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF64748B))),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Admin Control Center',
            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [

          // ── Admin identity card ──
          _adminCard(),
          const SizedBox(height: 28),

          // ── Academic Configuration ──
          const _SectionHeader(label: 'Academic Configuration', icon: Icons.school_rounded, color: Color(0xFF6366F1)),
          const SizedBox(height: 12),

          _ActionTile(
            icon: Icons.swap_vert_circle_rounded,
            color: const Color(0xFF6366F1),
            title: 'Semester Promotion',
            subtitle: 'View all semesters & advance students to the next',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SemesterPromotionScreen()),
            ),
          ),

          const SizedBox(height: 28),

          // ── Notifications & Automation ──
          const _SectionHeader(label: 'Notifications & Automation', icon: Icons.tune_rounded, color: Color(0xFF10B981)),
          const SizedBox(height: 12),

          _ToggleTile(
            icon: Icons.notifications_rounded,
            color: const Color(0xFF10B981),
            title: 'Push Notifications',
            subtitle: 'Alerts for new applications & status changes',
            value: _notificationsEnabled,
            onChanged: (v) {
              setState(() => _notificationsEnabled = v);
              _showSuccessSnack(v ? 'Notifications enabled' : 'Notifications disabled');
            },
          ),
          const SizedBox(height: 10),
          _ToggleTile(
            icon: Icons.alarm_rounded,
            color: const Color(0xFFF59E0B),
            title: 'Auto Reminders',
            subtitle: 'Send weekly report submission reminders',
            value: _autoRemindersEnabled,
            onChanged: (v) {
              setState(() => _autoRemindersEnabled = v);
              _showSuccessSnack(v ? 'Auto-reminders activated' : 'Auto-reminders turned off');
            },
          ),
          const SizedBox(height: 10),
          _ToggleTile(
            icon: Icons.lock_clock_rounded,
            color: const Color(0xFFEF4444),
            title: 'Report Submission Lock',
            subtitle: 'Block late report entries after due date',
            value: _reportLockEnabled,
            onChanged: (v) {
              setState(() => _reportLockEnabled = v);
              _showSuccessSnack(v ? 'Late submissions blocked' : 'Late submissions allowed');
            },
          ),

          const SizedBox(height: 28),

          // ── Data & System Tools ──
          const _SectionHeader(label: 'Data & System Tools', icon: Icons.build_rounded, color: Color(0xFF3B82F6)),
          const SizedBox(height: 12),

          _ActionTile(
            icon: Icons.download_rounded,
            color: const Color(0xFF3B82F6),
            title: 'Export Data',
            subtitle: 'Download records as CSV / Excel',
            onTap: _showExportDialog,
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.backup_rounded,
            color: const Color(0xFF0EA5E9),
            title: 'Backup System Data',
            subtitle: 'Create a full backup of current records',
            onTap: () => _showSuccessSnack("Backup initiated — you'll be notified when done"),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.cleaning_services_rounded,
            color: const Color(0xFF64748B),
            title: 'Clear Cache',
            subtitle: 'Free up temporary app storage',
            onTap: () => _showSuccessSnack('Cache cleared successfully'),
          ),

          const SizedBox(height: 28),

          // ── Account ──
          const _SectionHeader(label: 'Account', icon: Icons.person_rounded, color: Color(0xFF0F172A)),
          const SizedBox(height: 12),

          _ActionTile(
            icon: Icons.manage_accounts_rounded,
            color: const Color(0xFF475569),
            title: 'Account Settings',
            subtitle: 'Edit admin profile and preferences',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.shield_rounded,
            color: const Color(0xFF475569),
            title: 'Security Overview',
            subtitle: 'Password reset and active sessions',
            onTap: () {},
          ),

          const SizedBox(height: 28),

          // ── Logout ──
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
              ),
              title: const Text('Logout',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFDC2626), fontSize: 15)),
              subtitle: const Text('Return to the sign-in screen',
                  style: TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
              trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFEF4444)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onTap: () => Navigator.of(context).pushNamed('/logout'),
            ),
          ),

          const SizedBox(height: 40),
          Center(
            child: Text('Admin Control Center  ·  v1.0.0',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _adminCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('College Admin',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
            Text('admin@college.edu',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Super Admin',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ]),
        const SizedBox(height: 18),
        Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
        const SizedBox(height: 14),
        Row(children: [
          _statPill(Icons.calendar_month_rounded, _academicYear),
          const SizedBox(width: 10),
          _statPill(Icons.swap_vert_circle_rounded, 'Tap to manage semesters'),
        ]),
      ]),
    );
  }

  Widget _statPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.6)),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SectionHeader({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15, color: color),
    const SizedBox(width: 7),
    Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
  ]);
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.color, required this.title,
    required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          hoverColor: color.withValues(alpha: 0.03),
          splashColor: color.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ])),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({required this.icon, required this.color, required this.title,
    required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (value ? color : const Color(0xFF94A3B8)).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: value ? color : const Color(0xFF94A3B8), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ])),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: color,
        ),
      ]),
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _ExportOption({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Export', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
