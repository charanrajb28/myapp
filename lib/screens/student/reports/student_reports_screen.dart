import 'package:flutter/material.dart';

class StudentReportsScreen extends StatefulWidget {
  const StudentReportsScreen({super.key});

  @override
  State<StudentReportsScreen> createState() => _StudentReportsScreenState();
}

class _StudentReportsScreenState extends State<StudentReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  static const _weekly = [
    _Report('Week 8', 'Mar 16, 2025', 'Pending', null),
    _Report('Week 7', 'Mar 9, 2025', 'Reviewed', 'Great progress on the backend module!'),
    _Report('Week 6', 'Mar 2, 2025', 'Reviewed', 'Well structured report, keep it up.'),
    _Report('Week 5', 'Feb 24, 2025', 'Reviewed', null),
    _Report('Week 4', 'Feb 17, 2025', 'Reviewed', null),
  ];

  static const _monthly = [
    _Report('March 2025', 'Mar 31, 2025', 'Upcoming', null),
    _Report('February 2025', 'Feb 28, 2025', 'Reviewed', 'Excellent monthly summary.'),
    _Report('January 2025', 'Jan 31, 2025', 'Reviewed', null),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Reports',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              Container(color: const Color(0xFFE2E8F0), height: 1),
              TabBar(
                controller: _tab,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                unselectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                labelColor: const Color(0xFF0F172A),
                unselectedLabelColor: const Color(0xFF64748B),
                indicatorColor: const Color(0xFF0F172A),
                indicatorWeight: 2.5,
                tabs: const [Tab(text: 'Weekly'), Tab(text: 'Monthly')],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _ReportList(reports: _weekly, isWeekly: true),
          _ReportList(reports: _monthly, isWeekly: false),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
class _Report {
  final String period;
  final String due;
  final String status;
  final String? feedback;
  const _Report(this.period, this.due, this.status, this.feedback);
}

class _ReportList extends StatelessWidget {
  final List<_Report> reports;
  final bool isWeekly;
  const _ReportList({required this.reports, required this.isWeekly});

  Color _statusColor(String s) {
    switch (s) {
      case 'Reviewed':
        return const Color(0xFF10B981);
      case 'Pending':
        return const Color(0xFFF59E0B);
      case 'Upcoming':
        return const Color(0xFF94A3B8);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'Reviewed':
        return Icons.check_circle_rounded;
      case 'Pending':
        return Icons.schedule_rounded;
      case 'Upcoming':
        return Icons.lock_clock_rounded;
      default:
        return Icons.article_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Submit CTA if pending ──
        if (reports.isNotEmpty && reports.first.status == 'Pending')
          _SubmitCTA(report: reports.first, isWeekly: isWeekly),
        if (reports.isNotEmpty && reports.first.status == 'Pending')
          const SizedBox(height: 20),

        const Text(
          'Report History',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),

        ...reports.map((r) => _ReportCard(
              report: r,
              statusColor: _statusColor(r.status),
              statusIcon: _statusIcon(r.status),
            )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
class _SubmitCTA extends StatelessWidget {
  final _Report report;
  final bool isWeekly;
  const _SubmitCTA({required this.report, required this.isWeekly});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.article_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${report.period} Report Due',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Due: ${report.due}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showSubmitSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E40AF),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Submit Report Now',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubmitReportSheet(report: report),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
class _SubmitReportSheet extends StatefulWidget {
  final _Report report;
  const _SubmitReportSheet({required this.report});

  @override
  State<_SubmitReportSheet> createState() => _SubmitReportSheetState();
}

class _SubmitReportSheetState extends State<_SubmitReportSheet> {
  final _summaryController = TextEditingController();
  final _challengesController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _summaryController.dispose();
    _challengesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.article_rounded,
                    color: Color(0xFF3B82F6), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Submit ${widget.report.period} Report',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _fieldLabel('Work Summary'),
          const SizedBox(height: 8),
          _textArea(
            controller: _summaryController,
            hint: 'What did you work on this week?',
          ),
          const SizedBox(height: 16),
          _fieldLabel('Challenges & Learnings'),
          const SizedBox(height: 8),
          _textArea(
            controller: _challengesController,
            hint: 'Describe any challenges you faced...',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting
                  ? null
                  : () async {
                      setState(() => _submitting = true);
                      await Future.delayed(const Duration(milliseconds: 600));
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(children: [
                              Icon(Icons.check_circle_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 10),
                              Text('Report submitted successfully!',
                                  style: TextStyle(fontWeight: FontWeight.w600)),
                            ]),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('Submit Report',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) => Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      );

  Widget _textArea({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      maxLines: 3,
      style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.all(14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF0F172A), width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
class _ReportCard extends StatelessWidget {
  final _Report report;
  final Color statusColor;
  final IconData statusIcon;
  const _ReportCard({
    required this.report,
    required this.statusColor,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.period,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Due: ${report.due}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    report.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (report.feedback != null) ...[
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded,
                      size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '"${report.feedback!}"',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
