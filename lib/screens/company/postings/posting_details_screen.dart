import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../candidates/candidate_portfolio_screen.dart';

class PostingDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> posting;
  const PostingDetailsScreen({super.key, required this.posting});

  @override
  State<PostingDetailsScreen> createState() => _PostingDetailsScreenState();
}

class _PostingDetailsScreenState extends State<PostingDetailsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _applicants = [];
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchApplicants();
  }

  Future<void> _fetchApplicants() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      // Fetch applications along with student profiles
      final res = await supabase
          .from('applications')
          .select('*, student_profiles(*)')
          .eq('internship_id', widget.posting['id']);

      if (mounted) {
        setState(() {
          _applicants = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching applicants: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateApplicationStatus(String applicationId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('applications')
          .update({'status': newStatus})
          .eq('id', applicationId);
      
      _fetchApplicants();
    } catch (e) {
      debugPrint('Error updating application status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.posting['color'] as Color? ?? const Color(0xFF6366F1);
    final role = widget.posting['role']?.toString() ?? 'Unknown Role';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          Positioned.fill(child: _DotGrid()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, color, role),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildContent(color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color color, String role) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              ),
              const Spacer(),
              _statusChip(widget.posting['status'] ?? 'INTERVIEWING', color),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.work_rounded, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'POSTED ON ${_formatDate(widget.posting['created_at'])}',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Color color) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Row(
            children: [
              _tabButton(0, 'APPLICANTS', _applicants.length.toString()),
              const SizedBox(width: 16),
              _tabButton(1, 'DESCRIPTION', null),
            ],
          ),
        ),
        Expanded(
          child: _tabIndex == 0 ? _buildApplicantsList(color) : _buildDescription(color),
        ),
      ],
    );
  }

  Widget _tabButton(int index, String label, String? count) {
    final active = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: active ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  count,
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantsList(Color color) {
    if (_applicants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 64, color: const Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            const Text(
              'NO APPLICANTS YET',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _applicants.length,
      itemBuilder: (context, index) {
        final app = _applicants[index];
        final student = app['student_profiles'] as Map<String, dynamic>?;
        final name = student?['full_name'] ?? 'Candidate';
        final status = app['status'] ?? 'Applied';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CandidatePortfolioScreen(
                            candidate: {
                              'id': student?['id'] ?? '',
                              'name': student?['full_name'] ?? 'Candidate',
                              'college': student?['college'] ?? 'University',
                              'avatar': student?['avatar_url'] ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=${student?['full_name'] ?? 'C'}',
                            },
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, color: Color(0xFF6366F1)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _actionBtn(
                      'REJECT',
                      const Color(0xFFEF4444),
                      () => _updateApplicationStatus(app['id'], 'Rejected'),
                      status == 'Rejected',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionBtn(
                      'ACCEPT',
                      const Color(0xFF10B981),
                      () => _updateApplicationStatus(app['id'], 'Accepted'),
                      status == 'Accepted' || status == 'Active',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap, bool active) {
    return GestureDetector(
      onTap: active ? null : onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: active ? color : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescription(Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('ABOUT THE ROLE'),
          const SizedBox(height: 12),
          Text(
            widget.posting['about'] ?? 'No description provided.',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          _sectionTitle('KEY RESPONSIBILITIES'),
          const SizedBox(height: 12),
          ...((widget.posting['responsibilities'] as List? ?? []).map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(child: Text(r.toString(), style: const TextStyle(color: Color(0xFF64748B), fontSize: 14))),
              ],
            ),
          ))),
          const SizedBox(height: 32),
          Row(
            children: [
              _infoTile('STIPEND', '₹${widget.posting['stipend']}/mo'),
              const SizedBox(width: 16),
              _infoTile('DURATION', '${widget.posting['duration']} Months'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'active':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'under review':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6366F1);
    }
  }

  Widget _statusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'N/A';
    try {
      final date = DateTime.parse(value.toString());
      final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return value.toString();
    }
  }
}

class _DotGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => LinearGradient(
        colors: [Colors.white, Colors.white.withValues(alpha: 0.3), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect),
      child: CustomPaint(painter: _DotPainter()),
    );
  }
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 30) {
      for (double j = 0; j < size.height; j += 30) {
        canvas.drawCircle(Offset(i, j), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
