import 'package:flutter/material.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _notificationsEnabled = true;
  bool _remindersEnabled = true;

  final Color _primaryColor = const Color(0xFF0F172A);
  final Color _accentColor = const Color(0xFF6366F1);
  final Color _bgColor = const Color(0xFFF8FAFC);

  void _showSuccessSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.all(20),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickStats(),
                  const SizedBox(height: 32),

                  _buildSectionTitle('Academic Details', Icons.school_rounded, const Color(0xFF3B82F6)),
                  const SizedBox(height: 16),
                  _buildAcademicCard(),
                  const SizedBox(height: 32),

                  _buildSectionTitle('Skills & Expertise', Icons.auto_awesome_rounded, const Color(0xFF8B5CF6)),
                  const SizedBox(height: 16),
                  _buildSkillsSection(),
                  const SizedBox(height: 32),

                  _buildSectionTitle('Preferences', Icons.tune_rounded, const Color(0xFFF59E0B)),
                  const SizedBox(height: 16),
                  _buildSettingsSection(),
                  const SizedBox(height: 32),

                  _buildSectionTitle('Account Actions', Icons.manage_accounts_rounded, _primaryColor),
                  const SizedBox(height: 16),
                  _buildAccountSection(),
                  const SizedBox(height: 48),

                  _buildLogoutButton(),
                  const SizedBox(height: 40),
                  
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'ScholarBridge Student Portal',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version 2.4.0 • Enterprise Edition',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: const Color(0xFFCBD5E1)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      elevation: 0,
      backgroundColor: _primaryColor,
      stretch: true,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Abstract Background Decoration
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 250, height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accentColor.withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: -30,
              child: Container(
                width: 150, height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            
            // Profile Content
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Hero(
                  tag: 'profile_pic',
                  child: Container(
                    width: 100,
                    height: 100,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2),
                      gradient: LinearGradient(
                        colors: [_accentColor, const Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                      ),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF0F172A),
                      ),
                      child: const Center(
                        child: Text(
                          'AM',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Arjun Mehta',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'arjun.mehta@college.edu',
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ACTIVE STUDENT',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _statItem('CGPA', '8.74', const Color(0xFF3B82F6), Icons.auto_graph_rounded),
        const SizedBox(width: 16),
        _statItem('ATTENDANCE', '94%', const Color(0xFF10B981), Icons.event_available_rounded),
        const SizedBox(width: 16),
        _statItem('CREDITS', '142', const Color(0xFF8B5CF6), Icons.workspace_premium_rounded),
      ],
    );
  }

  Widget _statItem(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 24, offset: const Offset(0, 12)),
          ],
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(height: 16),
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                label, 
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                value, 
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.3),
        ),
      ],
    );
  }

  Widget _buildAcademicCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          _academicTile('Department', 'Computer Science & Engineering', Icons.account_tree_rounded),
          _divider(),
          _academicTile('Enrollment ID', 'SCH2024CS042', Icons.badge_rounded),
          _divider(),
          _academicTile('Cohort Batch', '2021 – 2025 (Final Year)', Icons.group_rounded),
          _divider(),
          _academicTile('Project Mentor', 'Dr. Sarah Wilson', Icons.person_pin_rounded),
        ],
      ),
    );
  }

  Widget _academicTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9), indent: 56, endIndent: 20);

  Widget _buildSkillsSection() {
    final skills = [
      {'label': 'Python', 'color': Color(0xFF3B82F6)},
      {'label': 'Flutter', 'color': Color(0xFF60A5FA)},
      {'label': 'React', 'color': Color(0xFF22D3EE)},
      {'label': 'Machine Learning', 'color': Color(0xFF8B5CF6)},
      {'label': 'AWS', 'color': Color(0xFFF59E0B)},
      {'label': 'UI Design', 'color': Color(0xFFEC4899)},
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: skills.map((s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: (s['color'] as Color).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: (s['color'] as Color).withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: s['color'] as Color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              s['label'] as String,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: (s['color'] as Color)),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          _toggleTile(
            'Push Notifications', 
            'Deadlines, attendance & updates', 
            _notificationsEnabled, 
            const Color(0xFFF59E0B),
            (v) => setState(() {
               _notificationsEnabled = v;
               _showSuccessSnack(v ? 'Notifications activated' : 'Notifications muted');
            }),
          ),
          _divider(),
          _toggleTile(
             'Check-In Reminders', 
             'Daily alert for mandatory login', 
             _remindersEnabled, 
             const Color(0xFF3B82F6),
             (v) => setState(() {
                _remindersEnabled = v;
                _showSuccessSnack(v ? 'Reminders enabled' : 'Reminders disabled');
             }),
          ),
        ],
      ),
    );
  }

  Widget _toggleTile(String title, String subtitle, bool value, Color color, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(value ? Icons.notifications_active_rounded : Icons.notifications_off_rounded, size: 18, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                Text(subtitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          Switch.adaptive(
            value: value, 
            onChanged: onChanged,
            activeColor: color,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          _actionTile('Edit Personal Details', Icons.edit_note_rounded, const Color(0xFF64748B), () {}),
          _divider(),
          _actionTile('Security & Password', Icons.lock_outline_rounded, const Color(0xFF64748B), () {}),
          _divider(),
          _actionTile('Documents Box', Icons.folder_open_rounded, const Color(0xFF64748B), () {}),
          _divider(),
          _actionTile('Privacy Policy', Icons.policy_rounded, const Color(0xFF64748B), () {}),
        ],
      ),
    );
  }

  Widget _actionTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFCBD5E1)),
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: () => Navigator.of(context).pushReplacementNamed('/'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 20, color: const Color(0xFFDC2626)),
            const SizedBox(width: 12),
            Text(
              'SIGN OUT ACCOUNT',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFFDC2626), letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }
}
