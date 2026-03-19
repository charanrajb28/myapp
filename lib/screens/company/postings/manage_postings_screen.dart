import 'package:flutter/material.dart';
import 'dart:math';
import 'posting_details_screen.dart';
import 'create_posting_screen.dart';

class PostingsRegistry {
  static final List<Map<String, dynamic>> data = [
    {'role': 'Full Stack Developer', 'status': 'ACTIVE', 'completion': 0.75, 'color': const Color(0xFF6366F1)},
    {'role': 'UI/UX Design Intern', 'status': 'INTERVIEWING', 'completion': 0.40, 'color': const Color(0xFF8B5CF6)},
    {'role': 'Legacy AI Engine', 'status': 'PAST', 'completion': 1.0, 'color': const Color(0xFF64748B)},
  ];
}

class ManagePostingsScreen extends StatefulWidget {
  const ManagePostingsScreen({super.key});

  @override
  State<ManagePostingsScreen> createState() => _ManagePostingsScreenState();
}

class _ManagePostingsScreenState extends State<ManagePostingsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostingScreen()));
            setState(() {});
          },
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.add_rounded, color: Colors.white),
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
                    sliver: SliverToBoxAdapter(child: _IndustrialPostingHeader()),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverToBoxAdapter(
                      child: TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicatorColor: const Color(0xFF6366F1),
                        indicatorWeight: 3,
                        labelColor: const Color(0xFF0F172A),
                        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5),
                        unselectedLabelColor: const Color(0xFF94A3B8),
                        dividerColor: const Color(0xFFE2E8F0),
                        onTap: (index) => setState(() {}),
                        tabs: const [
                          Tab(text: 'ACTIVE_PUBS'),
                          Tab(text: 'IN_APPLICATION'),
                          Tab(text: 'PAST_INTERNSHIPS'),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // ── RECRUITMENT_REGISTRY_FEED ──
                  Builder(
                    builder: (context) {
                      final tabIndex = DefaultTabController.of(context).index;
                      final filterStatus = ['ACTIVE', 'INTERVIEWING', 'PAST'][tabIndex];
                      final filteredList = PostingsRegistry.data.where((p) => p['status'] == filterStatus).toList();

                      if (filteredList.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Text('NO_RECORDS_IN_PHASE', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 2)),
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _PostingIndustrialCard(
                              posting: filteredList[index],
                              onTap: () => _showPostDetail(context, filteredList[index]),
                            ),
                            childCount: filteredList.length,
                          ),
                        ),
                      );
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPostDetail(BuildContext context, Map<String, dynamic> posting) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => PostingDetailsScreen(posting: posting)));
  }

  void _showQRDialog(BuildContext context, String role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('> QR_SHARE_TERMINAL: ${role.toUpperCase()}', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200, height: 200, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: CustomPaint(painter: _QRSimPainter()),
            ),
            const SizedBox(height: 24),
            const Text('SCAN_TO_INITIATE_APPLICATION', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 24),
            _industrialBtnSmall('DOWNLOAD_AS_PNG'),
          ],
        ),
      ),
    );
  }

  Widget _industrialBtnSmall(String label) {
    return Container(width: double.infinity, height: 44, decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)), child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5))));
  }
}

class _PostingIndustrialCard extends StatelessWidget {
  final Map<String, dynamic> posting;
  final VoidCallback onTap;
  const _PostingIndustrialCard({required this.posting, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = posting['color'] as Color;
    final isActive = posting['status'] == 'ACTIVE';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(posting['role'].toUpperCase(), style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _statusChip(posting['status'], color),
                          const SizedBox(width: 8),
                          const Text('32 APPLICANTS', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  IconButton(
                    icon: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF0F172A), size: 24),
                    onPressed: () {
                      final state = context.findAncestorStateOfType<_ManagePostingsScreenState>();
                      state?._showQRDialog(context, posting['role']);
                    },
                  )
                else
                  const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 14)),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: posting['completion'], backgroundColor: const Color(0xFFF1F5F9), color: color, minHeight: 4, borderRadius: BorderRadius.circular(2)),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(status, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
    );
  }
}

class _IndustrialPostingHeader extends StatelessWidget {
  const _IndustrialPostingHeader();
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('> MANAGEMENT_CMS_CONSOLE', style: TextStyle(color: Color(0xFF6366F1), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
      const SizedBox(height: 8),
      const Text('RECRUITMENT_COMMAND', style: TextStyle(color: Color(0xFF0F172A), fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      const SizedBox(height: 4),
      const Text('DEPLOY_AND_MONITOR_TALENT_NODES', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
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
    final paint = Paint()..color = const Color(0xFFE2E8F0)..strokeWidth = 1;
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
