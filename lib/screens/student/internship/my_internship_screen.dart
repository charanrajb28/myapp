import 'package:flutter/material.dart';
import '../../../models/internship.dart';
import 'internship_opportunity_detail_screen.dart';
import '../student_portal_repository.dart';

const List<StudentInternship> kStudentInternships = [
  StudentInternship(
    applicationId: 'APP-INT-2024-001',
    id: 'INT-2024-001',
    company: 'TechFlow Inc.',
    role: 'Software Engineering Intern',
    department: 'Backend Engineering',
    location: 'San Francisco, CA',
    startDate: 'Sep 1, 2024',
    endDate: 'Nov 30, 2024',
    deadline: '25 Aug 2024',
    progress: 0.67,
    daysLeft: 42,
    status: 'Active',
    internshipStatus: 'ACTIVE',
    brandColor: const Color(0xFF3B82F6),
    logoInitial: 'T',
    stipend: '₹15,000 / month',
    mentorName: 'Ravi Krishnan',
    mentorEmail: 'r.kris@techflow.io',
    offerLetterId: 'TF-2024-INT-0092',
    about:
        'Builds enterprise-grade cloud software used by over 2 million professionals worldwide.',
  ),
  StudentInternship(
    applicationId: 'APP-INT-2023-007',
    id: 'INT-2023-007',
    company: 'Nexus Robotics',
    role: 'Robotics Engineering Intern',
    department: 'Hardware Systems',
    location: 'Boston, MA',
    startDate: 'Jan 1, 2025',
    endDate: 'Jun 30, 2025',
    deadline: '20 Dec 2024',
    progress: 0.15,
    daysLeft: 124,
    status: 'Active',
    internshipStatus: 'ACTIVE',
    brandColor: const Color(0xFFF59E0B),
    logoInitial: 'N',
    stipend: '₹18,000 / month',
    mentorName: 'Sarah Jenkins',
    mentorEmail: 's.jenkins@nexus.io',
    offerLetterId: 'NX-2025-INT-0012',
    about:
        'Design and build the future of automated logistics and industrial bots.',
  ),
];


