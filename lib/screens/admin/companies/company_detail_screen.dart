import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'role_detail_screen.dart';
import 'add_company_screen.dart';


class CompanyDetailArgs {
  final String id;
  final String name;
  final String industry;
  final String location;
  final int activeInterns;
  final int totalPlacements;
  final int openRoles;
  final double rating;
  final String status;
  final Color logoColor;
  final String logoInitial;
  final String about;
  final bool isBlacklisted;

  const CompanyDetailArgs({
    required this.id, required this.name, required this.industry,
    required this.location, required this.activeInterns,
    required this.totalPlacements, required this.openRoles,
    required this.rating, required this.status,
    required this.logoColor, required this.logoInitial,
    required this.about, required this.isBlacklisted,
  });
}

// ─────────────────────────────────────────────────────────────────
class CompanyDetailScreen extends StatefulWidget {
  final CompanyDetailArgs company;
  const CompanyDetailScreen({super.key, required this.company});

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  int _tabIndex = 0;
  static const _tabs = ['Overview', 'Past Internships', 'Open Roles', 'Documents'];
  
  bool _isLoading = true;
  CompanyDetailArgs? _dynamicCompany;
  List<Map<String, dynamic>> _openRoles = [];
  List<Map<String, dynamic>> _pastRoles = [];
  List<Map<String, dynamic>> _docs = [];

  @override
  void initState() {
    super.initState();
    _fetchCompanyData();
  }

