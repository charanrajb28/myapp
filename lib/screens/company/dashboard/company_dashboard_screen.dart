import 'package:flutter/material.dart';

class CompanyDashboardScreen extends StatelessWidget {
  const CompanyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Company Header ──
            const SliverToBoxAdapter(child: _CompanyHeader()),
            
            // ── Primary Analytics ──
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(child: _StatusOverview()),
            ),

            // ── Active Postings Section ──
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 32, 20, 16),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Active Internship Postings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
                ),
              ),
            ),
            
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _PostingListItem(
                    role: _dummyPostings[index]['role']!,
                    applicants: _dummyPostings[index]['applicants']!,
                    status: _dummyPostings[index]['status']!,
                    color: _dummyPostings[index]['color'] as Color,
                  ),
                  childCount: _dummyPostings.length,
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF0F172A),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('POST NEW INTERNSHIP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────

class _CompanyHeader extends StatelessWidget {
  const _CompanyHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'C9',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF6366F1)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back,', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                SizedBox(height: 2),
                Text('Cloud9 Systems', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.8)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _StatusOverview extends StatelessWidget {
  const _StatusOverview();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _statCard('PENDING', '24', const Color(0xFF3B82F6)),
        _statCard('SHORTLISTED', '12', const Color(0xFF10B981)),
        _statCard('ACTIVE INTERNS', '08', const Color(0xFF8B5CF6)),
        _statCard('TOTAL POSTS', '05', const Color(0xFF6366F1)),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width - 40; // horizontal padding
        final cardWidth = (screenWidth - 12) / 2; // 12 is spacing

        return Container(
          width: cardWidth,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 1, height: 1.0),
              ),
            ],
          ),
        );
      }
    );
  }
}

class _PostingListItem extends StatelessWidget {
  final String role, applicants, status;
  final Color color;
  const _PostingListItem({required this.role, required this.applicants, required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.work_outline_rounded, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.3)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.groups_rounded, size: 12, color: const Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text('$applicants Applicants', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        status,
                        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 14),
        ],
      ),
    );
  }
}

final _dummyPostings = [
  {'role': 'Full Stack Developer', 'applicants': '42', 'status': 'ACTIVE', 'color': const Color(0xFF6366F1)},
  {'role': 'UI/UX Design Intern', 'applicants': '18', 'status': 'INTERVIEWING', 'color': const Color(0xFF8B5CF6)},
  {'role': 'DevOps Engineering', 'applicants': '09', 'status': 'DRAFT', 'color': const Color(0xFF64748B)},
];