const List<InternshipOpportunity> kAvailableInternships = [
  InternshipOpportunity(
    id: 'OPP-101',
    company: 'Stark Industries',
    role: 'AI Research Intern',
    industry: 'Advanced Tech',
    location: 'New York, NY',
    stipend: '₹25,000 / month',
    brandColor: const Color(0xFFEF4444),
    logoInitial: 'S',
    about: 'Join our cutting-edge AI labs to work on next-gen security and robotics.',
    responsibilities: const [
      'Assist in training deep learning models',
      'Optimize neural network architectures',
      'Process large-scale datasets for computer vision',
    ],
    requirements: const [
      'Strong Python programming skills',
      'Knowledge of TensorFlow or PyTorch',
      'Pursuing degree in CS or related field',
    ],
  ),
  InternshipOpportunity(
    id: 'OPP-102',
    company: 'Nexus Robotics',
    role: 'Robotics Engineer',
    industry: 'Mechanical Eng.',
    location: 'Boston, MA',
    stipend: '₹18,000 / month',
    brandColor: const Color(0xFFF59E0B),
    logoInitial: 'N',
    about: 'Design and build the future of automated logistics and industrial bots.',
    responsibilities: const [
      'Design mechanical components using CAD',
      'Perform stress testing on robotic arms',
      'Collaborate with the firmware team',
    ],
    requirements: const [
      'Proficiency in SolidWorks or AutoCAD',
      'Understanding of kinematics and dynamics',
      'Hands-on experience with hardware',
    ],
  ),
  InternshipOpportunity(
    id: 'OPP-103',
    company: 'Cloud9 Systems',
    role: 'Cloud Architect',
    industry: 'Cloud Computing',
    location: 'Seattle, WA',
    stipend: '₹20,000 / month',
    duration: '6 Months',
    brandColor: const Color(0xFF8B5CF6),
    logoInitial: 'C',
    about: 'Scale massive infrastructures using our proprietary serverless stack.',
    responsibilities: const [
      'Maintain reliable cloud architecture',
      'Write scalable backend services',
      'Optimize API performance',
    ],
    requirements: const [
      'AWS or GCP certified is a plus',
      'Strong Golang/Node.js skills',
      'Understanding of Kubernetes',
    ],
  ),
  InternshipOpportunity(
    id: 'OPP-104',
    company: 'Green Horizons',
    role: 'Sustainability Intern',
    industry: 'Renewable Energy',
    location: 'Denver, CO',
    stipend: '₹15,000 / month',
    duration: '4 Months',
    brandColor: const Color(0xFF10B981),
    logoInitial: 'G',
    about: 'Help us innovate in solar lattice designs and wind farm optimization.',
    responsibilities: const [
      'Analyze solar panel efficiency data',
      'Assist in wind turbine site surveys',
      'Draft sustainability impact reports',
    ],
    requirements: const [
      'Degree in Environmental Science or Eng.',
      'Data analysis skills in Excel/Python',
      'Passion for renewable energy',
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────
class MyInternshipScreen extends StatefulWidget {
  const MyInternshipScreen({super.key});

  @override
  State<MyInternshipScreen> createState() => _MyInternshipScreenState();
}

class _MyInternshipScreenState extends State<MyInternshipScreen> {
  final _repository = StudentPortalRepository();
  String _searchQuery = '';
  String _selectedIndustry = 'All';
  bool _isLoading = true;
  List<InternshipOpportunity> _availableInternships = [];
  List<StudentInternship> _studentInternships = [];

  List<InternshipOpportunity> get _filteredInternships {
    return _availableInternships.where((o) {
      final matchesSearch = o.company.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.role.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesIndustry = _selectedIndustry == 'All' || o.industry == _selectedIndustry;
      return matchesSearch && matchesIndustry;
    }).toList();
  }

  String _normalizedStatus(String status) => status.trim().toLowerCase();

  List<StudentInternship> get _ongoing => _studentInternships.where((i) {
        final status = _normalizedStatus(i.status);
        return status == 'applied' || status == 'accepted' || status == 'active';
      }).toList();

  List<StudentInternship> get _active => _studentInternships
      .where((i) => _normalizedStatus(i.status) == 'active')
      .toList();

  List<StudentInternship> get _history => _studentInternships.where((i) {
        final status = _normalizedStatus(i.status);
        return status == 'completed' || status == 'rejected' || status == 'removed';
      }).toList();

  @override
  void initState() {
    super.initState();
    _loadInternshipData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadInternshipData() async {
    setState(() => _isLoading = true);
    try {
      final available = await _repository.fetchAvailableInternships();
      final student = await _repository.fetchStudentInternships();
      if (!mounted) return;
      setState(() {
        _availableInternships = available;
        _studentInternships = student;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load internships: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'Internships',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
            ),
            _applicationsButton(),
          ],
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _exploreTab(),
    );
  }
  Widget _applicationsButton() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _MyApplicationsPage(
              ongoing: _ongoing,
              history: _history,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            const Text(
              'My Applications',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${_ongoing.length + _history.length}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showApplicationsSheet() async {
    var selectedView = 0;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final list = selectedView == 0 ? _ongoing : _history;
            final emptyMsg = selectedView == 0
                ? 'No ongoing applications available'
                : 'No application history available';
            return DraggableScrollableSheet(
              initialChildSize: 0.86,
              minChildSize: 0.55,
              maxChildSize: 0.94,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'My Applications',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _applicationsToggle(
                                  label: 'ONGOING',
                                  count: _ongoing.length,
                                  selected: selectedView == 0,
                                  onTap: () => setModalState(() => selectedView = 0),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _applicationsToggle(
                                  label: 'HISTORY',
                                  count: _history.length,
                                  selected: selectedView == 1,
                                  onTap: () => setModalState(() => selectedView = 1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _applicationsListView(
                          list,
                          emptyMsg: emptyMsg,
                          controller: scrollController,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _applicationsToggle({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
                color: selected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.16)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _applicationsListView(
    List<StudentInternship> list, {
    required String emptyMsg,
    ScrollController? controller,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.work_off_rounded,
                  size: 42,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                emptyMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No related internship data is available for this section yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return _InternshipCard(internship: list[index]);
      },
    );
  }

  Widget _exploreTab() {
    return CustomScrollView(
      slivers: [
        // ── Search & Filter Section ──
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    onSubmitted: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search roles or companies...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              _industryFilter(),
              const SizedBox(height: 16),
            ],
          ),
        ),

        // ── Featured Section ──
        

        // ── Results Header ──
        if (_filteredInternships.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Text(
                    '${_filteredInternships.length} AVAILABLE POSITIONS',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Internship List ──
        _filteredInternships.isEmpty
            ? const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: Color(0xFFE2E8F0)),
                      SizedBox(height: 12),
                      Text(
                        'No opportunities found',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final opportunity = _filteredInternships[index];
                      return _OpportunityListItem(
                        opportunity: opportunity,
                        onApplicationChanged: _loadInternshipData,
                      );
                    },
                    childCount: _filteredInternships.length,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _industryFilter() {
    final industries = ['All', ..._availableInternships.map((o) => o.industry).toSet()];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: industries.map((ind) {
          final isSelected = _selectedIndustry == ind;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(ind),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedIndustry = ind),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF0F172A),
              showCheckmark: false,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _tabBadge(int count, Color color, {bool isActive = false}) {

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: isActive ? Colors.white : color,
        ),
      ),
    );
  }

  Widget _internshipList(List<StudentInternship> list, {required String emptyMsg}) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.work_off_rounded,
                  size: 42,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                emptyMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No related internship data is available for this section yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return _InternshipCard(internship: list[index]);
      },
    );
  }


  Widget _exploreGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        mainAxisExtent: 280,
      ),
      itemCount: _availableInternships.length,
      itemBuilder: (_, i) => _OpportunityCard(opportunity: _availableInternships[i]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
class _OpportunityCard extends StatelessWidget {
  final InternshipOpportunity opportunity;
  const _OpportunityCard({required this.opportunity});

  void _showDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InternshipOpportunityDetailScreen(opportunity: opportunity),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: opportunity.brandColor.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 15)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showDetails(context),
            child: Stack(
              children: [
                // Subtle background decoration
                Positioned(
                  right: -25, top: -25,
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: opportunity.brandColor.withValues(alpha: 0.03),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                
                // Left accent bar
                Positioned(
                  left: 0, top: 0, bottom: 0,
                  child: Container(width: 4, color: opportunity.brandColor),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cleaner Top Section (Logo only on white)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: opportunity.brandColor.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: opportunity.brandColor.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                            border: Border.all(color: opportunity.brandColor.withValues(alpha: 0.1), width: 1),
                          ),
                          child: Center(
                            child: Text(
                              opportunity.logoInitial,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: opportunity.brandColor),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opportunity.company,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.3),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            opportunity.role,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 18),
                          _detailLink(Icons.location_on_rounded, opportunity.location),
                          const SizedBox(height: 8),
                          _detailLink(Icons.payments_rounded, opportunity.stipend),
                          const SizedBox(height: 24),
                          
                          // IMPROVED: VIEW DETAILS BUTTON
                          Container(
                            height: 38,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'VIEW DETAILS',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                                ),
                                const SizedBox(width: 10),
                                Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailLink(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────────
class _InternshipCard extends StatelessWidget {
  final StudentInternship internship;
  const _InternshipCard({required this.internship});

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final String statusLabel;
    final normalizedStatus = internship.status.trim().toLowerCase();
    final bool isActive = normalizedStatus == 'active';
    final bool canOpenDetails = normalizedStatus != 'rejected';

    switch (normalizedStatus) {
      case 'applied':
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'Applied';
        break;
      case 'accepted':
        statusColor = const Color(0xFF2563EB);
        statusLabel = 'Accepted';
        break;
      case 'active':
        statusColor = const Color(0xFF10B981);
        statusLabel = 'Active';
        break;
      case 'completed':
        statusColor = const Color(0xFF3B82F6);
        statusLabel = 'Completed';
        break;
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        statusLabel = 'Rejected';
        break;
      case 'removed':
        statusColor = const Color(0xFF7C3AED);
        statusLabel = 'Removed';
        break;
      default:
        statusColor = const Color(0xFF64748B);
        statusLabel = internship.status;
    }

    return Column(
      children: [
        InkWell(
          onTap: canOpenDetails
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InternshipDetailScreen(internship: internship),
                    ),
                  );
                }
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rejected application details are not accessible.'),
                    ),
                  );
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: internship.brandColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      internship.logoInitial,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: internship.brandColor),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        internship.company,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.2),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        internship.role,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          _metaTag(Icons.calendar_today_rounded, 'Deadline ${internship.deadline}'),
                          if (internship.status == 'Active' && internship.endDate != 'Not set')
                            _metaTag(Icons.flag_rounded, 'Ends ${internship.endDate}')
                          else if (internship.status != 'Active' && internship.endDate != 'Not set')
                            _metaTag(Icons.event_available_rounded, 'Ended ${internship.endDate}'),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel.toUpperCase(),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: statusColor, letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  canOpenDetails ? Icons.chevron_right_rounded : Icons.lock_outline_rounded,
                  color: canOpenDetails
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
      ],
    );
  }

  Widget _metaTag(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}

class _MyApplicationsPage extends StatefulWidget {
  final List<StudentInternship> ongoing;
  final List<StudentInternship> history;

  const _MyApplicationsPage({
    required this.ongoing,
    required this.history,
  });

  @override
  State<_MyApplicationsPage> createState() => _MyApplicationsPageState();
}

class _MyApplicationsPageState extends State<_MyApplicationsPage> {
  int _selectedView = 0;

  @override
  Widget build(BuildContext context) {
    final list = _selectedView == 0 ? widget.ongoing : widget.history;
    final emptyMsg = _selectedView == 0
        ? 'No ongoing applications available'
        : 'No application history available';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Applications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF2F7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _applicationsToggle(
                      label: 'ONGOING',
                      count: widget.ongoing.length,
                      selected: _selectedView == 0,
                      onTap: () => setState(() => _selectedView = 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _applicationsToggle(
                      label: 'HISTORY',
                      count: widget.history.length,
                      selected: _selectedView == 1,
                      onTap: () => setState(() => _selectedView = 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _ApplicationsListView(
              list: list,
              emptyMsg: emptyMsg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _applicationsToggle({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F172A) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF0F172A) : Colors.transparent,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
                color: selected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.16)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationsListView extends StatelessWidget {
  final List<StudentInternship> list;
  final String emptyMsg;

  const _ApplicationsListView({
    required this.list,
    required this.emptyMsg,
  });

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.work_off_rounded,
                  size: 42,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                emptyMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No related internship data is available for this section yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return _InternshipCard(internship: list[index]);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Detail screen (pushed on card tap)
// ─────────────────────────────────────────────────────────────────
class InternshipDetailScreen extends StatelessWidget {
  final StudentInternship internship;
  const InternshipDetailScreen({super.key, required this.internship});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF0F172A),
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                   // Dynamic background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [internship.brandColor.withValues(alpha: 0.8), const Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -60,
                    right: -60,
                    child: Container(
                      width: 250, height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('ACTIVE INTERNSHIP', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          internship.company,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 36),
                    _CompanyProfileCard(internship: internship),
                    const SizedBox(height: 36),
                    _TimelineSectionCard(internship: internship),
                    const SizedBox(height: 36),
                    _AttendanceCalendarCard(internship: internship),
                    const SizedBox(height: 36),
                    _DetailSectionCard(
                      title: 'Role & Department',
                      icon: Icons.badge_rounded,
                      color: internship.brandColor,
                      child: _RoleSection(internship: internship),
                    ),
                    const SizedBox(height: 36),
                    _DetailSectionCard(
                      title: 'Industry Mentor',
                      icon: Icons.person_pin_rounded,
                      color: const Color(0xFF8B5CF6),
                      child: _MentorSection(internship: internship),
                    ),
                    const SizedBox(height: 36),
                    _DetailSectionCard(
                      title: 'Documents',
                      icon: Icons.folder_rounded,
                      color: const Color(0xFFF59E0B),
                      child: const _DocumentsSection(),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyProfileCard extends StatelessWidget {
  final StudentInternship internship;
  const _CompanyProfileCard({required this.internship});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: internship.brandColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    internship.logoInitial,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: internship.brandColor),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      internship.role,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          internship.location,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 20),
          Text(
            internship.about,
            style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.6, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

}


// ─── Timeline card ────────────────────────────────────────────────
class _TimelineSectionCard extends StatelessWidget {
  final StudentInternship internship;
  const _TimelineSectionCard({required this.internship});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text(
              'Program Journey',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3),
            ),
          ]),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _dateLabel('Started', internship.startDate),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                child: Text('${internship.daysLeft} DAYS LEFT', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1)),
              ),
              _dateLabel('Ending', internship.endDate, right: true),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: internship.progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(internship.brandColor),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                internship.status == 'Completed' ? 'Internship Completed' : 'Current Progress',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
              ),
              Text(
                '${(internship.progress * 100).round()}%',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _dateLabel(String label, String date, {bool right = false}) {
    return Column(
      crossAxisAlignment:
          right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600)),
        Text(date,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A))),
      ],
    );
  }
}

// ─── Reusable section card ────────────────────────────────────────
class _DetailSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;
  const _DetailSectionCard(
      {required this.title,
      required this.icon,
      required this.color,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A))),
            ]),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

// ─── Role section ─────────────────────────────────────────────────
class _RoleSection extends StatelessWidget {
  final StudentInternship internship;
  const _RoleSection({required this.internship});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _row(Icons.account_tree_rounded, 'Department', internship.department, const Color(0xFF3B82F6)),
      const SizedBox(height: 16),
      _row(Icons.confirmation_number_rounded, 'ID Number', internship.offerLetterId, const Color(0xFF6366F1)),
      const SizedBox(height: 16),
      _row(Icons.payments_rounded, 'Monthly Stipend', internship.stipend, const Color(0xFF10B981)),
    ]);
  }

  Widget _row(IconData icon, String label, String value, Color color) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A))),
        ]),
      ),
    ]);
  }
}


