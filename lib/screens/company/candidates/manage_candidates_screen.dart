import 'package:flutter/material.dart';

class ManageCandidatesScreen extends StatelessWidget {
  const ManageCandidatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                  sliver: SliverToBoxAdapter(child: _IndustrialCandidateHeader()),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
                
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        _filterChip('ALL_CANDIDATES', true),
                        const SizedBox(width: 10),
                        _filterChip('SHORTLISTED', false),
                        const SizedBox(width: 10),
                        _filterChip('PENDING_REVIEW', false),
                      ],
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
                
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _CandidateIndustrialCard(candidate: _dummyCandidates[index]),
                      childCount: _dummyCandidates.length,
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

  Widget _filterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6366F1) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF64748B),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _IndustrialCandidateHeader extends StatelessWidget {
  const _IndustrialCandidateHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DB_RECORDS v2.4', style: TextStyle(color: Color(0xFF6366F1), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2.5)),
        SizedBox(height: 8),
        Text('Manage Candidates', style: TextStyle(color: Color(0xFF0F172A), fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
      ],
    );
  }
}

class _CandidateIndustrialCard extends StatelessWidget {
  final Map<String, dynamic> candidate;
  const _CandidateIndustrialCard({required this.candidate});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(candidate['status'] as String);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 4, color: statusColor)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      candidate['initials'] as String,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(candidate['name'] as String, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        (candidate['targetRole'] as String).toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        (candidate['status'] as String).toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      candidate['appliedDate'] as String,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'shortlisted': return const Color(0xFF10B981);
      case 'pending': return const Color(0xFFF59E0B);
      case 'rejected': return const Color(0xFFEF4444);
      default: return const Color(0xFF6366F1);
    }
  }
}

class _DotGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => LinearGradient(colors: [Colors.white, Colors.white.withValues(alpha: 0.3), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(rect),
      child: CustomPaint(
        painter: _DotPainter(),
      ),
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

final _dummyCandidates = [
  {'initials': 'AM', 'name': 'Arjun Mehta', 'targetRole': 'Full Stack Dev', 'status': 'Shortlisted', 'appliedDate': '02 MAR 2024'},
  {'initials': 'SK', 'name': 'Sara Khan', 'targetRole': 'UI/UX Design', 'status': 'Pending', 'appliedDate': '03 MAR 2024'},
  {'initials': 'RV', 'name': 'Rohan Verma', 'targetRole': 'DevOps Eng', 'status': 'In Review', 'appliedDate': '28 FEB 2024'},
];
