import 'package:flutter/material.dart';

class StudentDetailScreen extends StatefulWidget {
  final String studentName;
  final String collegeId;
  final String status;
  final String department;
  final String company;

  const StudentDetailScreen({
    super.key,
    required this.studentName,
    required this.collegeId,
    required this.status,
    required this.department,
    required this.company,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  int _activeTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final studentName = widget.studentName;
    final collegeId = widget.collegeId;
    final status = widget.status;
    final department = widget.department;
    final company = widget.company;

    final isAlert = status == 'Red Alert';
    final isUnassigned = status == 'Unassigned';

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
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {},
            tooltip: 'Edit Profile',
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
                                    const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF64748B)),
                                    const SizedBox(width: 6),
                                    Text(
                                      collegeId,
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
                      _buildTab('Check-Ins & Reports', 2),
                      const SizedBox(width: 12),
                      _buildTab('Documents', 3),
                      const SizedBox(width: 12),
                      _buildTab('Past Internships', 4),
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
                _buildCheckInsTab(isMobile),
              ] else if (_activeTabIndex == 3) ...[
                _buildDocumentsTab(isMobile),
              ] else if (_activeTabIndex == 4) ...[
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
    final tabNames = ['Overview', 'Applications', 'Check-Ins & Reports', 'Documents', 'Past Internships'];
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildApplicationCard(
          isMobile: isMobile,
          company: 'TechFlow Inc.',
          role: 'Software Engineering Intern',
          status: 'Interview',
          date: 'Applied Oct 12, 2025',
        ),
        const SizedBox(height: 16),
        _buildApplicationCard(
          isMobile: isMobile,
          company: 'DataDynamics',
          role: 'Data Science Intern',
          status: 'Pending',
          date: 'Applied Oct 15, 2025',
        ),
        const SizedBox(height: 16),
        _buildApplicationCard(
          isMobile: isMobile,
          company: 'CloudScale Systems',
          role: 'Backend Developer Intern',
          status: 'Rejected',
          date: 'Applied Sept 28, 2025',
        ),
      ],
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

  Widget _buildCheckInsTab(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCheckInCard(
          isMobile: isMobile,
          week: 'Week 12',
          date: 'Oct 24, 2026',
          status: 'Submitted',
          summary: 'Completed integration of the payment gateway API. Faced some issues with webhooks but resolved them. Setting up unit tests next week.',
          managerFeedback: 'Good progress. Ensure the test coverage is above 80%.',
        ),
        const SizedBox(height: 16),
        _buildCheckInCard(
          isMobile: isMobile,
          week: 'Week 11',
          date: 'Oct 17, 2026',
          status: 'Submitted',
          summary: 'Worked on database scheme migration for the new feature. Everything is deployed to staging.',
          managerFeedback: 'Approved.',
        ),
        const SizedBox(height: 16),
        _buildCheckInCard(
          isMobile: isMobile,
          week: 'Week 10',
          date: 'Oct 10, 2026',
          status: 'Missed',
          summary: '',
          managerFeedback: '',
        ),
      ],
    );
  }

  Widget _buildCheckInCard({
    required bool isMobile,
    required String week,
    required String date,
    required String status,
    required String summary,
    required String managerFeedback,
  }) {
    final isMissed = status.toLowerCase() == 'missed';

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isMissed ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      week,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    date,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isMissed ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isMissed ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMissed ? Icons.cancel_rounded : Icons.check_circle_rounded,
                      size: 14,
                      color: isMissed ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isMissed ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isMissed) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 16),
            const Text(
              'Student Summary',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
            Text(
              summary,
              style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.record_voice_over_outlined, size: 16, color: Color(0xFF64748B)),
                      SizedBox(width: 6),
                      Text(
                        'Manager Feedback',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    managerFeedback,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w500, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('View Full Report', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDocumentTile(
          title: 'Student Resume (Updated)',
          date: 'Uploaded Oct 01, 2026',
          type: 'PDF',
          status: 'Verified',
        ),
        const SizedBox(height: 12),
        _buildDocumentTile(
          title: 'TechFlow Offer Letter',
          date: 'Uploaded Sept 10, 2026',
          type: 'PDF',
          status: 'Verified',
        ),
        const SizedBox(height: 12),
        _buildDocumentTile(
          title: 'NDA Agreement',
          date: 'Uploaded Sept 12, 2026',
          type: 'PDF',
          status: 'Pending Signature',
        ),
        const SizedBox(height: 12),
        _buildDocumentTile(
          title: 'Mid-Term Evaluation Form',
          date: 'Uploaded Nov 15, 2026',
          type: 'DOCX',
          status: 'Action Required',
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPastInternshipCard(
          isMobile: isMobile,
          company: 'Acme Corp',
          role: 'Frontend Developer Intern',
          duration: 'May 2025 - Aug 2025',
          rating: 4.8,
          managerName: 'Jane Smith',
          feedback: 'Outstanding performer. Mastered React quickly and delivered a critical dashboard feature ahead of schedule.',
        ),
        const SizedBox(height: 16),
        _buildPastInternshipCard(
          isMobile: isMobile,
          company: 'Startup Incubator Labs',
          role: 'UI/UX Design Intern',
          duration: 'Jan 2025 - Apr 2025',
          rating: 4.2,
          managerName: 'Alex Johnson',
          feedback: 'Creative and eager to learn. Needs to work slightly on communication during cross-team alignment, but excellent design skills.',
        ),
      ],
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

  Widget _buildCurrentInternshipCard(String company, bool isUnassigned, bool isMobile) {
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
                border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.none),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF64748B)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This student hasn\'t been assigned an internship yet or hasn\'t applied.',
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
                         company,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Software Engineering Intern',
                        style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
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
            // Use Wrap to cleanly flow statistics safely onto a second row on extremely narrow mobile devices.
            Wrap(
              spacing: 32,
              runSpacing: 16,
              children: [
                _buildInfoColumn('Start Date', 'Sept 1, 2026'),
                _buildInfoColumn('Duration', '6 Months'),
                _buildInfoColumn('Reporting Status', 'Active'),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Recent Reports',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 16),
            _buildReportListTile('Week 12 Report', 'Submitted Oct 24', true),
            const SizedBox(height: 8),
            _buildReportListTile('Week 11 Report', 'Submitted Oct 17', true),
            const SizedBox(height: 8),
            _buildReportListTile('Week 10 Report', 'Missed', false),
          ],
        ],
      ),
    );
  }

  Widget _buildAcademicProfileCard(bool isMobile, String department) {
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
          _buildInfoRow(Icons.history_edu_outlined, 'Current Semester', '6th Semester (Year 3)'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.grade_outlined, 'Cumulative GPA', '3.8 / 4.0'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.calendar_month_outlined, 'Expected Graduation', 'May 2027'),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsCard(bool isMobile, String studentName) {
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
          _buildInfoRow(Icons.email_outlined, 'Email', '${studentName.toLowerCase().replaceAll(' ', '.')}@college.edu'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.phone_outlined, 'Phone', '+1 (555) 019-2026'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.cake_outlined, 'DOB', 'May 12, 2004'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.home_outlined, 'Home City', 'San Francisco, CA'),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.description_outlined, size: 18),
            label: const Text('View Resume', style: TextStyle(fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
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
