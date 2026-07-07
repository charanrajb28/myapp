// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'dart:io' as io;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_selector/file_selector.dart';
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

  String _userRole = 'admin';
  String _userName = 'System Admin';
  String _userEmail = 'admin@college.edu';
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminProfile();
  }

  Future<void> _fetchAdminProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final res = await supabase
            .from('users')
            .select('role, name, email')
            .eq('id', user.id)
            .single();
        setState(() {
          _userRole = res['role']?.toString() ?? 'admin';
          _userName = res['name']?.toString() ?? 'System Admin';
          _userEmail = res['email']?.toString() ?? user.email ?? 'admin@college.edu';
          _loadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching admin profile: $e');
      setState(() => _loadingProfile = false);
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Export Data',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A))),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _ExportOption(
            icon: Icons.people_alt_rounded, color: const Color(0xFF3B82F6), label: 'Student Records',
            onExport: () { Navigator.pop(ctx); _exportCSV('students'); },
          ),
          _ExportOption(
            icon: Icons.domain_rounded, color: const Color(0xFF8B5CF6), label: 'Company & Roles',
            onExport: () { Navigator.pop(ctx); _exportCSV('companies'); },
          ),
          _ExportOption(
            icon: Icons.work_rounded, color: const Color(0xFF10B981), label: 'Internship Reports',
            onExport: () { Navigator.pop(ctx); _exportCSV('internships'); },
          ),
          _ExportOption(
            icon: Icons.warning_amber_rounded, color: const Color(0xFFEF4444), label: 'Alert Logs',
            onExport: () { Navigator.pop(ctx); _exportCSV('alerts'); },
          ),
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

  void _showSubAdminsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SubAdminsManagementDialog(
        onSuccess: (msg) => _showSuccessSnack(msg),
      ),
    );
  }

  Future<void> _exportCSV(String type) async {
    try {
      _showSuccessSnack('Fetching data for export...');
      final client = Supabase.instance.client;
      final StringBuffer sb = StringBuffer();
      String fileName = '';

      if (type == 'students') {
        fileName = 'student_records_${DateTime.now().millisecondsSinceEpoch}.csv';
        final data = await client.from('students').select('*');
        sb.writeln('Enrollment ID,Name,College,Department,Semester,Email,Phone,Parent Contact,Parent Email,GPA,Graduation Year,Blacklisted');
        for (final row in data) {
          final email = row['contact_email']?.toString() ?? '';
          sb.writeln('"${row['enrollment_id'] ?? ''}","${row['name'] ?? ''}","${row['college'] ?? ''}","${row['department'] ?? ''}","${row['semester'] ?? ''}","$email","${row['phone_number'] ?? ''}","${row['parent_contact'] ?? ''}","${row['parent_email'] ?? ''}","${row['gpa'] ?? ''}","${row['graduation_year'] ?? ''}","${row['is_blacklisted'] == true ? 'Yes' : 'No'}"');
        }
      } else if (type == 'companies') {
        fileName = 'company_records_${DateTime.now().millisecondsSinceEpoch}.csv';
        final data = await client.from('companies').select('*');
        sb.writeln('Name,Industry,Location,Website,Contact Email,Phone,Partner Since,Blacklisted');
        for (final row in data) {
          final email = row['contact_email']?.toString() ?? '';
          sb.writeln('"${row['name'] ?? ''}","${row['industry'] ?? ''}","${row['location'] ?? ''}","${row['website'] ?? ''}","$email","${row['phone'] ?? ''}","${row['partner_since'] ?? ''}","${row['is_blacklisted'] == true ? 'Yes' : 'No'}"');
        }
      } else if (type == 'internships') {
        fileName = 'internship_reports_${DateTime.now().millisecondsSinceEpoch}.csv';
        final data = await client.from('applications').select('*, students(name, enrollment_id), internships(role, start_date, end_date, companies(name))');
        sb.writeln('Student Name,Enrollment ID,Company,Role,Status,Progress %,Start Date,End Date,Mentor Name');
        for (final row in data) {
          final student = row['students'] as Map? ?? {};
          final internship = row['internships'] as Map? ?? {};
          final company = internship['companies'] as Map? ?? {};
          final progressPercent = (((row['progress'] as num?) ?? 0) * 100).round();
          sb.writeln('"${student['name'] ?? ''}","${student['enrollment_id'] ?? ''}","${company['name'] ?? ''}","${internship['role'] ?? ''}","${row['status'] ?? ''}","$progressPercent","${internship['start_date'] ?? ''}","${internship['end_date'] ?? ''}","${row['mentor_name'] ?? ''}"');
        }
      } else if (type == 'alerts') {
        fileName = 'alert_logs_${DateTime.now().millisecondsSinceEpoch}.csv';
        final data = await client.from('applications').select('*, students(name, enrollment_id), internships(role, end_date, companies(name))').inFilter('status', ['Removed', 'Completed']).order('progress', ascending: true);
        sb.writeln('Alert Reason,Student Name,Enrollment ID,Company,Role,Status,Progress %,End Date');
        for (final row in data) {
          final student = row['students'] as Map? ?? {};
          final internship = row['internships'] as Map? ?? {};
          final company = internship['companies'] as Map? ?? {};
          final progressPercent = (((row['progress'] as num?) ?? 0) * 100).round();
          sb.writeln('"Low Progress Alert","${student['name'] ?? ''}","${student['enrollment_id'] ?? ''}","${company['name'] ?? ''}","${internship['role'] ?? ''}","${row['status'] ?? ''}","$progressPercent","${internship['end_date'] ?? ''}"');
        }
      }

      final FileSaveLocation? result = await getSaveLocation(
        suggestedName: fileName,
      );

      if (result == null) return;

      final file = io.File(result.path);
      await file.writeAsString(sb.toString(), encoding: utf8);
      _showSuccessSnack('Exported successfully to ${result.path}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to export: $e'),
        backgroundColor: Colors.redAccent,
      ));
    }
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
            icon: _userRole == 'sub_admin' ? Icons.lock_outline_rounded : Icons.swap_vert_circle_rounded,
            color: _userRole == 'sub_admin' ? Colors.grey : const Color(0xFF6366F1),
            title: 'Semester Promotion',
            subtitle: _userRole == 'sub_admin' ? 'Requires Super Admin privilege' : 'View all semesters & advance students to the next',
            onTap: _userRole == 'sub_admin'
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Access Denied: Semester Promotion is restricted to Super Admins.'),
                      backgroundColor: Colors.redAccent,
                    ));
                  }
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SemesterPromotionScreen()),
                    ),
          ),

          if (_userRole == 'admin') ...[
            const SizedBox(height: 28),
            const _SectionHeader(label: 'Access Management', icon: Icons.admin_panel_settings_rounded, color: Color(0xFF8B5CF6)),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.person_add_alt_1_rounded,
              color: const Color(0xFF8B5CF6),
              title: 'Manage Sub-Admins',
              subtitle: 'Create and view credentials for assistant admins',
              onTap: _showSubAdminsDialog,
            ),
          ],

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
            icon: _userRole == 'sub_admin' ? Icons.lock_outline_rounded : Icons.download_rounded,
            color: _userRole == 'sub_admin' ? Colors.grey : const Color(0xFF3B82F6),
            title: 'Export Data',
            subtitle: _userRole == 'sub_admin' ? 'Requires Super Admin privilege' : 'Download records as CSV / Excel',
            onTap: _userRole == 'sub_admin'
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Access Denied: Exporting data is restricted to Super Admins.'),
                      backgroundColor: Colors.redAccent,
                    ));
                  }
                : _showExportDialog,
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
    final isSubAdmin = _userRole == 'sub_admin';
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
            Text(_userName,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
            Text(_userEmail,
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSubAdmin ? const Color(0xFFF59E0B).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: isSubAdmin ? Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)) : null,
            ),
            child: Text(isSubAdmin ? 'Sub-Admin' : 'Super Admin',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isSubAdmin ? const Color(0xFFFBBF24) : Colors.white)),
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
  final VoidCallback onExport;
  const _ExportOption({required this.icon, required this.color, required this.label, required this.onExport});

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
        onPressed: onExport,
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