// ─── Mentor section ───────────────────────────────────────────────
class _MentorSection extends StatelessWidget {
  final StudentInternship internship;
  const _MentorSection({required this.internship});

  @override
  Widget build(BuildContext context) {
    final initials = internship.mentorName
        .split(' ')
        .map((e) => e[0])
        .take(2)
        .join();
    return Row(children: [
      Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(initials,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF8B5CF6),
                  fontSize: 16)),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(internship.mentorName,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text('Senior Engineer — ${internship.department}',
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          _chip(Icons.email_rounded, internship.mentorEmail),
        ]),
      ),
    ]);
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: const Color(0xFF64748B)),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569))),
      ]),
    );
  }
}

// ─── Documents section ────────────────────────────────────────────
class _DocumentsSection extends StatelessWidget {
  const _DocumentsSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No internship documents available.',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}



class _FeaturedCard extends StatelessWidget {
  final InternshipOpportunity opportunity;
  final Future<void> Function() onApplicationChanged;

  const _FeaturedCard({
    required this.opportunity,
    required this.onApplicationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => InternshipOpportunityDetailScreen(opportunity: opportunity),
            ),
          );
          if (changed == true) {
            await onApplicationChanged();
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(Icons.rocket_launch_rounded, size: 80, color: Colors.white.withValues(alpha: 0.05)),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Container(
                         padding: const EdgeInsets.all(6),
                         decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                         child: Text(opportunity.logoInitial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(opportunity.company, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                           Text(opportunity.industry, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.w600)),
                         ],
                       ),
                       const Spacer(),
                       if (opportunity.isApplied == true)
                         _statusBadge(
                           'APPLIED',
                           const Color(0xFF10B981),
                           textColor: Colors.white,
                           backgroundColor: const Color(0xFF10B981),
                         ),
                     ],
                   ),
                  const Spacer(),
                  Text(opportunity.role, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.payments_rounded, size: 12, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      Text(opportunity.stipend, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(
    String label,
    Color color, {
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.7,
          color: textColor ?? color,
        ),
      ),
    );
  }
}

