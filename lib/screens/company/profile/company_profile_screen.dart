import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_company_profile_screen.dart';

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
      if (user == null) return;

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
                      const SizedBox(height: 24),
                      const Text('COMPANY INFORMATION', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      const SizedBox(height: 12),
                      _ledgerRow('INDUSTRY', industry.toUpperCase(), () => {}),
                      _ledgerRow('ESTABLISHED', since, () => {}),
                      _ledgerRow('HEADQUARTERS', location.toUpperCase(), () => {}),
                      const SizedBox(height: 24),
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

  Widget _ledgerRow(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
            Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
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
