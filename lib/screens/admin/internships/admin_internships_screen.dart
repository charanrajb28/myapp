import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../companies/role_detail_screen.dart';

class AdminInternshipsScreen extends StatefulWidget {
  const AdminInternshipsScreen({super.key});

  @override
  State<AdminInternshipsScreen> createState() => _AdminInternshipsScreenState();
}

class _AdminInternshipsScreenState extends State<AdminInternshipsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _internships = [];

  @override
  void initState() {
    super.initState();
    _fetchInternships();
  }

  Future<void> _fetchInternships() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase
          .from('internships')
          .select('*, companies(*), applications(*, students(*))')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _internships = List<Map<String, dynamic>>.from(res ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching internships: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load internships: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF6366F1);
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  Future<void> _updatePostingStatus(String id, String status) async {
    try {
      await Supabase.instance.client
          .from('internships')
          .update({'status': status})
          .eq('id', id);

      if (status == 'INTERVIEWING') {
        // Fetch role and company details to send notification
        final postingRes = await Supabase.instance.client
            .from('internships')
            .select('role, companies(name)')
            .eq('id', id)
            .maybeSingle();

        final roleName = postingRes?['role']?.toString() ?? 'New Internship';
        final companyName = postingRes?['companies']?['name']?.toString() ?? 'Partner Company';

        // Broadcast notification to all students
        final studentsRes = await Supabase.instance.client
            .from('students')
            .select('user_id');

        if (studentsRes is List && studentsRes.isNotEmpty) {
          final notifications = studentsRes.map((s) => {
            'user_id': s['user_id'],
            'title': 'New Internship Available: $roleName',
            'message': '$companyName has posted a new opportunity for "$roleName". Apply now in your Student Portal!',
            'notification_type': 'announcement',
            'is_read': false,
          }).toList();

          await Supabase.instance.client
              .from('student_notifications')
              .insert(notifications);
        }
      }

      _fetchInternships();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'INTERVIEWING' ? 'Posting Approved & Notification Sent to Students!' : 'Posting Rejected.'),
            backgroundColor: status == 'INTERVIEWING' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating posting status: $e');
    }
  }

  Widget _buildRoleList(List<Map<String, dynamic>> roles, String emptyMessage, {bool isReviewTab = false}) {
    if (roles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.work_off_rounded,
                  size: 36,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  fontSize: 15,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'No internship listings match this category at this time.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: roles.length,
      itemBuilder: (context, index) {
        final role = roles[index];
        final company = role['companies'] as Map<String, dynamic>? ?? {};
        final brandColor = _parseColor(role['brand_color'] ?? '#6366F1');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Accent brand color border on left
                  Container(
                    width: 5,
                    color: brandColor,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RoleDetailScreen(
                                  id: role['id']?.toString() ?? '',
                                  title: role['role'] ?? 'Intern Role',
                                  type: role['location'] ?? 'Full-time',
                                  deadline: role['deadline'] ?? 'TBD',
                                  slots: role['vacancies']?.toString() ?? role['total_slots']?.toString() ?? '0',
                                  startDate: role['start_date'] ?? 'TBD',
                                  duration: '${role['duration'] ?? 3} Months',
                                  description: role['about'] ?? 'No description provided.',
                                  responsibilities: List<String>.from(role['responsibilities'] ?? []),
                                  activeDays: List<String>.from(role['active_days'] ?? []),
                                  eligibleDepartments: List<String>.from(role['eligible_departments'] ?? []),
                                  eligibleYears: List<String>.from(role['eligible_years'] ?? []),
                                  stipend: role['stipend']?.toString() ?? '',
                                  location: role['location']?.toString() ?? '',
                                  notes: role['notes']?.toString() ?? '',
                                  status: role['status']?.toString() ?? 'INTERVIEWING',
                                  applicants: (role['applications'] as List? ?? []).map((app) {
                                    final student = app['students'] as Map<String, dynamic>? ?? {};
                                    return {
                                      'name': student['name']?.toString() ?? 'Unknown Student',
                                      'id': student['enrollment_id']?.toString() ?? student['id']?.toString() ?? 'N/A',
                                      'dept': student['department']?.toString() ?? 'CS',
                                      'status': app['status']?.toString() ?? 'Applied',
                                      'application_id': app['id']?.toString() ?? '',
                                      'progress': double.tryParse(app['progress']?.toString() ?? '0') ?? 0.0,
                                      'checkins': app['checkins'] as List? ?? [],
                                    };
                                  }).toList(),
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                              child: Row(
                                children: [
                                  // Left side logo icon representation
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: brandColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        role['logo_initial'] ?? company['name']?[0]?.toUpperCase() ?? 'I',
                                        style: TextStyle(
                                          color: brandColor,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          role['role'] ?? 'Intern Role',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F172A),
                                            fontSize: 14,
                                            letterSpacing: -0.2,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          company['name'] ?? 'Partner Company',
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                role['location'] ?? 'On-site',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF475569),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                role['deadline'] ?? 'No Deadline',
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (isReviewTab) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFFDE68A)),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.rate_review_outlined, size: 10, color: Color(0xFFD97706)),
                                              SizedBox(width: 4),
                                              Text(
                                                'Under Review',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFB45309),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: brandColor.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${role['vacancies'] ?? role['total_slots'] ?? 0} slots',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: brandColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviewRoles = _internships.where((r) {
      final status = (r['status'] as String? ?? 'INTERVIEWING').toUpperCase();
      return status == 'UNDER_REVIEW';
    }).toList();

    final interviewingRoles = _internships.where((r) {
      final status = (r['status'] as String? ?? 'INTERVIEWING').toUpperCase();
      return status == 'INTERVIEWING';
    }).toList();

    final activeRoles = _internships.where((r) {
      final status = (r['status'] as String? ?? 'INTERVIEWING').toUpperCase();
      return status == 'ACTIVE';
    }).toList();

    final closedRoles = _internships.where((r) {
      final status = (r['status'] as String? ?? 'INTERVIEWING').toUpperCase();
      return status == 'CLOSED' || status == 'REJECTED';
    }).toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'Internship Management',
            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            labelColor: const Color(0xFF0F172A),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF0F172A),
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            tabs: [
              Tab(text: 'Review (${reviewRoles.length})'),
              Tab(text: 'Open (${interviewingRoles.length})'),
              Tab(text: 'Ongoing (${activeRoles.length})'),
              Tab(text: 'Past (${closedRoles.length})'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  RefreshIndicator(
                    onRefresh: _fetchInternships,
                    child: _buildRoleList(reviewRoles, 'No Postings Under Review', isReviewTab: true),
                  ),
                  RefreshIndicator(
                    onRefresh: _fetchInternships,
                    child: _buildRoleList(interviewingRoles, 'No Open Positions'),
                  ),
                  RefreshIndicator(
                    onRefresh: _fetchInternships,
                    child: _buildRoleList(activeRoles, 'No Ongoing Internships'),
                  ),
                  RefreshIndicator(
                    onRefresh: _fetchInternships,
                    child: _buildRoleList(closedRoles, 'No Past Internships'),
                  ),
                ],
              ),
      ),
    );
  }
}
