import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ManageCandidatesScreen extends StatefulWidget {
  const ManageCandidatesScreen({super.key});

  @override
  State<ManageCandidatesScreen> createState() => _ManageCandidatesScreenState();
}

class _ManageCandidatesScreenState extends State<ManageCandidatesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _candidates = [];
  String _filter = 'ALL_CANDIDATES';

  @override
  void initState() {
    super.initState();
    _fetchCandidates();
  }

  Future<void> _fetchCandidates() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final companyRes = await supabase
          .from('companies')
          .select('id')
          .eq('user_id', user.id)
          .single();
      
      final companyId = companyRes['id'];

      final res = await supabase
          .from('applications')
          .select('*, students(name), internships(role)')
          .eq('internships.company_id', companyId);
      
      final List<Map<String, dynamic>> processed = [];
      for (var app in (res as List)) {
        if (app['internships'] == null) continue;

        final studentName = app['students']?['name'] ?? 'Unknown Student';
        final role = app['internships']?['role'] ?? 'Unknown Role';
        final initials = studentName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

        processed.add({
          'id': app['id'],
          'initials': initials,
          'name': studentName,
          'targetRole': role,
          'status': app['status'] ?? 'Pending',
          'appliedDate': DateFormat('dd MMM yyyy').format(DateTime.parse(app['created_at'])),
        });
      }

      if (mounted) {
        setState(() {
          _candidates = processed;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching candidates: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filtered = _candidates;
    if (_filter == 'SHORTLISTED') {
      filtered = _candidates.where((c) => c['status'] == 'Active' || c['status'] == 'Completed').toList();
    } else if (_filter == 'PENDING_REVIEW') {
      filtered = _candidates.where((c) => c['status'] == 'Applied' || c['status'] == 'Under Review').toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Positioned.fill(child: _DotGrid()),
          SafeArea(
            child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(child: _CandidateHeader()),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
                
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        _filterBtn('ALL CANDIDATES'),
                        const SizedBox(width: 10),
                        _filterBtn('SHORTLISTED'),
                        const SizedBox(width: 10),
                        _filterBtn('PENDING REVIEW'),
                      ],
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
                
                filtered.isEmpty 
                ? const SliverToBoxAdapter(child: Center(child: Text('No candidates found.', style: TextStyle(color: Color(0xFF64748B)))))
                : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _CandidateCard(candidate: filtered[index]),
                      childCount: filtered.length,
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

  Widget _filterBtn(String label) {
    bool isSelected = _filter == label;
    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: Container(
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
      ),
    );
  }
}

class _CandidateHeader extends StatelessWidget {
  const _CandidateHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('APPLICANT DATABASE', style: TextStyle(color: Color(0xFF6366F1), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
        SizedBox(height: 8),
        Text('Manage Candidates', style: TextStyle(color: Color(0xFF0F172A), fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
      ],
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final Map<String, dynamic> candidate;
  const _CandidateCard({required this.candidate});

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
      case 'active':
      case 'completed':
      case 'shortlisted': return const Color(0xFF10B981);
      case 'applied':
      case 'under review':
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
