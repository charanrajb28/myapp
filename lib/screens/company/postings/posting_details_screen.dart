import 'package:flutter/material.dart';
import 'edit_posting_screen.dart';

class PostingDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> posting;
  const PostingDetailsScreen({super.key, required this.posting});

  @override
  State<PostingDetailsScreen> createState() => _PostingDetailsScreenState();
}

class _PostingDetailsScreenState extends State<PostingDetailsScreen> {
  late String roleName;
  late String status;

  @override
  void initState() {
    super.initState();
    roleName = widget.posting['role'];
    status = widget.posting['status'];
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.posting['color'] as Color;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Positioned.fill(child: _DotGrid()),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── BANNER_HERO ──
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(height: 180, width: double.infinity, decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight))),
                    Positioned(top: 40, left: 24, child: GestureDetector(onTap: () => Navigator.pop(context), child: CircleAvatar(backgroundColor: Colors.white.withValues(alpha: 0.2), child: const Icon(Icons.arrow_back_rounded, color: Colors.white)))),
                    Positioned(bottom: -30, left: 24, child: Container(width: 70, height: 70, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 1), blurRadius: 10, offset: const Offset(0, 5))]), child: Icon(Icons.work_rounded, color: color, size: 28))),
                  ],
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 45)),

              // ── IDENTITY_UNIT ──
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(roleName.toUpperCase(), style: const TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _statusChip('ACTV_PHASE: $status', color),
                          const SizedBox(width: 12),
                          _statusChip('SECURE_RECORD', const Color(0xFF6366F1)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── PRIMARY_BENTO_GRID ──
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(child: _bentoParam('STIPEND_VAL', '₹25K /mo', Icons.payments_rounded, color)),
                      const SizedBox(width: 12),
                      Expanded(child: _bentoParam('DURATION', '06 Months', Icons.timer_rounded, const Color(0xFF6366F1))),
                      const SizedBox(width: 12),
                      Expanded(child: _bentoParam('LOCATION', 'REMOTE_IN', Icons.place_rounded, const Color(0xFFF59E0B))),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // ── MISSION_DETAILS_LEDGER ──
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _narrativeCard('MISSION_LOG', 'Our company is scaling decentralised AI nodes. We need a high-performance engineer to build technical dashboards and cloud infra for enterprise monitoring. This is a mission-critical role for the 2026 roadmap.'),
                    const SizedBox(height: 20),
                    _responsibilitiesCard('MISSION_RESPONSIBILITIES', [
                      'Architect and scale responsive UI modules in Flutter.',
                      'Optimize Node.js service layers for low-latency nodes.',
                      'Integrate Firebase cloud functions for real-time monitoring.',
                      'Standardise technical documentation for system audits.',
                    ]),
                    const SizedBox(height: 20),
                    _qualificationGrid('QUALIFICATION_MATRIX', 'B.Tech / BE in Comp Science', 'No backlogs. Minimum 7.5 CGPA required.'),
                  ]),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 48)),

              // ── APPLICANT_REGISTRY ──
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: Text('> APPLICANT_REGISTRY_LOG', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _CandidateIndustrialTile(
                      candidate: _dummyCandidates[index],
                      onTap: () => _showCandidateDetail(context, _dummyCandidates[index]),
                    ),
                    childCount: _dummyCandidates.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 48)),

              // ── ACTION_CONSOLE ──
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(child: _actionBtn('EDIT_CONSOLE', true, color, () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditPostingScreen(posting: widget.posting))))),
                      const SizedBox(width: 12),
                      Expanded(child: _actionBtn('CLOSE_SLOT', false, color, () {})),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _narrativeCard(String label, String content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('> $label', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.6, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _responsibilitiesCard(String label, List<String> duties) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('> $label', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 16),
          Column(
            children: duties.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(padding: EdgeInsets.only(top: 4), child: Icon(Icons.circle, color: Color(0xFF6366F1), size: 6)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(d, style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.5, fontWeight: FontWeight.w500))),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _qualificationGrid(String label, String degree, String notes) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('> $label', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 12),
          Text(degree, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(notes, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
    );
  }

  Widget _bentoParam(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, bool isPrimary, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(color: isPrimary ? const Color(0xFF0F172A) : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF0F172A))),
        child: Center(child: Text(label, style: TextStyle(color: isPrimary ? Colors.white : const Color(0xFF0F172A), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5))),
      ),
    );
  }

  void _showCandidateDetail(BuildContext context, Map<String, dynamic> candidate) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 28, backgroundImage: NetworkImage(candidate['avatar'])),
                const SizedBox(width: 20),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(candidate['name'], style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w900)),
                  Text(candidate['college'], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ]),
              ],
            ),
            const SizedBox(height: 32),
            const Text('> APPLICATION_INSIGHTS', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 16),
            _insightRow('MATCH_SCORE', '84%', const Color(0xFF10B981)),
            _insightRow('PROFILE_STATE', 'SCREENING_NODE_ACTIVE', const Color(0xFF6366F1)),
            const SizedBox(height: 32),
            _industrialBtnSmall('VIEW_FULL_PORTFOLIO'),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _insightRow(String label, String value, Color color) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)), Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))]));
  }

  Widget _industrialBtnSmall(String label) {
    return Container(width: double.infinity, height: 44, decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)), child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5))));
  }
}

class _CandidateIndustrialTile extends StatelessWidget {
  final Map<String, dynamic> candidate;
  final VoidCallback onTap;
  const _CandidateIndustrialTile({required this.candidate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Row(
          children: [
            CircleAvatar(radius: 18, backgroundImage: NetworkImage(candidate['avatar'])),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(candidate['name'], style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold)), Text(candidate['college'].toUpperCase(), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.w800))])),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 12),
          ],
        ),
      ),
    );
  }
}

class _DotGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShaderMask(shaderCallback: (rect) => LinearGradient(colors: [Colors.white, Colors.white.withValues(alpha: 0.3), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(rect), child: CustomPaint(painter: _DotPainter()));
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

final _dummyCandidates = [
  {'name': 'Arjun Mehta', 'college': 'IIT Bombay', 'avatar': 'https://i.pravatar.cc/150?u=1'},
  {'name': 'Sara Khan', 'college': 'BITS Pilani', 'avatar': 'https://i.pravatar.cc/150?u=2'},
  {'name': 'Vikram Singh', 'college': 'NIT Trichy', 'avatar': 'https://i.pravatar.cc/150?u=3'},
];
