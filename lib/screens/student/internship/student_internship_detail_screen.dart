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
            
            // Mentor info (unique to active)
            _sectionTitle('Mentor & Support'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [internship.brandColor.withValues(alpha: 0.05), Colors.white],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: internship.brandColor.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: internship.brandColor.withValues(alpha: 0.2),
                    child: Icon(Icons.person_rounded, color: internship.brandColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          internship.mentorName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          internship.mentorEmail,
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.mail_rounded, color: internship.brandColor, size: 20),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            
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
