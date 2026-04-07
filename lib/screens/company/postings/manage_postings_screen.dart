import 'package:flutter/material.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'posting_details_screen.dart';
import 'create_posting_screen.dart';

class ManagePostingsScreen extends StatefulWidget {
  const ManagePostingsScreen({super.key});

  @override
  State<ManagePostingsScreen> createState() => _ManagePostingsScreenState();
}

class _ManagePostingsScreenState extends State<ManagePostingsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allPostings = [];
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchPostings();
  }

  Future<void> _fetchPostings() async {
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
          .from('internships')
          .select('*, applications(id, status)')
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> processed = [];
      for (var p in (res as List)) {
        final apps = p['applications'] as List;
        final pool = apps.length;
        final String status = p['status'] ?? 'INTERVIEWING';

        processed.add({
          ...p,
          'status': status,
          'applicants': pool.toString(),
          'completion': pool > 0 ? (apps.where((a) => a['status'] == 'Completed').length / pool).clamp(0.0, 1.0) : 0.05,
          'color': _parseColor(p['brand_color'] ?? '#6366F1'),
        });
      }

      if (mounted) {
        setState(() {
          _allPostings = processed;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching postings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      final today = DateTime.now();
      final todayLabel = today.toIso8601String().split('T')[0];
      final posting = _allPostings.firstWhere(
        (item) => item['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      final plannedEndDate = _plannedEndDateFromDuration(
        today,
        posting['duration'],
      );
      final Map<String, dynamic> updateData = {'status': newStatus};
      
      if (newStatus == 'ACTIVE') {
        updateData['start_date'] = todayLabel;
        updateData['end_date'] = plannedEndDate;
      } else if (newStatus == 'CLOSED') {
        updateData['end_date'] = todayLabel;
      } else if (newStatus == 'INTERVIEWING') {
        updateData['start_date'] = null;
        updateData['end_date'] = null;
      }

      await Supabase.instance.client
          .from('internships')
          .update(updateData)
          .eq('id', id);

      if (newStatus == 'ACTIVE') {
        await Supabase.instance.client
            .from('applications')
            .update({
              'status': 'Active',
              'start_date': todayLabel,
              'end_date': null,
            })
            .eq('internship_id', id)
            .inFilter('status', ['Accepted', 'Active', 'Completed']);
      } else if (newStatus == 'CLOSED') {
        await Supabase.instance.client
            .from('applications')
            .update({
              'end_date': todayLabel,
            })
            .eq('internship_id', id)
            .eq('status', 'Active');
      } else if (newStatus == 'INTERVIEWING') {
        await Supabase.instance.client
            .from('applications')
            .update({
              'status': 'Accepted',
              'start_date': null,
              'end_date': null,
            })
            .eq('internship_id', id)
            .eq('status', 'Active');
      }

      if (!mounted) return;
      setState(() {
        _allPostings = _allPostings
            .map(
              (item) => item['id'] == id
                  ? {
                      ...item,
                      ...updateData,
                    }
                  : item,
            )
            .toList();
      });

      _fetchPostings();
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
  }

  Future<void> _discardPosting(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('DISCARD INTERNSHIP?', style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
        content: const Text('This will permanently delete the internship and all associated applications. This action cannot be undone.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text('DISCARD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('internships')
          .delete()
          .eq('id', id);
      _fetchPostings();
    } catch (e) {
      debugPrint('Error discarding posting: $e');
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

  String? _plannedEndDateFromDuration(DateTime startDate, dynamic rawDuration) {
    final value = rawDuration?.toString().trim() ?? '';
    final match = RegExp(r'\d+').firstMatch(value);
    final months = int.tryParse(match?.group(0) ?? '') ?? 0;
    if (months <= 0) {
      return null;
    }

    final plannedEnd = DateTime(
      startDate.year,
      startDate.month + months,
      startDate.day,
    );
    return plannedEnd.toIso8601String().split('T')[0];
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostingScreen()));
            _fetchPostings();
          },
          backgroundColor: const Color(0xFF0F172A),
          elevation: 10,
          label: const Text('CREATE NEW JOB', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
        ),
        body: Stack(
          children: [
            Positioned.fill(child: _DotGrid()),
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  const SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverToBoxAdapter(child: _JobsHeader()),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverToBoxAdapter(
                      child: TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicatorColor: const Color(0xFF6366F1),
                        indicatorWeight: 4,
                        labelColor: const Color(0xFF0F172A),
                        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
                        unselectedLabelColor: const Color(0xFF94A3B8),
                        dividerColor: Colors.transparent,
                        onTap: (index) => setState(() => _tabIndex = index),
                        tabs: const [
                          Tab(text: 'INTERVIEWING'),
                          Tab(text: 'ACTIVE JOBS'),
                          Tab(text: 'CLOSED JOBS'),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                   _isLoading 
                   ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.only(top: 100), child: CircularProgressIndicator())))
                   : Builder(
                    builder: (context) {
                      final filterStatus = ['INTERVIEWING', 'ACTIVE', 'CLOSED'][_tabIndex];
                      final filteredList = _allPostings.where((p) => p['status'] == filterStatus).toList();

                      if (filteredList.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 60),
                              child: Column(
                                children: [
                                  Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8), size: 48),
                                  SizedBox(height: 20),
                                  Text('NO JOBS FOUND', style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                  SizedBox(height: 8),
                                  Text('No listings available in this category.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _JobIndustrialCard(
                              posting: filteredList[index],
                              onTap: () => _showPostDetail(context, filteredList[index]),
                              onStatusChange: (newStatus) => _updateStatus(filteredList[index]['id'], newStatus),
                              onDiscard: () => _discardPosting(filteredList[index]['id']),
                            ),
                            childCount: filteredList.length,
                          ),
                        ),
                      );
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPostDetail(
    BuildContext context,
    Map<String, dynamic> posting,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostingDetailsScreen(posting: posting),
      ),
    );
    if (mounted) {
      _fetchPostings();
    }
  }

  void _showQRDialog(BuildContext context, String role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('SHARE JOB QR: ${role.toUpperCase()}', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: CustomPaint(size: const Size(200, 200), painter: _QRSimPainter()),
            ),
            const SizedBox(height: 24),
            const Text('SCAN TO APPLY FOR THIS ROLE', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('DOWNLOAD AS IMAGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobIndustrialCard extends StatelessWidget {
  final Map<String, dynamic> posting;
  final VoidCallback onTap;
  final Function(String) onStatusChange;
  final VoidCallback onDiscard;
  const _JobIndustrialCard({required this.posting, required this.onTap, required this.onStatusChange, required this.onDiscard});

  @override
  Widget build(BuildContext context) {
    final color = posting['color'] as Color;
    final status = posting['status'] as String;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.work_rounded, color: color, size: 22),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(posting['role'].toUpperCase(), style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      const SizedBox(height: 6),
                      _statusChip('${posting['applicants']} APPLICANTS', color),
                    ],
                  ),
                ),
                _statusMenu(context),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CREATED: ${_formatDate(posting['created_at'])}',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusMenu(BuildContext context) {
    final status = posting['status'] as String? ?? 'INTERVIEWING';
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8)),
      onSelected: (val) {
        if (val == 'DISCARD') {
          onDiscard();
        } else {
          onStatusChange(val);
        }
      },
      itemBuilder: (context) => [
        ..._statusMenuItems(status),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'DISCARD',
          child: Text('Discard Internship', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  List<PopupMenuEntry<String>> _statusMenuItems(String status) {
    switch (status) {
      case 'INTERVIEWING':
        return const [
          PopupMenuItem(value: 'ACTIVE', child: Text('Move to Active')),
        ];
      case 'ACTIVE':
        return const [
          PopupMenuItem(
            value: 'INTERVIEWING',
            child: Text('Move to Interviewing'),
          ),
          PopupMenuItem(value: 'CLOSED', child: Text('Move to Closed')),
        ];
      case 'CLOSED':
        return const [
          PopupMenuItem(value: 'ACTIVE', child: Text('Move to Active')),
        ];
      default:
        return const [
          PopupMenuItem(value: 'ACTIVE', child: Text('Move to Active')),
        ];
    }
  }

  Widget _statusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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

class _JobsHeader extends StatelessWidget {
  const _JobsHeader();
  @override
  Widget build(BuildContext context) {
    return const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('ADMINISTRATION PANEL', style: TextStyle(color: Color(0xFF6366F1), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
      SizedBox(height: 12),
      Text('Job Listings', style: TextStyle(color: Color(0xFF0F172A), fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
      SizedBox(height: 8),
      Text('Manage and create new internship opportunities', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
    ]);
  }
}

class _DotGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShaderMask(shaderCallback: (rect) => LinearGradient(colors: [Colors.white, Colors.white.withValues(alpha: 0.3), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(rect), child: CustomPaint(painter: _DotPainter()));
  }
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFCBD5E1)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 30) {
      for (double j = 0; j < size.height; j += 30) {
        canvas.drawCircle(Offset(i, j), 1, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QRSimPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF0F172A);
    final tileSize = size.width / 15;
    final random = Random(42);
    for (int i = 0; i < 15; i++) {
        for (int j = 0; j < 15; j++) {
            if ((i < 4 && j < 4) || (i > 10 && j < 4) || (i < 4 && j > 10)) {
                canvas.drawRect(Rect.fromLTWH(i * tileSize, j * tileSize, tileSize, tileSize), paint);
            } else if (random.nextBool()) {
                canvas.drawRect(Rect.fromLTWH(i * tileSize, j * tileSize, tileSize, tileSize), paint);
            }
        }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