  Future<void> _fetchCompanyData() async {
    try {
      final supabase = Supabase.instance.client;
      
      final companyRes = await supabase
          .from('companies')
          .select('*')
          .eq('id', widget.company.id)
          .single();
          
      final rolesRes = await supabase
          .from('internships')
          .select('*')
          .eq('company_id', widget.company.id);

      if (mounted) {
        setState(() {
          _dynamicCompany = CompanyDetailArgs(
            id: companyRes['id'].toString(),
            name: companyRes['name'] ?? widget.company.name,
            industry: companyRes['industry'] ?? widget.company.industry,
            location: companyRes['location'] ?? widget.company.location,
            activeInterns: widget.company.activeInterns, // Calculated or placeholder
            totalPlacements: widget.company.totalPlacements,
            openRoles: (rolesRes as List).length,
            rating: widget.company.rating,
            status: 'Approved',
            logoColor: widget.company.logoColor,
            logoInitial: widget.company.logoInitial,
            about: companyRes['description'] ?? widget.company.about,
            isBlacklisted: (companyRes['is_blacklisted'] as bool?) ?? false,
          );
          _openRoles = List<Map<String, dynamic>>.from(rolesRes);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching company: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBlacklist() async {
    final c = _dynamicCompany ?? widget.company;
    try {
      await Supabase.instance.client
          .from('companies')
          .update({'is_blacklisted': !c.isBlacklisted})
          .eq('id', c.id);
          
      _fetchCompanyData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(c.isBlacklisted ? 'Company Whitelisted' : 'Company Blocked Successfully'))
        );
      }
    } catch (e) {
      debugPrint('Error toggling blacklist: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // We use the Dynamic Profile if ready, otherwise fallback to the Initial passed one (Instant Load)
    final c = _dynamicCompany ?? widget.company;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(c.name,
            style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.4),
            overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => AddCompanyScreen(company: c),
              ));
            },
            tooltip: 'Edit',
          ),
          IconButton(
            icon: Icon(
              c.isBlacklisted ? Icons.check_circle_outline : Icons.block_rounded,
              color: c.isBlacklisted ? Colors.green : Colors.orange,
            ),
            onPressed: _toggleBlacklist,
            tooltip: c.isBlacklisted ? 'Unblock Partner' : 'Block Partner',
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
          final isMobile = constraints.maxWidth < 680;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeroCard(c: c, isMobile: isMobile, isLoading: _isLoading),
                const SizedBox(height: 20),
                _TabRow(tabs: _tabs, activeIndex: _tabIndex,
                    onTap: (i) => setState(() => _tabIndex = i)),
                const SizedBox(height: 20),
                _isLoading 
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: Color(0xFF0F172A)),
                    ))
                  : _buildTabContent(c, isMobile),
                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent(CompanyDetailArgs c, bool isMobile) {
    switch (_tabIndex) {
      case 0: return _OverviewTab(c: c, isMobile: isMobile);
      case 1: return _PastRolesTab(pastRoles: _pastRoles);
      case 2: return _RolesTab(roles: _openRoles);
      case 3: return _DocsTab(docs: _docs);
      default: return const SizedBox();
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Hero Card — uses Stack, not Transform.translate, to avoid overflow
class _HeroCard extends StatelessWidget {
  final CompanyDetailArgs c;
  final bool isMobile;
  final bool isLoading;
  const _HeroCard({required this.c, required this.isMobile, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final bannerH = isMobile ? 80.0 : 100.0;
    final avatarD = isMobile ? 56.0 : 68.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner + avatar using Stack ──
          SizedBox(
            height: bannerH + avatarD / 2,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Gradient banner
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: SizedBox(
                    height: bannerH,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [c.logoColor, c.logoColor.withValues(alpha: 0.55)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        Positioned(right: -20, top: -20,
                            child: _circle(100, 0.09)),
                        Positioned(left: 40, bottom: -28,
                            child: _circle(70, 0.07)),
                      ],
                    ),
                  ),
                ),
                // Avatar sitting at banner bottom edge
                Positioned(
                  left: isMobile ? 16 : 24,
                  top: bannerH - avatarD / 2,
                  child: _Avatar(c: c, diameter: avatarD),
                ),
                // Status badge on banner top-right
                Positioned(
                  top: 12,
                  right: 12,
                  child: isLoading 
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                        child: const Row(children: [
                          SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          SizedBox(width: 8),
                          Text('Syncing...', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                        ]),
                      )
                    : _StatusBadgeLight(status: c.isBlacklisted ? 'Blocked' : c.status),
                ),
              ],
            ),
          ),

          // ── Text content ──
          Padding(
            padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 10, isMobile ? 16 : 24, isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w900, color: const Color(0xFF0F172A),
                    fontSize: isMobile ? 18 : 22, letterSpacing: -0.5),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _metaChip(Icons.domain_rounded,  c.industry),
                    _metaChip(Icons.place_outlined,   c.location),
                  ],
                ),
                const SizedBox(height: 12),
                Text(c.about,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.6)),
                const SizedBox(height: 20),

                // ── Stats — wrap on mobile ──
                isMobile
                    ? _mobileStats(c)
                    : _desktopStats(c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileStats(CompanyDetailArgs c) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatChip(icon: Icons.people_alt_outlined, value: '${c.activeInterns}', label: 'Interns',         color: c.logoColor),
        _StatChip(icon: Icons.work_outline_rounded, value: '${c.openRoles}',    label: 'Open Roles',      color: const Color(0xFF8B5CF6)),
        _StatChip(icon: Icons.check_circle_outline, value: '${c.totalPlacements}', label: 'Placed',       color: const Color(0xFF10B981)),
        _StatChip(icon: Icons.star_rounded,         value: c.rating > 0 ? '${c.rating}' : '—', label: 'Rating', color: const Color(0xFFEAB308)),
      ],
    );
  }

  Widget _desktopStats(CompanyDetailArgs c) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _HeroStat(icon: Icons.people_alt_outlined, value: '${c.activeInterns}', label: 'Active Interns',    color: c.logoColor)),
          _vLine(),
          Expanded(child: _HeroStat(icon: Icons.work_outline_rounded, value: '${c.openRoles}',    label: 'Open Roles',       color: const Color(0xFF8B5CF6))),
          _vLine(),
          Expanded(child: _HeroStat(icon: Icons.check_circle_outline, value: '${c.totalPlacements}', label: 'Total Placed',  color: const Color(0xFF10B981))),
          _vLine(),
          Expanded(child: _HeroStat(icon: Icons.star_rounded,         value: c.rating > 0 ? '${c.rating}' : 'N/A', label: 'Avg Rating', color: const Color(0xFFEAB308))),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Flexible(child: Text(text,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _vLine() => Container(width: 1, height: 40, color: const Color(0xFFE2E8F0));

  Widget _circle(double size, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity)),
  );
}

