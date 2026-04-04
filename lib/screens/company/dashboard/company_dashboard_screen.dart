import 'package:flutter/material.dart';
import '../company_shell.dart';

class CompanyDashboardScreen extends StatelessWidget {
  const CompanyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(child: _IndustrialHeader()),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 48)),

                
                // ── PREMIUM_BENTO_GRID ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _premiumLargeCard('RECRUITMENT_POOL', '3,422', const Color(0xFF6366F1), Icons.group_add_rounded),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _premiumMiniCard('INTERVIEWING', '86', const Color(0xFFF59E0B), Icons.forum_rounded),
                              const SizedBox(height: 16),
                              _premiumMiniCard('HIRED_NODES', '12', const Color(0xFF10B981), Icons.verified_rounded),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 48)),
                
                // ── OPERATIONS_LOG ──
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Text('> RECRUITMENT_LOG_FEED', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _LogItemCard(posting: _dummyLogs[index]),
                      childCount: _dummyLogs.length,
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

class _IndustrialHeader extends StatelessWidget {
  const _IndustrialHeader();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FRACTAL_OS v2.4', style: TextStyle(color: Color(0xFF6366F1), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 3)),
            SizedBox(height: 10),
            Text('Cloud9 Systems', style: TextStyle(color: Color(0xFF0F172A), fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
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
            child: Icon(Icons.token_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((posting['role'] as String).toUpperCase(), style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Text('${posting['applicants']} NODES SYNCED', style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
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

final _dummyLogs = [
  {'role': 'Full Stack Developer', 'applicants': '42', 'color': const Color(0xFF6366F1)},
  {'role': 'UI/UX Design Intern', 'applicants': '18', 'color': const Color(0xFF8B5CF6)},
  {'role': 'DevOps Engineering', 'applicants': '09', 'color': const Color(0xFF64748B)},
];
