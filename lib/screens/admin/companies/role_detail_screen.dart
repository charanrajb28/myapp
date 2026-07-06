import 'package:flutter/material.dart';
import '../feedbacks/admin_form_builder_screen.dart';
import '../../company/postings/posting_details_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class RoleDetailScreen extends StatefulWidget {
  final String id;
  final String title;
  final String type;
  final String deadline;
  final String slots;
  final String startDate;
  final String duration;
  final String description;
  final List<String> responsibilities;
  final List<String> activeDays;
  final String notes;
  final List<Map<String, dynamic>> applicants;

  const RoleDetailScreen({
    super.key,
    required this.id,
    required this.title,
    required this.type,
    required this.deadline,
    required this.slots,
    required this.startDate,
    required this.duration,
    required this.description,
    required this.responsibilities,
    this.activeDays = const [],
    this.notes = '',
    required this.applicants,
  });

  @override
  State<RoleDetailScreen> createState() => _RoleDetailScreenState();
}

class _RoleDetailScreenState extends State<RoleDetailScreen> {
  bool _hasForm = false;
  bool _isLoadingForm = true;

  @override
  void initState() {
    super.initState();
    _checkForm();
  }

  Future<void> _checkForm() async {
    if (widget.id.isEmpty) {
      if (mounted) setState(() => _isLoadingForm = false);
      return;
    }
    if (mounted) setState(() => _isLoadingForm = true);
    try {
      final res = await Supabase.instance.client
          .from('internships')
          .select('feedback_form_schema')
          .eq('id', widget.id)
          .single();
      final schema = res['feedback_form_schema'];
      if (mounted) {
        setState(() {
          _hasForm = schema != null && (schema as List).isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Error checking form: $e');
    } finally {
      if (mounted) setState(() => _isLoadingForm = false);
    }
  }

  void _clearForm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Form?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: const Text('This will delete all custom questions for this form. Are you sure?'),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoadingForm = true);
              try {
                await Supabase.instance.client
                    .from('internships')
                    .update({'feedback_form_schema': []})
                    .eq('id', widget.id);
                setState(() => _hasForm = false);
              } catch (e) {
                debugPrint('Error clearing form: $e');
              } finally {
                if (mounted) setState(() => _isLoadingForm = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Clear Form'),
          ),
        ],
      ),
    );
  }

  // Derive counts from applicants
  int get _accepted     => widget.applicants.where((a) => a['status'] == 'Accepted').length;
  int get _underReview  => widget.applicants.where((a) => a['status'] == 'Under Review').length;
  int get _applied      => widget.applicants.where((a) => a['status'] == 'Applied').length;
  int get _rejected     => widget.applicants.where((a) => a['status'] == 'Rejected').length;

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Softer background to make white cards pop
      appBar: AppBar(
        title: const Text('Role Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Card ──
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(widget.type.toUpperCase(), 
                        style: const TextStyle(color: Color(0xFF1D4ED8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ),
                    const SizedBox(height: 12),
                    Text(widget.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5, height: 1.2),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _MetaBox(icon: Icons.play_circle_fill, label: 'Starts', value: widget.startDate, color: const Color(0xFF0EA5E9))),
                        const SizedBox(width: 12),
                        Expanded(child: _MetaBox(icon: Icons.timer_rounded, label: 'Duration', value: widget.duration, color: const Color(0xFF8B5CF6))),
                        const SizedBox(width: 12),
                        Expanded(child: _MetaBox(icon: Icons.event_busy_rounded, label: 'Deadline', value: widget.deadline, color: const Color(0xFFF43F5E))),
                      ],
                    ),
                  ],
                ),
              ),
              
              // ── Details Card (About, Responsibilities, Task List) ──
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('About the Role', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), letterSpacing: -0.2)),
                    const SizedBox(height: 14),
                    Text(widget.description,
                      style: const TextStyle(fontSize: 15, color: Color(0xFF475569), height: 1.6, fontWeight: FontWeight.w400),
                    ),
                    
                    if (widget.responsibilities.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      const Divider(color: Color(0xFFF1F5F9), height: 1),
                      const SizedBox(height: 24),
                      const Text('Responsibilities', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), letterSpacing: -0.2)),
                      const SizedBox(height: 16),
                      ...widget.responsibilities.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF10B981)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(r, style: const TextStyle(fontSize: 15, color: Color(0xFF334155), height: 1.5)),
                                ),
                              ],
                            ),
                          )),
                    ],

                    if (widget.notes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFFF1F5F9), height: 1),
                      const SizedBox(height: 24),
                      const Text('Task List', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), letterSpacing: -0.2)),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 30, height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.sticky_note_2_rounded, color: Color(0xFFD97706), size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(widget.notes,
                                    style: const TextStyle(color: Color(0xFF92400E), fontSize: 13, fontWeight: FontWeight.w500, height: 1.6)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Active Days Card ──
              if (widget.activeDays.isNotEmpty)
                _buildSectionCard(
                  child: Builder(builder: (context) {
                    const allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                    final sortedDays = allDays.where((d) => widget.activeDays.contains(d)).toList();

                    String daysSummary = '';
                    if (sortedDays.length == 7) {
                      daysSummary = 'All days — 7 days/week';
                    } else if (sortedDays.length == 5 && !widget.activeDays.contains('Sat') && !widget.activeDays.contains('Sun')) {
                      daysSummary = 'Monday to Friday — 5 days/week';
                    } else {
                      daysSummary = '${sortedDays.join(', ')} — ${sortedDays.length} day${sortedDays.length == 1 ? '' : 's'}/week';
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Days Active in the Week', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), letterSpacing: -0.2)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: allDays.map((day) {
                                  final isActive = widget.activeDays.contains(day);
                                  final isWeekend = day == 'Sat' || day == 'Sun';
                                  return Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isActive ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isActive ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          day.substring(0, isWeekend ? 3 : 1),
                                          style: TextStyle(color: isActive ? const Color(0xFF047857) : const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              const Divider(color: Color(0xFFE2E8F0), height: 1),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF10B981)),
                                  const SizedBox(width: 6),
                                  Text(daysSummary, style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),

              // ── Feedback Configuration Card ──
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Feedback Form', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), letterSpacing: -0.2)),
                        ),
                        if (widget.id.isNotEmpty)
                          _isLoadingForm 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Row(
                                children: [
                                  if (_hasForm) ...[
                                    OutlinedButton.icon(
                                      onPressed: _clearForm,
                                      icon: const Icon(Icons.delete_outline, size: 16),
                                      label: const Text('Clear'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFEF4444),
                                        side: const BorderSide(color: Color(0xFFFECACA)),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AdminFormBuilderScreen(internshipId: widget.id),
                                        ),
                                      ).then((_) => _checkForm());
                                    },
                                    icon: Icon(_hasForm ? Icons.edit_document : Icons.add_circle_outline, size: 16),
                                    label: Text(_hasForm ? 'Configure' : 'Create'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _hasForm ? const Color(0xFF1D4ED8) : const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                      ]
                    ),
                    const SizedBox(height: 12),
                    const Text('Create custom feedback questions for students to answer when their internship completes.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
              ),

              // ── Applicants Card ──
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Applicants', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), letterSpacing: -0.2)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                          child: Text('Total ${widget.applicants.length}',
                            style: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      ]
                    ),
                    const SizedBox(height: 20),
                    
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
                    const SizedBox(height: 24),

                    // applicant list
                    if (widget.applicants.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('No applicants yet.', style: TextStyle(color: Color(0xFF94A3B8))),
                        ),
                      )
                    else
                      ...widget.applicants.map((a) => _ApplicantRow(applicant: a)),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 12, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, 
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ApplicantRow extends StatelessWidget {
  final Map<String, dynamic> applicant;
  const _ApplicantRow({required this.applicant});

  static const _avatarColors = [
    Color(0xFF6366F1), Color(0xFF0EA5E9), Color(0xFF10B981),
    Color(0xFFEA580C), Color(0xFF8B5CF6), Color(0xFFF43F5E),
  ];

  @override
  Widget build(BuildContext context) {
    final name   = applicant['name']?.toString() ?? 'Unknown';
    final id     = applicant['id']?.toString() ?? 'N/A';
    final dept   = applicant['dept']?.toString() ?? 'CS';
    final status = applicant['status']?.toString() ?? 'Applied';
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
          onTap: () {
            final appId = applicant['application_id']?.toString() ?? '';
            if (appId.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentInfoScreen(
                    applicationId: appId,
                    studentName: name,
                    progress: double.tryParse(applicant['progress']?.toString() ?? '0') ?? 0.0,
                    checkins: applicant['checkins'] as List? ?? [],
                  ),
                ),
              );
            }
          },
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