class _Avatar extends StatelessWidget {
  final CompanyDetailArgs c;
  final double diameter;
  const _Avatar({required this.c, required this.diameter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter, height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: c.logoColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, color: c.logoColor.withValues(alpha: 0.12)),
        child: Center(
          child: Text(c.logoInitial,
            style: TextStyle(fontWeight: FontWeight.w900, color: c.logoColor, fontSize: diameter * 0.42)),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _HeroStat({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11), textAlign: TextAlign.center),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 7),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14)),
            Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
          ]),
        ],
      ),
    );
  }
}

class _StatusBadgeLight extends StatelessWidget {
  final String status;
  const _StatusBadgeLight({required this.status});

  @override
  Widget build(BuildContext context) {
    final isBlocked = status == 'Blocked';
    final Color dot = status == 'Approved'
        ? const Color(0xFF4ADE80)
        : status == 'Pending' 
            ? const Color(0xFFFBBF24) 
            : isBlocked ? const Color(0xFF0F172A) : const Color(0xFFFC8181);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isBlocked ? const Color(0xFF0F172A).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: isBlocked ? Colors.white : dot, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(status, style: TextStyle(
          fontSize: 11, 
          fontWeight: FontWeight.w700, 
          color: isBlocked ? const Color(0xFF0F172A) : Colors.white
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
class _TabRow extends StatelessWidget {
  final List<String> tabs;
  final int activeIndex;
  final void Function(int) onTap;
  const _TabRow({required this.tabs, required this.activeIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = activeIndex == i;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: i < tabs.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: active ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
              ),
              child: Text(tabs[i],
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: active ? Colors.white : const Color(0xFF64748B))),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Shared helpers
Widget _sectionTitle(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Text(t, style: const TextStyle(
      fontSize: 16, fontWeight: FontWeight.w800,
      color: Color(0xFF0F172A), letterSpacing: -0.3)),
);

Widget _card({required Widget child}) => Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFFE2E8F0)),
  ),
  child: child,
);

// ─────────────────────────────────────────────────────────────────
class _OverviewTab extends StatefulWidget {
  final CompanyDetailArgs c;
  final bool isMobile;
  const _OverviewTab({required this.c, required this.isMobile});

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  Map<String, dynamic>? _fullData;

  @override
  void initState() {
    super.initState();
    _fetchExtraData();
  }

  Future<void> _fetchExtraData() async {
    final res = await Supabase.instance.client
        .from('companies')
        .select('*')
        .eq('id', widget.c.id)
        .single();
    if (mounted) setState(() => _fullData = res);
  }

