import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackModel {
  final String id;
  final String studentName;
  final String companyName;
  final String companyId;
  final String type; // 'Compliment', 'Complaint', 'Suggestion', 'Final Feedback'
  final String comment;
  final DateTime date;

  FeedbackModel({
    required this.id,
    required this.studentName,
    required this.companyName,
    required this.companyId,
    required this.type,
    required this.comment,
    required this.date,
  });
}

class AdminFeedbacksScreen extends StatefulWidget {
  const AdminFeedbacksScreen({super.key});

  @override
  State<AdminFeedbacksScreen> createState() => _AdminFeedbacksScreenState();
}

class _AdminFeedbacksScreenState extends State<AdminFeedbacksScreen> {
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
      final client = Supabase.instance.client;
      if (client.auth.currentUser == null) {
        // Mock data
        _internships = [
          {
            'id': 'intern-1',
            'role': 'Full Stack Developer',
            'company_id': 'comp-1',
            'brand_color': '#3B82F6',
            'logo_initial': 'T',
            'companies': {'name': 'TechCorp Solutions'},
          },
          {
            'id': 'intern-2',
            'role': 'Software Engineer Intern',
            'company_id': 'comp-2',
            'brand_color': '#8B5CF6',
            'logo_initial': 'G',
            'companies': {'name': 'Google'},
          },
          {
            'id': 'intern-3',
            'role': 'Product Design Intern',
            'company_id': 'comp-3',
            'brand_color': '#EC4899',
            'logo_initial': 'M',
            'companies': {'name': 'Meta'},
          },
        ];
      } else {
        final res = await client
            .from('internships')
            .select('id, role, company_id, brand_color, logo_initial, companies(name)')
            .order('created_at', ascending: false);
        _internships = List<Map<String, dynamic>>.from(res ?? []);
      }
    } catch (e) {
      debugPrint('Error fetching internships for feedbacks: $e');
      _internships = [];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Student Feedbacks',
            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _internships.isEmpty
              ? const _EmptyInternshipsState()
              : RefreshIndicator(
                  onRefresh: _fetchInternships,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    itemCount: _internships.length,
                    itemBuilder: (context, index) {
                      final intern = _internships[index];
                      final role = intern['role'] ?? 'Internship Role';
                      final companyName = intern['companies']?['name'] ?? 'Partner Company';
                      final brandColor = _parseColor(intern['brand_color']);
                      final logoInitial = intern['logo_initial'] ?? companyName[0].toUpperCase();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
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
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminInternshipFeedbackDetailScreen(
                                    companyId: intern['company_id']?.toString() ?? '',
                                    companyName: companyName,
                                    roleTitle: role,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: brandColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        logoInitial,
                                        style: TextStyle(
                                          color: brandColor,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
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
                                          role,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F172A),
                                            fontSize: 15,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          companyName,
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _EmptyInternshipsState extends StatelessWidget {
  const _EmptyInternshipsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(Icons.work_off_rounded, size: 48, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 24),
          const Text('No Internships Listed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          const Text("No internships are currently registered in the database.", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class AdminInternshipFeedbackDetailScreen extends StatefulWidget {
  final String companyId;
  final String companyName;
  final String roleTitle;

  const AdminInternshipFeedbackDetailScreen({
    super.key,
    required this.companyId,
    required this.companyName,
    required this.roleTitle,
  });

  @override
  State<AdminInternshipFeedbackDetailScreen> createState() => _AdminInternshipFeedbackDetailScreenState();
}

class _AdminInternshipFeedbackDetailScreenState extends State<AdminInternshipFeedbackDetailScreen> {
  bool _isLoading = true;
  List<FeedbackModel> _feedbacks = [];

  @override
  void initState() {
    super.initState();
    _fetchFeedbacks();
  }

  Future<void> _fetchFeedbacks() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser == null) {
        final now = DateTime.now();
        final allMock = [
          FeedbackModel(
            id: 'fb-1',
            studentName: 'Alex Guest',
            companyName: 'TechCorp Solutions',
            companyId: 'comp-1',
            type: 'Compliment',
            comment: 'The mentorship program has been exceptionally well-structured and I have learned a lot about full-stack engineering.',
            date: now.subtract(const Duration(hours: 2)),
          ),
          FeedbackModel(
            id: 'fb-2',
            studentName: 'Sarah Chen',
            companyName: 'Google',
            companyId: 'comp-2',
            type: 'Compliment',
            comment: 'Thoroughly enjoying my internship. The tooling and team support are second to none!',
            date: now.subtract(const Duration(days: 1, hours: 3)),
          ),
          FeedbackModel(
            id: 'fb-3',
            studentName: 'Michael Vance',
            companyName: 'Meta',
            companyId: 'comp-3',
            type: 'Suggestion',
            comment: 'Would love to see more internal learning modules made available early in the internship.',
            date: now.subtract(const Duration(days: 2, hours: 5)),
          ),
        ];
        _feedbacks = allMock.where((f) => f.companyId == widget.companyId).toList();
      } else {
        final res = await client
            .from('feedbacks')
            .select('*, students(name), companies(name)')
            .eq('company_id', widget.companyId)
            .order('created_at', ascending: false);

        _feedbacks = (res as List).map((f) {
          return FeedbackModel(
            id: f['id'].toString(),
            studentName: f['students']?['name'] ?? 'Unknown Student',
            companyName: f['companies']?['name'] ?? 'Unknown Company',
            companyId: f['company_id']?.toString() ?? '',
            type: f['type'] ?? 'Suggestion',
            comment: f['comment'] ?? '',
            date: DateTime.tryParse(f['created_at'].toString()) ?? DateTime.now(),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching feedbacks for detail view: $e');
      _feedbacks = [];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final compliments = _feedbacks.where((f) => f.type.toLowerCase() == 'compliment').toList();
    final complaints = _feedbacks.where((f) => f.type.toLowerCase() == 'complaint').toList();
    final suggestions = _feedbacks.where((f) => f.type.toLowerCase() == 'suggestion').toList();
    final finalFeedbacks = _feedbacks.where((f) => f.type.toLowerCase() == 'final feedback').toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.companyName} Feedbacks',
                style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 16),
              ),
              Text(
                widget.roleTitle,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
          bottom: const TabBar(
            labelColor: Color(0xFF0F172A),
            unselectedLabelColor: Color(0xFF64748B),
            indicatorColor: Color(0xFF0F172A),
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            tabs: [
              Tab(text: 'Compliments'),
              Tab(text: 'Complaints'),
              Tab(text: 'Suggestions'),
              Tab(text: 'Final Feedback'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _FeedbackCategoryList(feedbacks: compliments, category: 'Compliments', icon: Icons.favorite_rounded, color: const Color(0xFF10B981)),
                  _FeedbackCategoryList(feedbacks: complaints, category: 'Complaints', icon: Icons.warning_rounded, color: const Color(0xFFEF4444)),
                  _FeedbackCategoryList(feedbacks: suggestions, category: 'Suggestions', icon: Icons.lightbulb_rounded, color: const Color(0xFFF59E0B)),
                  _FeedbackCategoryList(feedbacks: finalFeedbacks, category: 'Final Feedbacks', icon: Icons.assignment_turned_in_rounded, color: const Color(0xFF3B82F6)),
                ],
              ),
      ),
    );
  }
}

class _FeedbackCategoryList extends StatelessWidget {
  final List<FeedbackModel> feedbacks;
  final String category;
  final IconData icon;
  final Color color;

  const _FeedbackCategoryList({
    required this.feedbacks,
    required this.category,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (feedbacks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 16),
            Text(
              'No $category Received',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            Text(
              'No feedback is currently available in this category.',
              style: TextStyle(color: const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: feedbacks.length,
      itemBuilder: (context, index) {
        final fb = feedbacks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fb.studentName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        Text(DateFormat('MMMM dd, yyyy • hh:mm a').format(fb.date),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Text(
                  '"${fb.comment}"',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF334155),
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
