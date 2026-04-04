import 'package:flutter/material.dart';
import 'edit_posting_screen.dart';
import '../candidates/candidate_portfolio_screen.dart';

class PostingDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> posting;
  const PostingDetailsScreen({super.key, required this.posting});

  @override
  State<PostingDetailsScreen> createState() => _PostingDetailsScreenState();
}

class _PostingDetailsScreenState extends State<PostingDetailsScreen> {
  late String roleName;
  late String status;
  late List<Map<String, dynamic>> _candidates;
  final Set<String> _selectedCandidates = {};

  @override
  void initState() {
    super.initState();
    roleName = widget.posting['role'];
    status = widget.posting['status'];
    _candidates = List.from(_dummyCandidates);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.posting['color'] as Color;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Positioned.fill(child: _DotGrid()),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── BANNER_HERO ──
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(height: 180, width: double.infinity, decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight))),
                    Positioned(top: 40, left: 24, child: GestureDetector(onTap: () => Navigator.pop(context), child: CircleAvatar(backgroundColor: Colors.white.withValues(alpha: 0.2), child: const Icon(Icons.arrow_back_rounded, color: Colors.white)))),
                    Positioned(bottom: -30, left: 24, child: Container(width: 70, height: 70, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 1), blurRadius: 10, offset: const Offset(0, 5))]), child: Icon(Icons.work_rounded, color: color, size: 28))),
                  ],
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 45)),

              // ── IDENTITY_UNIT ──
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(roleName.toUpperCase(), style: const TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _statusChip('ACTV_PHASE: $status', color),
                          const SizedBox(width: 12),
                          _statusChip('SECURE_RECORD', const Color(0xFF6366F1)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── PRIMARY_BENTO_GRID ──
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(child: _bentoParam('STIPEND_VAL', '₹25K /mo', Icons.payments_rounded, color)),
                      const SizedBox(width: 12),
                      Expanded(child: _bentoParam('DURATION', '06 Months', Icons.timer_rounded, const Color(0xFF6366F1))),
                      const SizedBox(width: 12),
                      Expanded(child: _bentoParam('LOCATION', 'REMOTE_IN', Icons.place_rounded, const Color(0xFFF59E0B))),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // ── MISSION_DETAILS_LEDGER ──
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _narrativeCard('MISSION_LOG', 'Our company is scaling decentralised AI nodes. We need a high-performance engineer to build technical dashboards and cloud infra for enterprise monitoring. This is a mission-critical role for the 2026 roadmap.'),
                    const SizedBox(height: 20),
                    _responsibilitiesCard('MISSION_RESPONSIBILITIES', [
                      'Architect and scale responsive UI modules in Flutter.',
                      'Optimize Node.js service layers for low-latency nodes.',
                      'Integrate Firebase cloud functions for real-time monitoring.',
                      'Standardise technical documentation for system audits.',
                    ]),
                    const SizedBox(height: 20),
                    _qualificationGrid('QUALIFICATION_MATRIX', 'B.Tech / BE in Comp Science', 'No backlogs. Minimum 7.5 CGPA required.'),
                  ]),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 48)),

              // ── APPLICANT_REGISTRY ──
              if (status == 'ACTIVE') ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('> BATCH_SELECTION_HUB', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              if (_selectedCandidates.length == _candidates.length) {
                                _selectedCandidates.clear();
                              } else {
                                _selectedCandidates.addAll(_candidates.map((c) => c['name'] as String));
                              }
                            });
                          },
                          child: Text(_selectedCandidates.length == _candidates.length ? 'DESELECT_ALL' : 'SELECT_ALL', style: const TextStyle(color: Color(0xFF6366F1), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: _industrialBtnSmall('SEND_ALERT_TO_SELECTED (${_selectedCandidates.length})', onTap: () {
                      if (_selectedCandidates.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NO_NODES_SELECTED_FOR_BROADCAST.'), backgroundColor: Color(0xFF64748B)));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ALERT_BROADCASTED_TO ${_selectedCandidates.length} CANDIDATES.'), backgroundColor: const Color(0xFF0F172A)));
                      }
                    }),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],

              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: Text('> APPLICANT_REGISTRY_LOG', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final candidate = _candidates[index];
                      return _CandidateIndustrialTile(
                        candidate: candidate,
                        isSelected: _selectedCandidates.contains(candidate['name']),
                        showSelection: status == 'ACTIVE',
                        onSelect: (val) {
                           setState(() {
                             if (val == true) {
                               _selectedCandidates.add(candidate['name']);
                             } else {
                               _selectedCandidates.remove(candidate['name']);
                             }
                           });
                        },
                        onTap: () => _showCandidateDetail(context, candidate),
                      );
                    },
                    childCount: _candidates.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 48)),

              // ── ACTION_CONSOLE ──
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(child: _actionBtn('EDIT_CONSOLE', true, color, () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditPostingScreen(posting: widget.posting))))),
                      if (status == 'ACTIVE' || status == 'INTERVIEWING') ...[
                        const SizedBox(width: 12),
                        Expanded(child: _actionBtn('CLOSE_SLOT', false, color, () {
                          // TODO: Implement close logic
                        })),
                      ],
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _narrativeCard(String label, String content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('> $label', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.6, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _responsibilitiesCard(String label, List<String> duties) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('> $label', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 16),
          Column(
            children: duties.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(padding: EdgeInsets.only(top: 4), child: Icon(Icons.circle, color: Color(0xFF6366F1), size: 6)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(d, style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.5, fontWeight: FontWeight.w500))),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _qualificationGrid(String label, String degree, String notes) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('> $label', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 12),
          Text(degree, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(notes, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
    );
  }

  Widget _bentoParam(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, bool isPrimary, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(color: isPrimary ? const Color(0xFF0F172A) : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF0F172A))),
        child: Center(child: Text(label, style: TextStyle(color: isPrimary ? Colors.white : const Color(0xFF0F172A), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5))),
      ),
    );
  }

  void _showCandidateDetail(BuildContext context, Map<String, dynamic> candidate) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(28),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 28, backgroundImage: NetworkImage(candidate['avatar'])),
                  const SizedBox(width: 20),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(candidate['name'], style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w900)),
                    Text('${candidate['college']} • SCH_NODE_ID', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ]),
                ],
              ),
              const Text('> CREDENTIAL_OVERVIEW', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 16),
              _insightRow('RESUME_DOC', 'DOWNLOAD_STUB_PDF', const Color(0xFF3B82F6)),
              
              const SizedBox(height: 32),
              const Text('> TECHNICAL_SKILL_BREAKDOWN', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                   _skillPulse('Flutter', 0.95),
                   _skillPulse('Node.js', 0.8),
                   _skillPulse('UI/UX', 0.7),
                ],
              ),
              
              const SizedBox(height: 48),
              _actionBtnModal('ACCEPT_CANDIDATE', const Color(0xFF10B981), () {
                setState(() {
                  final idx = _candidates.indexWhere((c) => c['name'] == candidate['name']);
                  if (idx != -1) _candidates[idx]['status'] = 'ACCEPTED';
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${candidate['name']} accepted.'), backgroundColor: const Color(0xFF10B981)));
              }),
              const SizedBox(height: 12),
              _actionBtnModal('REJECT_PHASE', const Color(0xFFEF4444), () {
                setState(() {
                  final idx = _candidates.indexWhere((c) => c['name'] == candidate['name']);
                  if (idx != -1) _candidates[idx]['status'] = 'REJECTED';
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${candidate['name']} rejected.'), backgroundColor: const Color(0xFFEF4444)));
              }),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _insightRow(String label, String value, Color color) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)), Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))]));
  }

  Widget _industrialBtnSmall(String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: double.infinity, height: 44, decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)), child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)))),
    );
  }

  Widget _actionBtnModal(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: color)),
        child: Center(child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5))),
      ),
    );
  }

  Widget _deepMetric(String label, String status, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              Text(status, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: const Color(0xFFF1F5F9),
              color: color,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _skillPulse(String label, double strength) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: strength > 0.7 ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _CandidateIndustrialTile extends StatelessWidget {
  final Map<String, dynamic> candidate;
  final bool isSelected;
  final bool showSelection;
  final ValueChanged<bool?> onSelect;
  final VoidCallback onTap;
  const _CandidateIndustrialTile({required this.candidate, required this.onTap, required this.isSelected, required this.showSelection, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final status = candidate['status'] as String? ?? 'PENDING';
    final isAccepted = status == 'ACCEPTED';
    final isRejected = status == 'REJECTED';
    
    Color statusColor = const Color(0xFF64748B);
    Color bgColor = Colors.white;
    if (isAccepted) {
      statusColor = const Color(0xFF10B981);
      bgColor = const Color(0xFF10B981).withValues(alpha: 0.05); // Green-whiter
    }
    if (isRejected) {
      statusColor = const Color(0xFFEF4444);
      bgColor = const Color(0xFFEF4444).withValues(alpha: 0.05); // Red-whiter
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
             if (isAccepted || isRejected)
               BoxShadow(color: statusColor.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            if (showSelection) ...[
               Checkbox(
                 value: isSelected,
                 onChanged: onSelect,
                 activeColor: const Color(0xFF6366F1),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
               ),
               const SizedBox(width: 8),
            ],
            Stack(
              children: [
                CircleAvatar(radius: 20, backgroundImage: NetworkImage(candidate['avatar'])),
                if (isAccepted || isRejected)
                  Positioned(
                    right: -2, bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      child: Icon(isAccepted ? Icons.check : Icons.close, color: Colors.white, size: 8),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(candidate['name'], style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold)),
                  Text(candidate['college'].toUpperCase(), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            if (isAccepted || isRejected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
              )
            else
              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 12),
          ],
        ),
      ),
    );
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

final _dummyCandidates = [
  {'name': 'Arjun Mehta', 'college': 'IIT Bombay', 'avatar': 'https://i.pravatar.cc/150?u=1', 'status': 'ACCEPTED'},
  {'name': 'Sara Khan', 'college': 'BITS Pilani', 'avatar': 'https://i.pravatar.cc/150?u=2', 'status': 'REJECTED'},
  {'name': 'Vikram Singh', 'college': 'NIT Trichy', 'avatar': 'https://i.pravatar.cc/150?u=3', 'status': 'PENDING'},
];