class _OpportunityListItem extends StatelessWidget {
  final InternshipOpportunity opportunity;
  final Future<void> Function() onApplicationChanged;

  const _OpportunityListItem({
    required this.opportunity,
    required this.onApplicationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = opportunity.brandColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final changed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => InternshipOpportunityDetailScreen(opportunity: opportunity),
              ),
            );
            if (changed == true) {
              await onApplicationChanged();
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.10),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: accent.withValues(alpha: 0.14),
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.18),
                          accent.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        opportunity.logoInitial,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    opportunity.company,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    opportunity.role,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF94A3B8),
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (opportunity.isApplied == true)
                              _statusBadge('Applied', const Color(0xFF10B981)),
                            _infoPill(
                              Icons.location_on_rounded,
                              opportunity.location,
                              accent,
                            ),
                            _infoPill(
                              Icons.payments_rounded,
                              opportunity.stipend,
                              accent,
                            ),
                            _infoPill(
                              Icons.event_rounded,
                              opportunity.deadline,
                              accent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accent.withValues(alpha: 0.85)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
          color: color,
        ),
      ),
    );
  }
}

class _AttendanceCalendarCard extends StatelessWidget {
  final StudentInternship internship;
  const _AttendanceCalendarCard({required this.internship});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totalDays = DateTime(now.year, now.month + 1, 0).day;
    final monthLabel = _monthLabel(now);
    final checkinMap = <int, Map<String, dynamic>>{};
    for (final entry in internship.checkins) {
      final parsedDate = DateTime.tryParse(entry['checkin_date']?.toString() ?? '');
      if (parsedDate == null || parsedDate.year != now.year || parsedDate.month != now.month) {
        continue;
      }
      checkinMap[parsedDate.day] = entry;
    }
    final presentCount = checkinMap.values
        .where((entry) => entry['check_in_at'] != null || entry['status']?.toString() == 'Present')
        .length;
    final startDate = _parseDate(internship.startDate);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF3B82F6)),
              SizedBox(width: 8),
              Text(
                'Check-In History',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthLabel,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$presentCount CHECK-INS',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF10B981), letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
              itemCount: totalDays,
              itemBuilder: (context, index) {
                final day = index + 1;
                final date = DateTime(now.year, now.month, day);
                final statusEntry = checkinMap[day];
                Color bgColor = const Color(0xFFF1F5F9);
                Color textColor = const Color(0xFF64748B);
                IconData? icon;

                final hasCheckIn = statusEntry?['check_in_at'] != null;
                final explicitAbsent =
                    statusEntry?['status']?.toString().toLowerCase() == 'absent';
                final isAbsent = explicitAbsent ||
                    _isMissedWorkingDay(
                      date: date,
                      startDate: startDate,
                      statusEntry: statusEntry,
                    );

                if (hasCheckIn) {
                  bgColor = const Color(0xFF10B981).withValues(alpha: 0.12);
                  textColor = const Color(0xFF059669);
                  icon = Icons.check_circle_rounded;
              } else if (isAbsent) {
                bgColor = const Color(0xFFEF4444).withValues(alpha: 0.1);
                textColor = const Color(0xFFDC2626);
                icon = Icons.close_rounded;
              }

              return Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: statusEntry == null
                      ? Text(
                          '$day',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor.withValues(alpha: 0.5)),
                        )
                      : Icon(icon, size: 16, color: textColor),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _legendItem('Present', const Color(0xFF10B981)),
              _legendItem('Absent', const Color(0xFFEF4444)),
              _legendItem('Future / N.A.', const Color(0xFF94A3B8)),
            ],
          ),
        ],
      ),
    );
  }

  bool _isMissedWorkingDay({
    required DateTime date,
    required DateTime? startDate,
    required Map<String, dynamic>? statusEntry,
  }) {
    if (startDate == null) {
      return false;
    }

    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      return false;
    }

    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart =
        DateTime(startDate.year, startDate.month, startDate.day);
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    if (normalizedDate.isBefore(normalizedStart) ||
        normalizedDate.isAfter(normalizedToday)) {
      return false;
    }

    final status = statusEntry?['status']?.toString().toLowerCase();
    final hasCheckIn = statusEntry?['check_in_at'] != null;
    if (hasCheckIn || status == 'present') {
      return false;
    }

    return statusEntry == null || status == 'absent';
  }

  DateTime? _parseDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value == 'Not set' || value == 'TBD') {
      return null;
    }

    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }

    final match = RegExp(r'^(\d{1,2}) ([A-Za-z]{3}) (\d{4})$').firstMatch(value);
    if (match == null) {
      return null;
    }

    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };

    final day = int.tryParse(match.group(1) ?? '');
    final month = months[match.group(2)];
    final year = int.tryParse(match.group(3) ?? '');
    if (day == null || month == null || year == null) {
      return null;
    }

    return DateTime(year, month, day);
  }

  String _monthLabel(DateTime value) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[value.month - 1]} ${value.year}';
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
      ],
    );
  }
}
