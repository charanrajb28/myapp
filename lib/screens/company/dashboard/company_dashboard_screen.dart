import 'package:flutter/material.dart';
import '../company_shell.dart';

class CompanyDashboardScreen extends StatelessWidget {
  const CompanyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Deeper Slate for card pop
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
                        // Left: 3 units (slightly wider)
                        Expanded(
                          flex: 3,
                          child: _premiumLargeCard('RECRUITMENT_POOL', '3,422', const Color(0xFF6366F1)),
                        ),
                        const SizedBox(width: 16),
                        // Right: 2 units (slightly narrower)
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _premiumMiniCard('INTERVIEWING', '86', const Color(0xFFF59E0B)),
                              const SizedBox(height: 16),
                              _premiumMiniCard('HIRED_V0.8', '12', const Color(0xFF10B981)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 48)),

                // ── ACTION_PRIORITY_CONSOLE ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.1)),
                        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.05), blurRadius: 25, offset: const Offset(0, 12))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('CRITICAL_REVIEWS_PENDING', style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w900)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(4)),
                                child: const Text('24 HIGH', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(height: 1, color: const Color(0xFFF1F5F9)),
                          const SizedBox(height: 16),
                          _pendingItem('Arjun Mehta', 'Full Stack Dev', '02h ago'),
                          _pendingItem('Sara Khan', 'UI/UX Intern', '05h ago'),
                          const SizedBox(height: 16),
                          _industrialBtn('OPEN_REVIEW_TERMINAL'),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 48)),
                
                // ── OPERATIONS_LOG ──
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Text('> OPERATIONS_LOG.TXT', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
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

  Widget _premiumLargeCard(String title, String value, Color color) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Glow
          Positioned(
            right: -20, top: -20,
            child: Icon(Icons.analytics_rounded, color: color.withValues(alpha: 0.03), size: 140),
          ),
          // Accent Ribbon
          Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 6, color: color)),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 60,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value, style: TextStyle(color: const Color(0xFF0F172A), fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: -2)),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumMiniCard(String title, String value, Color color) {
    return Container(
      width: double.infinity,
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 30,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -1)),
            ),
          ),
          const SizedBox(height: 4),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _pendingItem(String name, String role, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const CircleAvatar(radius: 16, backgroundImage: NetworkImage('https://i.pravatar.cc/150')),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold)),
                Text(role.toUpperCase(), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _industrialBtn(String label) {
    return Container(
      width: double.infinity, height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5))),
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
            Text('SYS_OVERVIEW v2.2', style: TextStyle(color: Color(0xFF6366F1), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 3)),
            SizedBox(height: 8),
            Text('Cloud9 Systems', style: TextStyle(color: Color(0xFF0F172A), fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          ],
        ),
        GestureDetector(
          onTap: () => CompanyShell.of(context)?.setIndex(3),
          child: Hero(
            tag: 'recruiter_avatar',
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2), width: 2),
                image: const DecorationImage(image: NetworkImage('https://i.pravatar.cc/150?u=recruiter'), fit: BoxFit.cover),
                boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text((posting['role'] as String).toUpperCase(), style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('${posting['applicants']} APPLICANTS REGISTERED', style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ],
              ),
            ],
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 18),
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
