import 'package:flutter/material.dart';
import '../../../models/internship.dart';

class StudentInternshipAlertsScreen extends StatelessWidget {
  final StudentInternship internship;
  const StudentInternshipAlertsScreen({super.key, required this.internship});

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Company Alerts',
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18),
            ),
            Text(
              internship.company,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _alertItem(
            context,
            title: 'Attendance Report Overdue',
            message: 'Your weekly attendance for the final phase of ${internship.role} is overdue by 2 days.',
            type: 'Urgent',
            icon: Icons.error_rounded,
            color: const Color(0xFFEF4444),
            time: '2 hours ago',
          ),
          const SizedBox(height: 16),
          _alertItem(
            context,
            title: 'Action Item: Performance Review',
            message: 'A final performance review has been scheduled by your mentor, ${internship.mentorName}.',
            type: 'Action',
            icon: Icons.assignment_late_rounded,
            color: const Color(0xFFF59E0B),
            time: '1 day ago',
          ),
          const SizedBox(height: 16),
          _alertItem(
            context,
            title: 'Policy Change Reminder',
            message: 'Reminder regarding the company policy update for the ${internship.department} department.',
            type: 'Info',
            icon: Icons.info_rounded,
            color: const Color(0xFF3B82F6),
            time: 'Mar 20',
          ),
        ],
      ),
    );
  }

  Widget _alertItem(
    BuildContext context, {
    required String title,
    required String message,
    required String type,
    required IconData icon,
    required Color color,
    required String time,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.3),
                      ),
                      Text(
                        type.toUpperCase(),
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.0),
                      ),
                    ],
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.5, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );

  }
}
