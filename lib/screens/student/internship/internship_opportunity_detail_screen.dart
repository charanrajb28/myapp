import 'package:flutter/material.dart';
import '../../../models/internship.dart';
import '../student_portal_repository.dart';

class InternshipOpportunityDetailScreen extends StatefulWidget {
  final InternshipOpportunity opportunity;
  const InternshipOpportunityDetailScreen({super.key, required this.opportunity});

  @override
  State<InternshipOpportunityDetailScreen> createState() => _InternshipOpportunityDetailScreenState();
}

class _InternshipOpportunityDetailScreenState extends State<InternshipOpportunityDetailScreen> {
  final _repository = StudentPortalRepository();
  bool _isApplying = false;
  bool _isApplied = false;

  @override
  void initState() {
    super.initState();
    _isApplied = widget.opportunity.isApplied ?? false;
  }

  void _handleEasyApply() async {
    setState(() => _isApplying = true);

    try {
      final applied = await _repository.applyForInternship(widget.opportunity);

      if (!mounted) return;

      setState(() {
        _isApplying = false;
        _isApplied = true;
      });

      if (applied) {
        _showSuccessFeedback();
        Navigator.of(context).pop(true);
      } else {
        _showInfoFeedback('You have already applied to ${widget.opportunity.company}.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isApplying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to apply: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  void _showSuccessFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 12),
            Expanded(child: Text('Successfully applied to ${widget.opportunity.company}!')),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF10B981),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  void _showInfoFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.opportunity;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B), size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.bookmark_outline_rounded, color: Color(0xFF1E293B), size: 18),
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      o.brandColor.withValues(alpha: 0.15),
                      o.brandColor.withValues(alpha: 0.02),
                      const Color(0xFFF8FAFC)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 88, height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: o.brandColor.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8))
                        ],
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: Text(
                          o.logoInitial,
                          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: o.brandColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(
                          o.role,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5, height: 1.2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          o.company,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: o.brandColor, letterSpacing: 0.2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(child: _buildInfoCard(Icons.location_on_rounded, 'Location', o.location, const Color(0xFF3B82F6))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoCard(Icons.payments_rounded, 'Stipend', o.stipend, const Color(0xFF10B981))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildInfoCard(Icons.schedule_rounded, 'Duration', o.duration, const Color(0xFFF59E0B))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoCard(Icons.groups_rounded, 'Vacancies', '${o.vacancies} Openings', const Color(0xFF8B5CF6))),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSectionCard(
                    title: 'About the Internship',
                    icon: Icons.info_outline_rounded,
                    child: Text(
                      o.about,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.6, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'Task List',
                    icon: Icons.task_alt_rounded,
                    child: _buildTasksList(o),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'Important Notes',
                    icon: Icons.sticky_note_2_outlined,
                    child: _buildNotesList(o),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'Eligible Departments',
                    icon: Icons.school_rounded,
                    child: _buildEligibleDepartmentsList(o),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'Active Days',
                    icon: Icons.calendar_month_rounded,
                    child: _buildActiveDaysList(o),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, -10)),
          ],
        ),
        child: SafeArea(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 52,
            child: ElevatedButton(
              onPressed: (_isApplying || _isApplied) ? null : _handleEasyApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isApplied ? const Color(0xFF10B981) : const Color(0xFF0F172A),
                disabledBackgroundColor: _isApplied ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isApplying 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isApplied ? Icons.check_circle_rounded : Icons.bolt_rounded, size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        _isApplied ? 'APPLIED' : 'EASY APPLY',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8),
                      ),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(width: 14),
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.3)),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildTasksList(InternshipOpportunity o) {
    if (o.responsibilities.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text('No tasks specified.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500)),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: o.responsibilities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: o.brandColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text('${index + 1}', style: TextStyle(color: o.brandColor, fontSize: 11, fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(o.responsibilities[index], style: const TextStyle(color: Color(0xFF475569), fontSize: 14, fontWeight: FontWeight.w500, height: 1.5)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotesList(InternshipOpportunity o) {
    if (o.notes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text('No notes available.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500)),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(o.notes, style: const TextStyle(color: Color(0xFF92400E), fontSize: 14, fontWeight: FontWeight.w600, height: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEligibleDepartmentsList(InternshipOpportunity o) {
    if (o.eligibleDepartments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text('Open to all departments.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: o.eligibleDepartments.map((dept) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF6366F1)),
              const SizedBox(width: 6),
              Text(
                dept,
                style: const TextStyle(
                  color: Color(0xFF4338CA),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActiveDaysList(InternshipOpportunity o) {
    if (o.activeDays.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text('No active days scheduled.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500)),
      );
    }

    const allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sortedDays = allDays.where((d) => o.activeDays.contains(d)).toList();

    String daysSummary = '';
    if (sortedDays.length == 7) {
      daysSummary = 'All days — 7 days/week';
    } else if (sortedDays.length == 5 && !o.activeDays.contains('Sat') && !o.activeDays.contains('Sun')) {
      daysSummary = 'Monday to Friday — 5 days/week';
    } else {
      daysSummary = '${sortedDays.join(', ')} — ${sortedDays.length} day${sortedDays.length == 1 ? '' : 's'}/week';
    }

    return Column(
      children: [
        Row(
          children: allDays.map((day) {
            final isActive = o.activeDays.contains(day);
            final isWeekend = day == 'Sat' || day == 'Sun';
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isActive ? [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
                ),
                child: Center(
                  child: Text(
                    day.substring(0, isWeekend ? 3 : 1),
                    style: TextStyle(color: isActive ? Colors.white : const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF15803D)),
              const SizedBox(width: 10),
              Text(daysSummary, style: const TextStyle(color: Color(0xFF15803D), fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}
