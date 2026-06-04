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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF64748B)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_outline_rounded, color: Color(0xFF64748B)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header Part ───
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: o.brandColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        o.logoInitial,
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: o.brandColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    o.role,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    o.company,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF3B82F6)),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // ─── Quick Metadata Row ───
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metaItem(Icons.location_on_rounded, 'Location', o.location),
                  _metaItem(Icons.payments_rounded, 'Stipend', o.stipend),
                  _metaItem(Icons.schedule_rounded, 'Duration', o.duration),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // ─── Content Sections ───
            _sectionTitle('About the Internship'),
            const SizedBox(height: 12),
            Text(
              o.about,
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.6, fontWeight: FontWeight.w500),
            ),
            
            const SizedBox(height: 32),
            _sectionTitle('Task List'),
            const SizedBox(height: 14),
            if (o.responsibilities.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text('No tasks specified.',
                    style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: o.responsibilities.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: o.brandColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(color: o.brandColor.withValues(alpha: 0.25)),
                            ),
                            child: Center(
                              child: Text('${index + 1}',
                                  style: TextStyle(color: o.brandColor, fontSize: 9, fontWeight: FontWeight.w900)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(o.responsibilities[index],
                                style: const TextStyle(color: Color(0xFF334155), fontSize: 13, fontWeight: FontWeight.w500, height: 1.5)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 32),
            _sectionTitle('Notes'),
            const SizedBox(height: 14),
            if (o.notes.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text('No notes available.',
                    style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
              )
            else
              Container(
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
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.sticky_note_2_rounded, color: Color(0xFFD97706), size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(o.notes,
                          style: const TextStyle(color: Color(0xFF92400E), fontSize: 13, fontWeight: FontWeight.w500, height: 1.6)),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 32),
            _sectionTitle('Days Active in the Week'),
            const SizedBox(height: 14),
            if (o.activeDays.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text('No active days scheduled.',
                    style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
              )
            else
              Builder(builder: (context) {
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

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: allDays.map((day) {
                          final isActive = o.activeDays.contains(day);
                          final isWeekend = day == 'Sat' || day == 'Sun';
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isActive ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  day.substring(0, isWeekend ? 3 : 1),
                                  style: TextStyle(color: isActive ? Colors.white : const Color(0xFFCBD5E1), fontSize: 10, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFFF1F5F9), height: 1),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 13, color: const Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Text(daysSummary, style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 32), 
            const SizedBox(height: 120), // Bottom padding for fixed button space
          ],

        ),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.3),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 5, height: 5,
            decoration: const BoxDecoration(color: Color(0xFFCBD5E1), shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w800)),
      ],
    );
  }
}
