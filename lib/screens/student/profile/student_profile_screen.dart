import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../student_portal_repository.dart';
import 'edit_profile_screen.dart';
import 'security_password_screen.dart';
import 'student_documents_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _repository = StudentPortalRepository();
  bool _isLoading = true;
  StudentProfileData? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _repository.fetchProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load profile: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(profile),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                    'Academic Details',
                    Icons.school_rounded,
                    const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 16),
                  _buildAcademicCard(profile),
                  const SizedBox(height: 32),
                  _buildSectionTitle(
                    'Contact Details',
                    Icons.contact_page_rounded,
                    const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 16),
                  _buildContactCard(profile),
                  const SizedBox(height: 32),
                  _buildSectionTitle(
                    'Account Actions',
                    Icons.manage_accounts_rounded,
                    const Color(0xFF0F172A),
                  ),
                  const SizedBox(height: 16),
                  _buildAccountSection(),
                  const SizedBox(height: 48),
                  _buildLogoutButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(StudentProfileData? profile) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF0F172A),
      surfaceTintColor: Colors.transparent,
      actions: [
        IconButton(
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const EditProfileScreen()))
              .then((_) => _loadProfile()),
          icon: const Icon(Icons.edit_rounded, color: Colors.white70, size: 20),
        ),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                image: profile?.avatarUrl.trim().isNotEmpty == true
                    ? DecorationImage(
                        image: NetworkImage(profile!.avatarUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: profile?.avatarUrl.trim().isNotEmpty == true
                  ? null
                  : Center(
                      child: Text(
                        profile?.initials ?? 'ST',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              profile?.name ?? 'Student',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              profile?.email ?? 'Email not available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                (profile?.semester ?? 'ACTIVE STUDENT').toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 40),
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
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicCard(StudentProfileData? profile) {
    return _sectionCard(
      children: [
        _infoTile('Department', profile?.department ?? 'Not set'),
        _divider(),
        _infoTile('Enrollment ID', profile?.enrollmentId ?? 'Not set'),
        _divider(),
        _infoTile('College', profile?.college ?? 'Not set'),
        _divider(),
        _infoTile('Graduation Year', profile?.graduationYear ?? 'Not set'),
        _divider(),
        _infoTile('GPA', profile?.gpa ?? 'Not set'),
      ],
    );
  }

  Widget _buildContactCard(StudentProfileData? profile) {
    return _sectionCard(
      children: [
        _infoTile('Email', profile?.email ?? 'Not set'),
        _divider(),
        _infoTile('Phone', profile?.phone ?? 'Not set'),
        _divider(),
        _infoTile('Semester', profile?.semester ?? 'Not set'),
      ],
    );
  }

  Widget _buildAccountSection() {
    return _sectionCard(
      children: [
        _actionTile(
          'Edit Personal Details',
          Icons.edit_note_rounded,
          () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const EditProfileScreen()))
              .then((_) => _loadProfile()),
        ),
        _divider(),
        _actionTile(
          'Security & Password',
          Icons.lock_outline_rounded,
          () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SecurityPasswordScreen()),
          ),
        ),
        _divider(),
        _actionTile(
          'Documents Box',
          Icons.folder_open_rounded,
          () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StudentDocumentsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: () async {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 20, color: Color(0xFFDC2626)),
            SizedBox(width: 12),
            Text(
              'SIGN OUT ACCOUNT',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFFDC2626),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF64748B).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: Color(0xFFCBD5E1),
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF1F5F9),
      indent: 20,
      endIndent: 20,
    );
  }
}