class SubAdminsManagementDialog extends StatefulWidget {
  final Function(String) onSuccess;
  
  // Shared static list for Dev/Guest mode coordinate mocking
  static final List<Map<String, dynamic>> mockAdmins = [
    {
      'name': 'System Admin',
      'email': 'admin@scholarbridge.com',
      'role': 'admin',
      'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
    },
    {
      'name': 'Jane Assistant',
      'email': 'jane@college.edu',
      'role': 'sub_admin',
      'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    },
    {
      'name': 'John Helper',
      'email': 'john.h@college.edu',
      'role': 'sub_admin',
      'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
    }
  ];

  const SubAdminsManagementDialog({required this.onSuccess, super.key});

  @override
  State<SubAdminsManagementDialog> createState() => _SubAdminsManagementDialogState();
}

class _SubAdminsManagementDialogState extends State<SubAdminsManagementDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  List<Map<String, dynamic>> _subAdmins = [];
  bool _loading = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _fetchSubAdmins();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubAdmins() async {
    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;
      if (supabase.auth.currentUser == null) {
        // Dev Mode Mocking: Read only the sub_admins from mockAdmins
        setState(() {
          _subAdmins = SubAdminsManagementDialog.mockAdmins
              .where((admin) => admin['role'] == 'sub_admin')
              .map((admin) => {
                    'id': admin['email'],
                    'user_id': admin['email'],
                    'created_at': admin['created_at'] ?? DateTime.now().toIso8601String(),
                    'users': {
                      'name': admin['name'],
                      'email': admin['email'],
                    }
                  })
              .toList();
          _loading = false;
        });
        return;
      }

      final res = await supabase
          .from('sub_admins')
          .select('*, users!sub_admins_user_id_fkey(name, email)')
          .order('created_at', ascending: false);
      
      final mappedRes = List<Map<String, dynamic>>.from(res).map((item) {
        final Map<String, dynamic> copy = Map.from(item);
        if (copy.containsKey('users!sub_admins_user_id_fkey')) {
          copy['users'] = copy['users!sub_admins_user_id_fkey'];
        }
        return copy;
      }).toList();

      setState(() {
        _subAdmins = mappedRes;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching sub admins: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _createSubAdmin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _creating = true);
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      
      if (currentUser == null) {
        // Dev/Guest Mode Mocking: Insert into shared static list
        final mockAdmin = {
          'name': name,
          'email': email,
          'role': 'sub_admin',
          'created_at': DateTime.now().toIso8601String(),
        };
        SubAdminsManagementDialog.mockAdmins.insert(0, mockAdmin);
        
        _emailController.clear();
        _passwordController.clear();
        _nameController.clear();
        widget.onSuccess('Sub-Admin registered successfully! (Dev Mode)');
        _fetchSubAdmins();
        return;
      }

      // 1. Isolated client to prevent logging out the current super admin session
      final inviteClient = SupabaseClient(
        'https://nfurwspybtiaycqntzev.supabase.co',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5mdXJ3c3B5YnRpYXljcW50emV2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyODg4NzcsImV4cCI6MjA5MDg2NDg3N30.IoOwVWFQDNtA5ZIz48G_Zm-VIbzX91MDdMqJ-fy58v0',
        authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
      );

      final res = await inviteClient.auth.signUp(
        email: email,
        password: password,
        data: {'role': 'sub_admin', 'name': name},
      );

      final newUser = res.user;
      if (newUser == null) {
        throw Exception('Failed to sign up sub-admin');
      }

      // 2. Create the user profile row under public.users using Super Admin's main client
      try {
        await supabase.from('users').upsert({
          'id': newUser.id,
          'role': 'sub_admin',
          'email': email,
          'name': name,
        });
      } catch (e) {
        debugPrint('Note: public.users upsert bypassed/handled by trigger: $e');
      }

      // 3. Create tracking row under public.sub_admins
      await supabase.from('sub_admins').upsert({
        'user_id': newUser.id,
        'created_by': currentUser.id,
      });

      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();

      widget.onSuccess('Sub-Admin registered successfully!');
      _fetchSubAdmins();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create sub-admin: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Manage Sub-Admins',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A))),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Create sub-admin form
            const Text(
              'REGISTER NEW SUB-ADMIN',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Full Name',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'Official Email ID',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Password',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _creating ? null : _createSubAdmin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: _creating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('CREATE CREDENTIALS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ),
            const SizedBox(height: 20),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 16),
            const Text(
              'ACTIVE SUB-ADMIN ACCOUNTS',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (_subAdmins.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No sub-admin accounts created yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _subAdmins.length,
                  separatorBuilder: (_, __) => const Divider(color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final sub = _subAdmins[index];
                    final user = sub['users'] as Map? ?? {};
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(user['name']?.toString() ?? 'Sub-Admin', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text(user['email']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        child: const Icon(Icons.admin_panel_settings, color: Color(0xFF8B5CF6), size: 18),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: Color(0xFF64748B))),
        ),
      ],
    );
  }
}
