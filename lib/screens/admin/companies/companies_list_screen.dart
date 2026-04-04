import 'package:flutter/material.dart';
import 'company_detail_screen.dart';
import 'add_company_screen.dart';

class _Company {
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

  const _Company({
    required this.id, required this.name, required this.industry,
    required this.location, required this.activeInterns,
    required this.totalPlacements, required this.openRoles,
    required this.rating, required this.status,
    required this.logoColor, required this.logoInitial,
    required this.about,
  });
}

const List<_Company> _kCompanies = [
  _Company(id: 'C-1001', name: 'TechFlow Inc.', industry: 'Software Engineering',
    location: 'San Francisco, CA', activeInterns: 12, totalPlacements: 45,
    openRoles: 3, rating: 4.8, status: 'Approved',
    logoColor: Color(0xFF3B82F6), logoInitial: 'T',
    about: 'Builds enterprise-grade cloud software used by over 2M professionals worldwide.'),
  _Company(id: 'C-1002', name: 'DataDynamics', industry: 'Data Analytics',
    location: 'Austin, TX', activeInterns: 5, totalPlacements: 18,
    openRoles: 1, rating: 4.5, status: 'Approved',
    logoColor: Color(0xFF8B5CF6), logoInitial: 'D',
    about: 'Specialises in real-time data pipelines and predictive analytics for Fortune 500 clients.'),
  _Company(id: 'C-1003', name: 'Cloud9 Systems', industry: 'Cloud Computing',
    location: 'Seattle, WA', activeInterns: 0, totalPlacements: 0,
    openRoles: 2, rating: 0.0, status: 'Pending',
    logoColor: Color(0xFF64748B), logoInitial: 'C',
    about: 'Early-stage cloud infrastructure startup focused on edge computing and serverless architecture.'),
  _Company(id: 'C-1004', name: 'Green Horizons', industry: 'Renewable Energy',
    location: 'Denver, CO', activeInterns: 2, totalPlacements: 8,
    openRoles: 0, rating: 4.2, status: 'Restricted',
    logoColor: Color(0xFF10B981), logoInitial: 'G',
    about: 'Pioneer in solar and wind energy solutions, currently under compliance review.'),
  _Company(id: 'C-1005', name: 'Stark Industries', industry: 'Aerospace',
    location: 'New York, NY', activeInterns: 24, totalPlacements: 120,
    openRoles: 5, rating: 4.9, status: 'Approved',
    logoColor: Color(0xFFEF4444), logoInitial: 'S',
    about: 'Leading aerospace and advanced defence technologies firm with global R&D operations.'),
  _Company(id: 'C-1006', name: 'Nexus Robotics', industry: 'Mechanical Eng.',
    location: 'Boston, MA', activeInterns: 7, totalPlacements: 31,
    openRoles: 2, rating: 4.6, status: 'Approved',
    logoColor: Color(0xFFF59E0B), logoInitial: 'N',
    about: 'Designs autonomous industrial robots for manufacturing automation and smart logistics.'),
];

// ─────────────────────────────────────────────────────────────────
class CompaniesListScreen extends StatefulWidget {
  const CompaniesListScreen({super.key});
  @override
  State<CompaniesListScreen> createState() => _CompaniesListScreenState();
}

class _CompaniesListScreenState extends State<CompaniesListScreen> {
  String _query = '';

  List<_Company> get _filtered => _kCompanies
      .where((c) =>
          c.name.toLowerCase().contains(_query.toLowerCase()) ||
          c.industry.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    final companies = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Partner Companies',
            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Column(
        children: [
          // ── Toolbar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search companies...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCompanyScreen()));
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
              ),
            ]),
          ),

          // ── Count ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(children: [
              Text('${companies.length} companies',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500)),
            ]),
          ),

          // ── 2-col Grid ──
          Expanded(
            child: companies.isEmpty
                ? const Center(child: Text('No companies found', style: TextStyle(color: Color(0xFF94A3B8))))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 450,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          mainAxisExtent: 200, // Fixed height for consistency
                        ),
                        itemCount: companies.length,
                        itemBuilder: (_, i) => _CompanyCard(company: companies[i]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
class _CompanyCard extends StatelessWidget {
  final _Company company;
  const _CompanyCard({required this.company});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Stack(
            children: [
              // Subtle background decoration
              Positioned(
                right: -20, top: -20,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: company.logoColor.withValues(alpha: 0.03),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              
              // Left accent bar
              Positioned(
                left: 0, top: 0, bottom: 0,
                child: Container(width: 4, color: company.logoColor),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Bar with Status ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 14, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _StatusPill(status: company.status),
                      ],
                    ),
                  ),

                  // ── Content ──
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Avatar(company: company),
                          const SizedBox(height: 12),
                          Text(company.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800, color: Color(0xFF0F172A),
                              fontSize: 14, letterSpacing: -0.3),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 5),
                          _IndustryChip(label: company.industry),
                          const Spacer(),
                          _StatsRow(company: company),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final _Company company;
  const _Avatar({required this.company});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: company.logoColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: company.logoColor.withValues(alpha: 0.12),
        ),
        child: Center(
          child: Text(company.logoInitial,
            style: TextStyle(fontWeight: FontWeight.w900, color: company.logoColor, fontSize: 19)),
        ),
      ),
    );
  }
}

class _IndustryChip extends StatelessWidget {
  final String label;
  const _IndustryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final _Company company;
  const _StatsRow({required this.company});

  void _navigate(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CompanyDetailScreen(
        company: CompanyDetailArgs(
          id: company.id, name: company.name, industry: company.industry,
          location: company.location, activeInterns: company.activeInterns,
          totalPlacements: company.totalPlacements, openRoles: company.openRoles,
          rating: company.rating, status: company.status,
          logoColor: company.logoColor, logoInitial: company.logoInitial,
          about: company.about,
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigate(context),
          borderRadius: BorderRadius.circular(8),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('View Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.white, letterSpacing: 0.2)),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, size: 13, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color = status == 'Approved'
        ? const Color(0xFF10B981)
        : status == 'Pending'
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(status,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}
