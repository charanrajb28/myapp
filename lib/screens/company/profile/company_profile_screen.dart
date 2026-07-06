import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_company_profile_screen.dart';
import 'package:intl/intl.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _companyData;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> refreshData() async {
    await _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        // DEV-ONLY: Guest login bypass
        if (mounted) {
          setState(() {
            _companyData = {
              'name': 'TechCorp Solutions (Dev Mode)',
              'industry': 'Software & AI Systems',
              'description': 'TechCorp Solutions is a leading engineering enterprise specialized in highly robust web and mobile architectures, AI tooling, and premium digital solutions.',
              'location': 'San Francisco, CA',
              'partner_since': '2022',
              'logo_url': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=150',
              'banner_url': 'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&q=80&w=1000',
            };
            _isLoading = false;
          });
        }
        return;
      }

      final res = await supabase
          .from('companies')
          .select('*')
          .eq('user_id', user.id)
          .single();
      
      if (mounted) {
        setState(() {
          _companyData = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    final name = _companyData?['name'] ?? 'Partner Company';
    final industry = _companyData?['industry'] ?? 'Technology';
    final description = _companyData?['description'] ?? 'No description provided.';
    final location = _companyData?['location'] ?? 'Remote/Unspecified';
    final since = _companyData?['partner_since']?.toString() ?? '2024';
    final website = _companyData?['website'] ?? 'Not specified';
    final phone = _companyData?['phone'] ?? 'Not specified';
    final contactEmail = _companyData?['contact_email'] ?? 'Not specified';
    final mouDateRaw = _companyData?['mou_date'];
    String mouDate = 'Not specified';
    if (mouDateRaw != null) {
      try {
        mouDate = DateFormat('dd MMM yyyy').format(DateTime.parse(mouDateRaw.toString()));
      } catch (_) {}
    }

    return DefaultTabController(
      length: 1, // Simplified for now
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Stack(
          children: [
            Positioned.fill(child: _DotGrid()),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── ADMIN_BANNER_UNIT ──
                SliverToBoxAdapter(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          image: (_companyData?['banner_url']?.toString().trim().isNotEmpty ?? false)
                              ? DecorationImage(
                                  image: NetworkImage(_companyData!['banner_url'].toString()),
                                  fit: BoxFit.cover,
                                  opacity: 0.55,
                                )
                              : const DecorationImage(
                                  image: NetworkImage('https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&q=80&w=1000'),
                                  fit: BoxFit.cover,
                                  opacity: 0.3,
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: -40, left: 24,
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))],
                            image: (_companyData?['logo_url']?.toString().trim().isNotEmpty ?? false)
                                ? DecorationImage(
                                    image: NetworkImage(_companyData!['logo_url'].toString()),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: (_companyData?['logo_url']?.toString().trim().isNotEmpty ?? false)
                              ? null
                              : Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'C', style: const TextStyle(color: Color(0xFF6366F1), fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1))),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
                
                // ── ADMIN_IDENTITY_UNIT ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 14),
                            SizedBox(width: 6),
                            Text('VERIFIED PARTNER', style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
 
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
 
                // ── ADMIN_ACTION_CONSOLE ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(child: _adminBtn('EDIT PROFILE', true, Icons.edit_note_rounded, () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => EditCompanyProfileScreen(companyData: _companyData ?? {})));
                          _fetchProfile();
                        })),
                        const SizedBox(width: 12),
                        Expanded(child: _adminBtn('REFRESH DATA', false, Icons.sync_rounded, () => _showSyncProcess(context))),
                      ],
                    ),
                  ),
                ),
 
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
 
                // ── TAB_CONTENT ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _narrativeCard(description),
                      const SizedBox(height: 28),
                      
                      // Modern Grid for Contact Info
                      const Text('CONTACT & CHANNELS', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _infoTileCard(
                              icon: Icons.language_rounded,
                              iconColor: const Color(0xFF0EA5E9),
                              label: 'WEBSITE',
                              value: website,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _infoTileCard(
                              icon: Icons.phone_rounded,
                              iconColor: const Color(0xFF10B981),
                              label: 'PHONE',
                              value: phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _infoTileCard(
                        icon: Icons.email_rounded,
                        iconColor: const Color(0xFF6366F1),
                        label: 'CONTACT EMAIL',
                        value: contactEmail,
                      ),
                      
                      const SizedBox(height: 28),
                      
                      // Company Info List Card
                      const Text('PARTNERSHIP & PROFILE DETAILS', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _profileRowItem(
                              icon: Icons.business_rounded,
                              iconColor: const Color(0xFFEC4899),
                              label: 'INDUSTRY',
                              value: industry,
                            ),
                            const Divider(color: Color(0xFFF1F5F9), height: 1, indent: 56, endIndent: 20),
                            _profileRowItem(
                              icon: Icons.location_on_rounded,
                              iconColor: const Color(0xFFEF4444),
                              label: 'HEADQUARTERS',
                              value: location,
                            ),
                            const Divider(color: Color(0xFFF1F5F9), height: 1, indent: 56, endIndent: 20),
                            _profileRowItem(
                              icon: Icons.calendar_today_rounded,
                              iconColor: const Color(0xFFF59E0B),
                              label: 'PARTNER SINCE',
                              value: since,
                            ),
                            const Divider(color: Color(0xFFF1F5F9), height: 1, indent: 56, endIndent: 20),
                            _profileRowItem(
                              icon: Icons.handshake_rounded,
                              iconColor: const Color(0xFF8B5CF6),
                              label: 'MOU SIGN DATE',
                              value: mouDate,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      _logoutBtn(context),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminBtn(String label, bool isPrimary, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isPrimary ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isPrimary ? Colors.white : const Color(0xFF0F172A), size: 16),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isPrimary ? Colors.white : const Color(0xFF0F172A), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _narrativeCard(String text) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ABOUT US', style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.6, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _infoTileCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileRowItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSyncProcess(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      duration: Duration(seconds: 2),
      content: Text('Refreshing dashboard data...'),
      backgroundColor: Color(0xFF6366F1),
    ));
  }

  Widget _logoutBtn(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Supabase.instance.client.auth.signOut();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 18),
            SizedBox(width: 12),
            Text('LOGOUT FROM SESSION', style: TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

class _DotGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => LinearGradient(colors: [Colors.white, Colors.white.withValues(alpha: 0.3), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(rect),
      child: CustomPaint(painter: _DotPainter()),
    );
  }
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFE2E8F0)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 30) {
      for (double j = 0; j < size.height; j += 30) {
        canvas.drawCircle(Offset(i, j), 1, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
