import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../company_shell.dart';

class CompanyDashboardScreen extends StatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  bool _isLoading = true;
  String _companyName = 'Loading...';
  String _recruitmentPool = '0';
  String _interviewing = '0';
  String _hired = '0';
  List<Map<String, dynamic>> _activePostings = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 1. Get Company Profile
      final companyRes = await supabase
          .from('companies')
          .select('id, name')
          .eq('user_id', user.id)
          .single();
      
      final companyId = companyRes['id'];
      
      // 2. Get Postings and Application Counts
      final postingsRes = await supabase
          .from('internships')
          .select('id, role, brand_color')
          .eq('company_id', companyId);
      
      final List<String> postingIds = (postingsRes as List).map((p) => p['id'].toString()).toList();
      
      int pool = 0;
      int interviewing = 0;
      int hired = 0;

      if (postingIds.isNotEmpty) {
        final appsRes = await supabase
            .from('applications')
            .select('status')
            .inFilter('internship_id', postingIds);
            
        final apps = appsRes as List;
        pool = apps.length;
        interviewing = apps.where((a) => a['status'] == 'Under Review' || a['status'] == 'Active').length;
        hired = apps.where((a) => a['status'] == 'Completed' || a['status'] == 'Active').length;
      }

      // 3. Prepare Display List (Top 3 Postings)
      final List<Map<String, dynamic>> displayPostings = [];
      for (var p in (postingsRes as List).take(3)) {
        int count = 0;
        if (postingIds.isNotEmpty) {
           final specApps = await supabase.from('applications').select('id').eq('internship_id', p['id']);
           count = (specApps as List).length;
        }
        
        displayPostings.add({
          'role': p['role'],
          'applicants': count.toString(),
          'color': _parseColor(p['brand_color'] ?? '#6366F1'),
        });
      }

      if (mounted) {
        setState(() {
          _companyName = companyRes['name'] ?? 'Partner Company';
          _recruitmentPool = pool.toString();
          _interviewing = interviewing.toString();
          _hired = hired.toString();
          _activePostings = displayPostings;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching company dashboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          Positioned.fill(child: _DotGrid()),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(child: _DashboardHeader(companyName: _companyName)),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 48)),

                // ── SUMMARY_CARDS ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _premiumLargeCard('TOTAL APPLICANTS', _recruitmentPool, const Color(0xFF6366F1), Icons.group_add_rounded),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _premiumMiniCard('INTERVIEWING', _interviewing, const Color(0xFFF59E0B), Icons.forum_rounded),
                              const SizedBox(height: 16),
                              _premiumMiniCard('TOTAL HIRES', _hired, const Color(0xFF10B981), Icons.verified_rounded),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 48)),
                
                // ── RECENT_JOBS_LIST ──
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Text('RECENT JOB POSTINGS', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                
                _activePostings.isEmpty 
                ? const SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.work_outline_rounded, color: Color(0xFFCBD5E1), size: 40),
                          SizedBox(height: 12),
                          Text('NO ACTIVE POSTINGS', style: TextStyle(color: Color(0xFF0F172A), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          Text('You haven\'t posted any jobs yet.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _LogItemCard(posting: _activePostings[index]),
                      childCount: _activePostings.length,
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumLargeCard(String title, String value, Color color, IconData icon) {
    return Container(
      height: 236,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(right: -30, top: -30, child: Icon(icon, color: color.withValues(alpha: 0.03), size: 160)),
          Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 8, color: color)),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 44,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: ShaderMask(
                      shaderCallback: (rect) => LinearGradient(colors: [const Color(0xFF0F172A), const Color(0xFF0F172A).withValues(alpha: 0.7)]).createShader(rect),
                      child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(title, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumMiniCard(String title, String value, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 30,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -1)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ],
            ),
          ),
          Icon(icon, color: color.withValues(alpha: 0.2), size: 24),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String companyName;
  const _DashboardHeader({required this.companyName});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('RECRUITER DASHBOARD', style: TextStyle(color: Color(0xFF6366F1), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 10),
            Text(companyName, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          ],
        ),
        GestureDetector(
          onTap: () => CompanyShell.of(context)?.setIndex(3),
          child: Hero(
            tag: 'recruiter_avatar',
            child: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2), width: 2),
                image: const DecorationImage(image: NetworkImage('https://i.pravatar.cc/150?u=recruiter'), fit: BoxFit.cover),
                boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8))],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LogItemCard extends StatelessWidget {
  final Map<String, dynamic> posting;
  const _LogItemCard({required this.posting});

  @override
  Widget build(BuildContext context) {
    final color = posting['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.work_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((posting['role'] as String).toUpperCase(), style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Text('${posting['applicants']} APPLICANTS', style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 14),
        ],
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
    final paint = Paint()..color = const Color(0xFFCBD5E1)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 30) {
      for (double j = 0; j < size.height; j += 30) {
        canvas.drawCircle(Offset(i, j), 1, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
