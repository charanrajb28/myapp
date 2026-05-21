import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final bool isBlacklisted;
  final Color logoColor;
  final String logoInitial;
  final String about;

  const _Company({
    required this.id, required this.name, required this.industry,
    required this.location, required this.activeInterns,
    required this.totalPlacements, required this.openRoles,
    required this.rating, required this.status,
    required this.logoColor, required this.logoInitial,
    required this.about, required this.isBlacklisted,
  });
}

// ─────────────────────────────────────────────────────────────────
class CompaniesListScreen extends StatefulWidget {
  const CompaniesListScreen({super.key});
  @override
  State<CompaniesListScreen> createState() => _CompaniesListScreenState();
}

class _CompaniesListScreenState extends State<CompaniesListScreen> {
  String _query = '';
  List<_Company> _companies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser == null) {
        if (mounted) {
          setState(() {
            _companies = [
              _Company(
                id: 'comp-1',
                name: 'TechCorp Solutions',
                industry: 'Information Technology',
                location: 'San Francisco, CA',
                activeInterns: 8,
                totalPlacements: 24,
                openRoles: 3,
                rating: 4.8,
                status: 'Approved',
                logoColor: const Color(0xFF3B82F6),
                logoInitial: 'T',
                about: 'TechCorp Solutions is a leading provider of cloud infrastructure and modern enterprise software applications.',
                isBlacklisted: false,
              ),
              _Company(
                id: 'comp-2',
                name: 'Google',
                industry: 'Tech & Search',
                location: 'Mountain View, CA',
                activeInterns: 15,
                totalPlacements: 45,
                openRoles: 5,
                rating: 4.9,
                status: 'Approved',
                logoColor: const Color(0xFFEA4335),
                logoInitial: 'G',
                about: 'Organizing the world\'s information and making it universally accessible and useful.',
                isBlacklisted: false,
              ),
              _Company(
                id: 'comp-3',
                name: 'Stripe',
                industry: 'Fintech',
                location: 'South San Francisco, CA',
                activeInterns: 6,
                totalPlacements: 18,
                openRoles: 2,
                rating: 4.7,
                status: 'Approved',
                logoColor: const Color(0xFF635BFF),
                logoInitial: 'S',
                about: 'Stripe provides financial infrastructure for the internet, enabling payments and online billing globally.',
                isBlacklisted: false,
              ),
              _Company(
                id: 'comp-4',
                name: 'Meta',
                industry: 'Social Networking',
                location: 'Menlo Park, CA',
                activeInterns: 10,
                totalPlacements: 30,
                openRoles: 4,
                rating: 4.6,
                status: 'Approved',
                logoColor: const Color(0xFF0080FF),
                logoInitial: 'M',
                about: 'Meta builds technologies that help people connect, find communities, and grow businesses.',
                isBlacklisted: false,
              ),
              _Company(
                id: 'comp-5',
                name: 'Legacy Dynamics',
                industry: 'Consulting',
                location: 'Boston, MA',
                activeInterns: 0,
                totalPlacements: 12,
                openRoles: 0,
                rating: 3.5,
                status: 'Approved',
                logoColor: const Color(0xFF64748B),
                logoInitial: 'L',
                about: 'Legacy business consulting provider. Currently paused operations.',
                isBlacklisted: true,
              )
            ];
            _isLoading = false;
          });
        }
        return;
      }

      final res = await client
          .from('companies')
          .select('*')
          .order('created_at');

      if (mounted) {
        setState(() {
          _companies = (res as List).map((c) {
            return _Company(
              id: c['id'] ?? '',
              name: c['name'] ?? 'Unknown',
              industry: c['industry'] ?? 'General',
              location: 'Remote/Unspecified', // Dummy fallback as per schema
              activeInterns: 0,
              totalPlacements: 0,
              openRoles: 0,
              rating: 4.5,
              status: 'Approved',
              logoColor: const Color(0xFF3B82F6),
              logoInitial: (c['name'] != null && c['name'].isNotEmpty) ? c['name'][0].toUpperCase() : 'C',
              about: c['description'] ?? 'No description provided.',
              isBlacklisted: (c['is_blacklisted'] as bool?) ?? false,
            );
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching companies: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBlacklist(String id, bool currentState) async {
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser == null) {
        setState(() {
          final index = _companies.indexWhere((c) => c.id == id);
          if (index != -1) {
            final old = _companies[index];
            _companies[index] = _Company(
              id: old.id,
              name: old.name,
              industry: old.industry,
              location: old.location,
              activeInterns: old.activeInterns,
              totalPlacements: old.totalPlacements,
              openRoles: old.openRoles,
              rating: old.rating,
              status: old.status,
              logoColor: old.logoColor,
              logoInitial: old.logoInitial,
              about: old.about,
              isBlacklisted: !currentState,
            );
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(currentState ? 'Company Whitelisted (Dev Mode)' : 'Company Blocked Successfully (Dev Mode)'))
          );
        }
        return;
      }

      await client
          .from('companies')
          .update({'is_blacklisted': !currentState})
          .eq('id', id);
          
      _fetchCompanies();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(currentState ? 'Company Whitelisted' : 'Company Blocked Successfully'))
        );
      }
    } catch (e) {
      debugPrint('Error toggling blacklist: $e');
    }
  }

  List<_Company> get _filtered => _companies
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
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Column(
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
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 450,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          mainAxisExtent: 215, // Increased height to prevent overflow
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CompanyDetailScreen(
                  company: CompanyDetailArgs(
                    id: company.id,
                    name: company.name,
                    industry: company.industry,
                    location: company.location,
                    activeInterns: company.activeInterns,
                    totalPlacements: company.totalPlacements,
                    openRoles: company.openRoles,
                    rating: company.rating,
                    status: company.status,
                    logoColor: company.logoColor,
                    logoInitial: company.logoInitial,
                    about: company.about,
                    isBlacklisted: company.isBlacklisted,
                  ),
                ),
              ),
            ).then((_) {
              if (context.mounted) {
                context.findAncestorStateOfType<_CompaniesListScreenState>()?._fetchCompanies();
              }
            });
          },
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
                    padding: const EdgeInsets.fromLTRB(16, 10, 10, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _StatusPill(status: company.isBlacklisted ? 'Blocked' : company.status),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF94A3B8)),
                          padding: EdgeInsets.zero,
                          onSelected: (val) {
                            if (val == 'block') {
                              (context.findAncestorStateOfType<_CompaniesListScreenState>())?._toggleBlacklist(company.id, company.isBlacklisted);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'block',
                              child: Row(
                                children: [
                                  Icon(company.isBlacklisted ? Icons.check_circle_outline : Icons.block_rounded, size: 18, color: company.isBlacklisted ? Colors.green : Colors.orange),
                                  const SizedBox(width: 8),
                                  Text(company.isBlacklisted ? 'Unblock Partner' : 'Block Partner'),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                          const SizedBox(height: 8),
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
          isBlacklisted: company.isBlacklisted,
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
            : status == 'Blocked'
                ? const Color(0xFF0F172A) // Dark/Black for Blocked
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