  @override
  Widget build(BuildContext context) {
    final d = _fullData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Company Information'),
        _card(child: _infoList([
          _InfoRow(icon: Icons.tag_rounded,          label: 'System ID',        value: widget.c.id),
          _InfoRow(icon: Icons.domain_rounded,        label: 'Industry',          value: widget.c.industry),
          _InfoRow(icon: Icons.place_outlined,        label: 'Headquarters',      value: widget.c.location),
        ])),
        const SizedBox(height: 24),
        _sectionTitle('Contact & Partnership'),
        _card(child: _infoList([
          _InfoRow(icon: Icons.email_outlined,      label: 'Coordination Email', value: d?['contact_email'] ?? 'Not Given'),
          _InfoRow(icon: Icons.phone_outlined,      label: 'Phone',           value: d?['phone'] ?? 'N/A'),
          _InfoRow(icon: Icons.language_rounded,    label: 'Website',         value: d?['website'] ?? 'N/A'),
          _InfoRow(icon: Icons.handshake_outlined,  label: 'MOU Signed',      value: d?['mou_date'] ?? 'TBD'),
          _InfoRow(icon: Icons.calendar_month_outlined, label: 'Partner Since', value: d?['partner_since']?.toString() ?? 'N/A'),
        ])),
      ],
    );
  }

  Widget _infoList(List<_InfoRow> rows) {
    return Column(
      children: List.generate(rows.length, (i) => Column(children: [
        rows[i],
        if (i < rows.length - 1) const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
      ])),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Expanded(child: Text(label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500))),
          const SizedBox(width: 8),
          Flexible(child: Text(value,
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w700),
            textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
class _PastRolesTab extends StatelessWidget {
  final List<Map<String, dynamic>> pastRoles;
  const _PastRolesTab({required this.pastRoles});

  // Mock data for detail screen
  static const _applicants = [
    [
      {'name': 'Priya Sharma',  'id': 'STU-001', 'dept': 'Computer Science', 'status': 'Accepted'},
      {'name': 'Nisha Patel',   'id': 'STU-003', 'dept': 'Information Tech', 'status': 'Accepted'},
      {'name': 'Rohan Das',     'id': 'STU-004', 'dept': 'Electrical Eng.',  'status': 'Accepted'},
    ],
  ];
  static const _descriptions = [
    'This was a successful internship program where students worked on core backend services and scalable REST APIs. Delivered major impact.',
    'Interns focused on data modeling and created internal dashboard tools for the analytics team. Helped improve decision making.',
  ];
  static const _skills = [['Node.js', 'SQL', 'Git'], ['Python', 'Pandas', 'Tableau']];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Past Internship Roles (${pastRoles.length})'),
        ...List.generate(pastRoles.length, (i) {
          final role = pastRoles[i];
          final filled  = int.parse(role['filled']!);
          final slots   = int.parse(role['slots']!);
          final allFilled = filled == slots;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => RoleDetailScreen(
                      title: role['title']!,
                      type: role['type']!,
                      deadline: 'N/A (Closed)',
                      slots: role['slots']!,
                      startDate: role['period']!,
                      duration: 'Completed',
                      description: _descriptions[i % _descriptions.length],
                      skills: _skills[i % _skills.length],
                      applicants: _applicants[0], // Handful of accepted mock students
                    ),
                  ));
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(role['title']!,
                              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 14),
                              overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Row(children: [
                              _chip(role['type']!, const Color(0xFFF1F5F9), const Color(0xFF475569)),
                              const SizedBox(width: 8),
                              const Icon(Icons.event_note_outlined, size: 12, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Flexible(child: Text(role['period']!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis)),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: allFilled ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: allFilled ? const Color(0xFFBBF7D0) : const Color(0xFFFED7AA)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(
                                allFilled ? Icons.check_circle_outline : Icons.hourglass_bottom_rounded,
                                size: 12,
                                color: allFilled ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
                              ),
                              const SizedBox(width: 5),
                              Text('$filled/$slots filled',
                                style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: allFilled ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
                                )),
                            ]),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _chip(String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
  );
}

// ─────────────────────────────────────────────────────────────────
class _RolesTab extends StatelessWidget {
  final List<Map<String, dynamic>> roles;
  const _RolesTab({required this.roles});

  @override
  Widget build(BuildContext context) {
    if (roles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text('No open roles found for this company.')),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Open Positions (${roles.length})'),
        ...List.generate(roles.length, (i) {
          final role = roles[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => RoleDetailScreen(
                    title: role['role'] ?? 'Intern Role',
                    type: 'Full-time',
                    deadline: role['deadline'] ?? 'TBD',
                    slots: role['total_slots']?.toString() ?? '0',
                    startDate: 'May 1, 2025',
                    duration: '6 Months',
                    description: role['description'] ?? 'No description provided.',
                    skills: const ['General Skillset'],
                    applicants: const [],
                  ),
                )),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(role['role'] ?? 'Intern Role',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 14),
                        overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(children: [
                        _chip('Full-time', const Color(0xFFF1F5F9), const Color(0xFF475569)),
                        const SizedBox(width: 8),
                        const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Flexible(child: Text(role['deadline'] ?? 'No Deadline',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          overflow: TextOverflow.ellipsis)),
                      ]),
                    ])),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      _chip('${role['total_slots']} slots', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
                    ]),
                    const SizedBox(width: 10),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                  ]),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _chip(String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
  );
}


// ─────────────────────────────────────────────────────────────────
class _DocsTab extends StatelessWidget {
  final List<Map<String, dynamic>> docs;
  const _DocsTab({required this.docs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Compliance Documents'),
        ...docs.map((doc) {
          final verified = doc['status'] == 'Verified';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.description_outlined, color: Color(0xFF64748B), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(doc['title']!,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 13),
                  overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text('${doc['type']} · ${doc['date']}',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              ])),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: verified ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: verified ? const Color(0xFFBBF7D0) : const Color(0xFFFED7AA)),
                ),
                child: Text(doc['status']!,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                    color: verified ? const Color(0xFF16A34A) : const Color(0xFFEA580C))),
              ),
            ]),
          );
        }),
      ],
    );
  }
}
