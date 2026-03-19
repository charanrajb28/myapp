import 'package:flutter/material.dart';

class RoleDetailScreen extends StatelessWidget {
  final String title;
  final String type;
  final String deadline;
  final String slots;
  final String startDate;
  final String duration;
  final String description;
  final List<String> skills;
  final List<Map<String, String>> applicants;

  const RoleDetailScreen({
    super.key,
    required this.title,
    required this.type,
    required this.deadline,
    required this.slots,
    required this.startDate,
    required this.duration,
    required this.description,
    required this.skills,
    required this.applicants,
  });

  // Derive counts from applicants
  int get _accepted     => applicants.where((a) => a['status'] == 'Accepted').length;
  int get _underReview  => applicants.where((a) => a['status'] == 'Under Review').length;
  int get _applied      => applicants.where((a) => a['status'] == 'Applied').length;
  int get _rejected     => applicants.where((a) => a['status'] == 'Rejected').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Role Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        centerTitle: true,
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF0F172A)),
            onPressed: () {},
            tooltip: 'Options',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Background split (light gray top, white bottom)
          Positioned(
            top: 0, left: 0, right: 0, height: 260,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 100), // padding bottom for fab/action bar
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title Header ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(type.toUpperCase(), 
                      style: const TextStyle(color: Color(0xFF1D4ED8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 12),
                  Text(title,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.8, height: 1.1),
                  ),
                  const SizedBox(height: 24),
                  
                  // ── Meta Strip (Sleek cards) ──
                  Row(
                    children: [
                      Expanded(child: _MetaBox(icon: Icons.play_circle_fill, label: 'Starts', value: startDate, color: const Color(0xFF0EA5E9))),
                      const SizedBox(width: 12),
                      Expanded(child: _MetaBox(icon: Icons.timelapse_rounded, label: 'Duration', value: duration, color: const Color(0xFF8B5CF6))),
                    ]
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _MetaBox(icon: Icons.event_rounded, label: 'Deadline', value: deadline, color: const Color(0xFFF43F5E))),
                      const SizedBox(width: 12),
                      Expanded(child: _MetaBox(icon: Icons.people_alt_rounded, label: 'Openings', value: '$slots slots', color: const Color(0xFF10B981))),
                    ]
                  ),
                  
                  const SizedBox(height: 48),

                  // ── About ──
                  const Text('About the Role', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.3)),
                  const SizedBox(height: 12),
                  Text(description,
                    style: const TextStyle(fontSize: 15, color: Color(0xFF475569), height: 1.7, fontWeight: FontWeight.w400)),
                  
                  const SizedBox(height: 36),
                  
                  // ── Skills ──
                  const Text('Requirements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.3)),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8, runSpacing: 12,
                    children: skills.map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                        ],
                      ),
                    )).toList(),
                  ),

                  const SizedBox(height: 48),

                  // ── Applicants Section ──
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Applicants', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                        child: Text('Total ${applicants.length}',
                          style: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ]
                  ),
                  const SizedBox(height: 16),
                  
                  // Summary pills (scrollable horizontally if needed)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        if (_accepted > 0) _summaryPill('$_accepted Accepted', const Color(0xFF16A34A), const Color(0xFFF0FDF4), const Color(0xFFBBF7D0)),
                        if (_underReview > 0) _summaryPill('$_underReview Reviewing', const Color(0xFF2563EB), const Color(0xFFEFF6FF), const Color(0xFFBFDBFE)),
                        if (_applied > 0) _summaryPill('$_applied New', const Color(0xFFEA580C), const Color(0xFFFFF7ED), const Color(0xFFFED7AA)),
                        if (_rejected > 0) _summaryPill('$_rejected Rejected', const Color(0xFFDC2626), const Color(0xFFFEF2F2), const Color(0xFFFECACA)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // applicant list
                  ...applicants.map((a) => _ApplicantRow(applicant: a)),
                ],
              ),
            ),
          ),
          
          // ── Bottom Fixed Action Bar ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.file_download_outlined, size: 18),
                        label: const Text('Export List'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.post_add_rounded, size: 18),
                        label: const Text('Edit Role'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryPill(String label, Color text, Color bg, Color border) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
      child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: text)),
    );
  }
}

class _MetaBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  
  const _MetaBox({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        ],
      ),
    );
  }
}

class _ApplicantRow extends StatelessWidget {
  final Map<String, String> applicant;
  const _ApplicantRow({required this.applicant});

  static const _avatarColors = [
    Color(0xFF6366F1), Color(0xFF0EA5E9), Color(0xFF10B981),
    Color(0xFFEA580C), Color(0xFF8B5CF6), Color(0xFFF43F5E),
  ];

  @override
  Widget build(BuildContext context) {
    final name   = applicant['name']!;
    final id     = applicant['id']!;
    final dept   = applicant['dept']!;
    final status = applicant['status']!;
    final avatarColor = _avatarColors[name.codeUnitAt(0) % _avatarColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {}, // future navigate to student detail
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              // Avatar
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatarColor.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Text(name[0],
                    style: TextStyle(fontWeight: FontWeight.w800, color: avatarColor, fontSize: 18)),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 15, letterSpacing: -0.3),
                  overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('$id • $dept', 
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
              ])),
              const SizedBox(width: 12),
              _StatusBadge(status: status),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
            ]),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, text;
    IconData icon;

    switch (status) {
      case 'Accepted':
        bg = const Color(0xFFECFDF5); text = const Color(0xFF059669); icon = Icons.check_circle_rounded;
        break;
      case 'Under Review':
        bg = const Color(0xFFEFF6FF); text = const Color(0xFF2563EB); icon = Icons.hourglass_top_rounded;
        break;
      case 'Rejected':
        bg = const Color(0xFFFEF2F2); text = const Color(0xFFDC2626); icon = Icons.cancel_rounded;
        break;
      default: // Applied
        bg = const Color(0xFFFFF7ED); text = const Color(0xFFEA580C); icon = Icons.auto_awesome_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: text),
        const SizedBox(width: 6),
        Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: text)),
      ]),
    );
  }
}
