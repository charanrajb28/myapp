import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RedAlertsScreen extends StatelessWidget {
  const RedAlertsScreen({super.key});
  static const _alertStatuses = ['Removed', 'Completed'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Red Alerts',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFDC2626),
                    size: 28,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Low Progress Alerts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'This list shows removed and completed students ordered by the least progress first.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFB91C1C),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchLowProgressClosedApplications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data ?? const <Map<String, dynamic>>[];
                if (snapshot.hasError || items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 48,
                          color: Color(0xFF10B981),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No Red Alerts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'No removed or completed applications are available for alerts.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _StudentAlertRow(item: item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchLowProgressClosedApplications() async {
    final response = await Supabase.instance.client
        .from('applications')
        .select(
          'id, status, progress, start_date, end_date, created_at, '
          'students(id, name, department, semester), '
          'internships(role, companies(name))',
        )
        .inFilter('status', _alertStatuses)
        .order('progress', ascending: true)
        .order('created_at', ascending: true);

    return (response as List)
        .whereType<Map>()
        .map((raw) => raw.map((key, value) => MapEntry(key.toString(), value)))
        .toList();
  }
}

class _StudentAlertRow extends StatelessWidget {
  final Map<String, dynamic> item;

  const _StudentAlertRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final student = (item['students'] as Map?)?.cast<String, dynamic>() ?? {};

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _AlertDetailScreen(item: item),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFFEF2F2),
                  foregroundColor: const Color(0xFFDC2626),
                  radius: 24,
                  child: Text(
                    _initial(student['name']?.toString()),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    student['name']?.toString() ?? 'Unknown Student',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _initial(String? name) {
    final value = (name ?? '').trim();
    if (value.isEmpty) return 'S';
    return value[0].toUpperCase();
  }
}

class _AlertDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;

  const _AlertDetailScreen({required this.item});

  @override
  Widget build(BuildContext context) {
    final student = (item['students'] as Map?)?.cast<String, dynamic>() ?? {};
    final internship =
        (item['internships'] as Map?)?.cast<String, dynamic>() ?? {};
    final company =
        (internship['companies'] as Map?)?.cast<String, dynamic>() ?? {};
    final status = item['status']?.toString() ?? 'Closed';
    final progressValue = ((item['progress'] as num?) ?? 0).toDouble();
    final progressPercent = (progressValue * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          student['name']?.toString() ?? 'Student Detail',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _AlertCard(
            student: student,
            internship: internship,
            company: company,
            status: status,
            progressPercent: progressPercent,
            dateLabel: _dateLabel(
              item['end_date']?.toString() ??
                  item['start_date']?.toString() ??
                  item['created_at']?.toString(),
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return 'Date unavailable';
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return rawDate;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }
}

class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final Map<String, dynamic> internship;
  final Map<String, dynamic> company;
  final String status;
  final int progressPercent;
  final String dateLabel;

  const _AlertCard({
    required this.student,
    required this.internship,
    required this.company,
    required this.status,
    required this.progressPercent,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFFEF2F2),
                  foregroundColor: const Color(0xFFDC2626),
                  radius: 24,
                  child: Text(
                    _initial(student['name']?.toString()),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name']?.toString() ?? 'Unknown Student',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        internship['role']?.toString() ?? 'Internship Role',
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        company['name']?.toString() ?? 'Unknown Company',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusBadge(status),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _metaPill(
                  icon: Icons.trending_down_rounded,
                  label: 'Progress $progressPercent%',
                  color: const Color(0xFFDC2626),
                ),
                _metaPill(
                  icon: Icons.school_rounded,
                  label: student['semester']?.toString() ?? 'Semester N/A',
                  color: const Color(0xFF6366F1),
                ),
                _metaPill(
                  icon: Icons.calendar_month_rounded,
                  label: dateLabel,
                  color: const Color(0xFF64748B),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Text(
                'Student record is flagged here because the final internship progress is low.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB91C1C),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Color(0xFFDC2626),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _metaPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _initial(String? name) {
    final value = (name ?? '').trim();
    if (value.isEmpty) return 'S';
    return value[0].toUpperCase();
  }

  String _dateLabel(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return 'Closed date N/A';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final day = parsed.day.toString().padLeft(2, '0');
    final month = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][parsed.month - 1];
    return 'Closed $day $month ${parsed.year}';
  }
}
