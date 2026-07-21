import 'package:flutter/material.dart';
import '../../../models/internship.dart';

class StudentInternshipDetailScreen extends StatelessWidget {
  final StudentInternship internship;
  const StudentInternshipDetailScreen({super.key, required this.internship});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Internship Details',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: internship.brandColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        internship.logoInitial,
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: internship.brandColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    internship.role,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    internship.company,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF3B82F6)),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Metadata Row
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  _metaRow(Icons.location_on_rounded, 'Location', internship.location),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                  _metaRow(Icons.payments_rounded, 'Stipend', internship.stipend),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                  _metaRow(Icons.business_center_rounded, 'Department', internship.department),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // About
            _sectionTitle('About the Internship'),
            const SizedBox(height: 12),
            Text(
              internship.about,
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.6),
            ),
            
            const SizedBox(height: 32),
            
            _sectionTitle('Task List'),
            const SizedBox(height: 14),
            if (internship.responsibilities.isEmpty)
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
                  itemCount: internship.responsibilities.length,
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
                              color: internship.brandColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(color: internship.brandColor.withValues(alpha: 0.25)),
                            ),
                            child: Center(
                              child: Text('${index + 1}',
                                  style: TextStyle(color: internship.brandColor, fontSize: 9, fontWeight: FontWeight.w900)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(internship.responsibilities[index],
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
            if (internship.notes.isEmpty)
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
                      child: Text(internship.notes,
                          style: const TextStyle(color: Color(0xFF92400E), fontSize: 13, fontWeight: FontWeight.w500, height: 1.6)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            _sectionTitle('Days Active in the Week'),
            const SizedBox(height: 14),
            if (internship.activeDays.isEmpty)
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
                final sortedDays = allDays.where((d) => internship.activeDays.contains(d)).toList();

                String daysSummary = '';
                if (sortedDays.length == 7) {
                  daysSummary = 'All days — 7 days/week';
                } else if (sortedDays.length == 5 && !internship.activeDays.contains('Sat') && !internship.activeDays.contains('Sun')) {
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
                          final isActive = internship.activeDays.contains(day);
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
    );
  }

  Widget _metaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFE2E8F0).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
            Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w800)),
          ],
        ),
      ],
    );
  }
}
