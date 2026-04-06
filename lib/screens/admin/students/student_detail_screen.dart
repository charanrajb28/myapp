import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_student_screen.dart';

class StudentDetailScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String collegeId;
  final String status;
  final String department;
  final String company;

  StudentDetailScreen({
    Key? key,
    required this.studentId,
    required this.studentName,
    required this.collegeId,
    required this.status,
    required this.department,
    required this.company,
  }) : super(key: key);

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  int _activeTabIndex = 0;
  bool _isBlacklisted = false;
  bool _isDeleting = false;
  bool _isBlacklisting = false;
  bool _isLoadingData = true;

  Map<String, dynamic>? _studentData;
  List<Map<String, dynamic>> _pastInternships = [];
  List<Map<String, dynamic>> _currentInternships = [];
  List<Map<String, dynamic>> _appliedInternships = [];

  @override
  void initState() {
    super.initState();
    _fetchStudentAdditionalData();
  }

  Future<void> _fetchStudentAdditionalData() async {
    try {
      // 1. Fetch Full Student Info
      final studentRes = await Supabase.instance.client
          .from('students')
          .select('*')
          .eq('id', widget.studentId)
          .single();
      
      // 2. Fetch All Applications (Applied, Active, Completed)
      final appsRes = await Supabase.instance.client
          .from('applications')
          .select('*, internships(*, companies(*))')
          .eq('student_id', widget.studentId);
      
      final List<Map<String, dynamic>> apps = List<Map<String, dynamic>>.from(appsRes);

      if (mounted) {
        setState(() {
          _studentData = studentRes;
          _isBlacklisted = studentRes['is_blacklisted'] ?? false;
          _appliedInternships = apps.where((a) => a['status'] == 'Applied' || a['status'] == 'Under Review').toList();
          _currentInternships = apps.where((a) => a['status'] == 'Active').toList();
          _pastInternships = apps.where((a) => a['status'] == 'Completed').toList();
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching student details: $e');
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _toggleBlacklist() async {
    setState(() => _isBlacklisting = true);
    try {
      await Supabase.instance.client
          .from('students')
          .update({'is_blacklisted': !_isBlacklisted})
          .eq('id', widget.studentId);
      
      if (mounted) {
        setState(() {
          _isBlacklisted = !_isBlacklisted;
          _isBlacklisting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isBlacklisted ? 'Student Blacklisted' : 'Student Whitelisted'), backgroundColor: _isBlacklisted ? Colors.black : Colors.green)
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isBlacklisting = false);
    }
  }

  Future<void> _deleteStudent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student?'),
        content: const Text('This will permanently remove the student profile and the associated Auth account. This action is irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    try {
      // Note: We delete from 'users' (public) which handles 'students' via CASCADE. 
      // Auth deletion requires admin API but we assume a trigger or direct access for MVP.
      final studentRes = await Supabase.instance.client
          .from('students')
          .select('user_id')
          .eq('id', widget.studentId)
          .single();
      
      await Supabase.instance.client
          .from('users')
          .delete()
          .eq('id', studentRes['user_id']);
      
      if (mounted) {
        Navigator.pop(context, true); // Pop with refresh signal
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student Deleted Successfully')));
      }
    } catch (e) {
      if (mounted) setState(() => _isDeleting = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    // Dynamic mapping back to database fields
    final studentName = _studentData?['name'] ?? widget.studentName;
    final collegeId = _studentData?['college'] ?? widget.collegeId;
    final department = _studentData?['department'] ?? widget.department;
    final semester = _studentData?['semester'] ?? 'Semester Not Set';
    final status = widget.status;
    final company = widget.company;

    final isAlert = status == 'Red Alert';
    final isUnassigned = _currentInternships.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Student Profile',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            )),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF64748B)),
            onPressed: () async {
              if (_studentData != null) {
                // Ensure AddStudentScreen is imported
                // (Already imported or will be handled by auto-imports in local dev)
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddStudentScreen(student: _studentData)),
                );
                if (result == true) {
                  _fetchStudentAdditionalData();
                }
              }
            },
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: Icon(
              _isBlacklisted ? Icons.block_flipped : Icons.block_rounded,
              color: _isBlacklisted ? Colors.red : const Color(0xFF64748B),
            ),
            onPressed: _isBlacklisting ? null : _toggleBlacklist,
            tooltip: _isBlacklisted ? 'Whitelist' : 'Blacklist',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: _isDeleting ? null : _deleteStudent,
            tooltip: 'Delete Profile',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 750;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Identity Card ──
                Container(
                  padding: EdgeInsets.all(isMobile ? 20 : 32),
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: isAlert ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                        foregroundColor: isAlert ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                        radius: isMobile ? 32 : 40,
                        child: Text(
                          studentName.substring(0, 1),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 22 : 28),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                Text(
                                  studentName,
                                  style: TextStyle(
                                    fontSize: isMobile ? 20 : 26,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                _buildStatusBadge(status),
                                if (_isBlacklisted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('BLACKLISTED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                                    const SizedBox(width: 6),
                                    Text(
                                      semester,
                                      style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.school_outlined, size: 16, color: Color(0xFF64748B)),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        department,
                                        style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                // ── Interactive Scrollable Navigation Tabs ──
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTab('Overview', 0),
                      const SizedBox(width: 12),
                      _buildTab('Applications', 1),
                      const SizedBox(width: 12),
                      _buildTab('Documents', 2),
                      const SizedBox(width: 12),
                      _buildTab('Past Internships', 3),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── State-Based Content Layout ──
                if (_activeTabIndex == 0) ...[
                  // ── Responsive Split Layout for Details ──
                  if (isMobile) ...[
                    _buildCurrentInternshipCard(company, isUnassigned, isMobile),
                    const SizedBox(height: 24),
                    _buildAcademicProfileCard(isMobile, department),
                    const SizedBox(height: 24),
                    _buildPersonalDetailsCard(isMobile, studentName),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildCurrentInternshipCard(company, isUnassigned, isMobile),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              _buildAcademicProfileCard(isMobile, department),
                              const SizedBox(height: 24),
                              _buildPersonalDetailsCard(isMobile, studentName),
                            ],
                          ),
                        ),
                    ],
                  ),
                ]
              ] else if (_activeTabIndex == 1) ...[
                _buildApplicationsTab(isMobile),
              ] else if (_activeTabIndex == 2) ...[
                _buildDocumentsTab(isMobile),
              ] else if (_activeTabIndex == 3) ...[
                _buildPastInternshipsTab(isMobile),
              ] else ...[
                _buildComingSoonPlaceholder(_activeTabIndex),
              ]
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isActive = _activeTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0F172A) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF64748B),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonPlaceholder(int tabIndex) {
    final tabNames = ['Overview', 'Applications', 'Documents', 'Past Internships'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.construction_rounded, size: 48, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          Text(
            '${tabNames[tabIndex]} content coming soon',
            style: const TextStyle(fontSize: 16, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsTab(bool isMobile) {
    if (_isLoadingData) return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
    if (_appliedInternships.isEmpty) return _buildComingSoonPlaceholder(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _appliedInternships.map((app) {
        final intern = app['internships'] ?? {};
        final comp = intern['companies'] ?? {};
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildApplicationCard(
            isMobile: isMobile,
            company: comp['name'] ?? 'Unknown Company',
            role: intern['role'] ?? 'Intern Role',
            status: app['status'] ?? 'Pending',
            date: 'Applied ${app['created_at'].substring(0, 10)}',
          ),
        );
      }).toList(),
    );
  }

  Widget _buildApplicationCard({
    required bool isMobile,
    required String company,
    required String role,
    required String status,
    required String date,
  }) {
    Color statusColor;
    Color statusBgColor;
    Color statusBorderColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'interview':
        statusColor = const Color(0xFFD97706); // Amber
        statusBgColor = const Color(0xFFFEF3C7);
        statusBorderColor = const Color(0xFFFDE68A);
        statusIcon = Icons.calendar_month_outlined;
        break;
      case 'pending':
        statusColor = const Color(0xFF2563EB); // Blue
        statusBgColor = const Color(0xFFEFF6FF);
        statusBorderColor = const Color(0xFFBFDBFE);
        statusIcon = Icons.schedule_rounded;
        break;
      case 'rejected':
        statusColor = const Color(0xFFDC2626); // Red
        statusBgColor = const Color(0xFFFEF2F2);
        statusBorderColor = const Color(0xFFFECACA);
        statusIcon = Icons.cancel_outlined;
        break;
      case 'accepted':
        statusColor = const Color(0xFF16A34A); // Green
        statusBgColor = const Color(0xFFF0FDF4);
        statusBorderColor = const Color(0xFFBBF7D0);
        statusIcon = Icons.check_circle_outline;
        break;
      default:
        statusColor = const Color(0xFF64748B);
        statusBgColor = const Color(0xFFF1F5F9);
        statusBorderColor = const Color(0xFFE2E8F0);
        statusIcon = Icons.info_outline;
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business_center_rounded, color: Color(0xFF0F172A), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      company,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusBorderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusBorderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 6),
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  Text(
                    date,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('View Details', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildDocumentsTab(bool isMobile) {
    final List<dynamic> docUrls = _studentData?['document_urls'] ?? [];
    
    if (docUrls.isEmpty) return _buildComingSoonPlaceholder(2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...List.generate(docUrls.length, (index) {
          final rawDoc = docUrls[index];
          final Map<String, dynamic> doc = rawDoc is Map<String, dynamic>
              ? rawDoc
              : rawDoc is Map
                  ? rawDoc.map((key, value) => MapEntry(key.toString(), value))
                  : {
                      'name': 'Student Document ${index + 1}',
                      'url': rawDoc.toString(),
                    };
          final url = doc['url']?.toString() ?? '';
          final name = doc['name']?.toString().trim().isNotEmpty == true
              ? doc['name'].toString().trim()
              : 'Student Document ${index + 1}';
          final String extension = url.split('.').last.toUpperCase().split('?').first;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildDocumentTile(
              title: name,
              date: 'Profile Attachment',
              type: extension.length > 4 ? 'DOC' : extension,
              status: 'Verified',
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDocumentTile({
    required String title,
    required String date,
    required String type,
    required String status,
  }) {
    bool isActionRequired = status == 'Action Required' || status == 'Pending Signature';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActionRequired ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(date, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    const Text('•', style: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isActionRequired ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActionRequired ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.download_rounded, color: Color(0xFF64748B)),
            tooltip: 'Download',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.visibility_outlined, color: Color(0xFF64748B)),
            tooltip: 'View',
          ),
        ],
      ),
    );
  }

  Widget _buildPastInternshipsTab(bool isMobile) {
    if (_isLoadingData) return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
    if (_pastInternships.isEmpty) return _buildComingSoonPlaceholder(3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _pastInternships.map((app) {
        final intern = app['internships'] ?? {};
        final comp = intern['companies'] ?? {};
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildPastInternshipCard(
            isMobile: isMobile,
            company: comp['name'] ?? 'Unknown',
            role: intern['role'] ?? 'Role',
            duration: '${app['start_date'] ?? "?"} - ${app['end_date'] ?? "?"}',
            rating: 4.5,
            managerName: app['mentor_name'] ?? 'Mentor',
            feedback: 'Completed Internship.',
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPastInternshipCard({
    required bool isMobile,
    required String company,
    required String role,
    required String duration,
    required double rating,
    required String managerName,
    required String feedback,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.history_rounded, color: Color(0xFF64748B), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(role, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text(company, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(rating.toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text(duration, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text(managerName, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.format_quote_rounded, size: 16, color: Color(0xFF94A3B8)),
                    SizedBox(width: 6),
                    Text('Final Review', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(feedback, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentInternshipCard(String fallbackCompany, bool isUnassignedShortcut, bool isMobile) {
    final hasCurrent = _currentInternships.isNotEmpty;
    final currentApp = hasCurrent ? _currentInternships.first : null;
    final intern = currentApp?['internships'] ?? {};
    final comp = intern['companies'] ?? {};
    
    final companyName = hasCurrent ? (comp['name'] ?? 'Company') : fallbackCompany;
    final roleName = hasCurrent ? (intern['role'] ?? 'Intern Role') : 'Not Assigned';
    final isUnassigned = !hasCurrent && isUnassignedShortcut;

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Assignment',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 20),
          if (isUnassigned)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF64748B)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This student hasn\'t been assigned an active internship yet.',
                      style: TextStyle(color: Color(0xFF64748B), height: 1.4),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.domain_rounded, color: Color(0xFF0F172A), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companyName,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        roleName,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 32,
              runSpacing: 16,
              children: [
                _buildInfoColumn('Start Date', currentApp?['start_date'] ?? 'TBD'),
                _buildInfoColumn('Mentor', currentApp?['mentor_name'] ?? 'Unassigned'),
                _buildInfoColumn('Status', hasCurrent ? 'ACTIVE' : 'IDLE'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAcademicProfileCard(bool isMobile, String department) {
    final gpa = _studentData?['gpa']?.toString() ?? 'N/A';
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Academic Profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 24),
          _buildInfoRow(Icons.school_outlined, 'Degree Program', 'B.Tech - $department'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.history_edu_outlined, 'Current Status', 'Enrolled'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.grade_outlined, 'Cumulative GPA', '$gpa / 4.0'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.calendar_month_outlined, 'Joined Date', _studentData?['created_at']?.toString().substring(0, 10) ?? 'TBD'),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsCard(bool isMobile, String studentName) {
    final resumeUrl = _studentData?['resume_url'];

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 24),
          _buildInfoRow(Icons.badge_outlined, 'Enrollment ID', _studentData?['enrollment_id'] ?? 'N/A'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.email_outlined, 'Contact Email', _studentData?['contact_email'] ?? 'Not Given'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.phone_outlined, 'Phone Number', _studentData?['phone_number'] ?? 'N/A'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.escalator_warning_outlined, 'Parent Contact', _studentData?['parent_contact'] ?? 'N/A'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.alternate_email_outlined, 'Parent Email', _studentData?['parent_email'] ?? 'N/A'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.location_on_outlined, 'City Location', 'Bangalore'),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: resumeUrl != null ? () {
              // Future: launch resumeUrl
            } : null,
            icon: Icon(resumeUrl != null ? Icons.description_outlined : Icons.file_present_outlined, size: 18),
            label: Text(resumeUrl != null ? 'View Resume' : 'Resume Not Uploaded', style: const TextStyle(fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: resumeUrl != null ? const Color(0xFF0F172A) : Colors.grey,
              minimumSize: const Size(double.infinity, 48),
              side: BorderSide(color: resumeUrl != null ? const Color(0xFFE2E8F0) : Colors.grey.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A), fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    if (status == 'Red Alert') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFDC2626)),
            SizedBox(width: 4),
            Text('RED ALERT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFDC2626))),
          ],
        ),
      );
    } else if (status == 'Unassigned') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text('UNASSIGNED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: const Text('ACTIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF16A34A))),
      );
    }
  }

  Widget _buildReportListTile(String title, String date, bool isSubmitted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isSubmitted ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isSubmitted ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          Text(
            date,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSubmitted ? const Color(0xFF64748B) : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }
}
