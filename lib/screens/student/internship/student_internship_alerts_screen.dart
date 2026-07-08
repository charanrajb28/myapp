import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/internship.dart';

class StudentInternshipAlertsScreen extends StatefulWidget {
  final StudentInternship internship;

  const StudentInternshipAlertsScreen({super.key, required this.internship});

  @override
  State<StudentInternshipAlertsScreen> createState() =>
      _StudentInternshipAlertsScreenState();
}

class _StudentInternshipAlertsScreenState
    extends State<StudentInternshipAlertsScreen> {
  late List<Map<String, dynamic>> _alerts;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _alerts = widget.internship.alerts
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _buildAlerts();

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
              'Internship Alerts',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            Text(
              '${widget.internship.company}  •  ${widget.internship.role}',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: alerts.isEmpty
          ? _emptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: alerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return _alertItem(
                  alert: alert,
                );
              },
            ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF94A3B8),
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No internship alerts available',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This internship does not have any active updates or action items right now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertItem({required _InternshipAlert alert}) {
    return Container(
      decoration: BoxDecoration(
        color: alert.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: alert.color.withValues(alpha: 0.1)),
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
                    color: alert.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(alert.icon, color: alert.color, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        alert.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: alert.color,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  alert.timeLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              alert.message,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (alert.requiresAcknowledgement) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting || alert.isAcknowledged
                      ? null
                      : () => _acknowledgeCertificate(alert),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: alert.isAcknowledged
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF0F172A),
                    foregroundColor: alert.isAcknowledged
                        ? const Color(0xFF64748B)
                        : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    alert.isAcknowledged
                        ? 'CERTIFICATE RECEIVED'
                        : 'I RECEIVED THE CERTIFICATE',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<_InternshipAlert> _buildAlerts() {
    return _alerts
        .map(_mapStoredAlert)
        .whereType<_InternshipAlert>()
        .toList();
  }

  _InternshipAlert? _mapStoredAlert(Map<String, dynamic> raw) {
    final title = _firstNonEmpty(
      raw['title'],
      raw['subject'],
      raw['heading'],
    ) ??
        'Company Alert';
    final message = _firstNonEmpty(
      raw['message'],
      raw['body'],
      raw['description'],
      raw['content'],
    );

    if (title == null || message == null) {
      return null;
    }

    final type = _firstNonEmpty(raw['type'], raw['level'], raw['category']) ??
        'Update';
    final status = _firstNonEmpty(raw['status'], raw['severity']) ?? type;
    final timeSource = _firstNonEmpty(
      raw['time'],
      raw['timeLabel'],
      raw['timestamp'],
      raw['created_at'],
      raw['createdAt'],
    );
    final timeLabel = _formatAlertTime(timeSource);
    final requiresAcknowledgement = raw['requires_ack'] == true;
    final isAcknowledged = raw['acknowledged'] == true;

    return _InternshipAlert(
      id: raw['id']?.toString() ?? '',
      title: title,
      message: message,
      type: type,
      icon: _iconForAlert(status),
      color: _colorForAlert(status),
      timeLabel: timeLabel,
      requiresAcknowledgement: requiresAcknowledgement,
      isAcknowledged: isAcknowledged,
    );
  }

  Future<void> _acknowledgeCertificate(_InternshipAlert alert) async {
    try {
      setState(() => _isSubmitting = true);
      final now = DateTime.now().toUtc().toIso8601String();
      final updatedAlerts = _alerts.map((item) {
        if (item['id']?.toString() != alert.id) {
          return Map<String, dynamic>.from(item);
        }
        return {
          ...Map<String, dynamic>.from(item),
          'acknowledged': true,
          'acknowledged_at': now,
          'status': 'completed',
        };
      }).toList();

      await Supabase.instance.client
          .from('applications')
          .update({
            'alerts': updatedAlerts,
            'status': 'Completed',
          })
          .eq('id', widget.internship.applicationId);

      if (!mounted) return;
      setState(() {
        _alerts = updatedAlerts;
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Certificate receipt confirmed'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to confirm certificate receipt: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  String? _firstNonEmpty(
    dynamic a, [
    dynamic b,
    dynamic c,
    dynamic d,
    dynamic e,
  ]) {
    final values = [a, b, c, d, e];
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  String _formatAlertTime(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) {
      return 'Recent';
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }

    final diff = DateTime.now().difference(parsed.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    final day = parsed.day.toString().padLeft(2, '0');
    final month = _monthShort(parsed.month);
    return '$day $month';
  }

  String _monthShort(int month) {
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
    return months[(month - 1).clamp(0, 11)];
  }

  IconData _iconForAlert(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'urgent':
      case 'high':
      case 'critical':
        return Icons.warning_amber_rounded;
      case 'action':
      case 'pending':
        return Icons.assignment_late_rounded;
      case 'success':
      case 'completed':
        return Icons.task_alt_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'removed':
        return Icons.person_remove_alt_1_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _colorForAlert(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'urgent':
      case 'high':
      case 'critical':
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'action':
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'success':
      case 'completed':
        return const Color(0xFF10B981);
      case 'removed':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF3B82F6);
    }
  }
}

class _InternshipAlert {
  final String id;
  final String title;
  final String message;
  final String type;
  final IconData icon;
  final Color color;
  final String timeLabel;
  final bool requiresAcknowledgement;
  final bool isAcknowledged;

  const _InternshipAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.icon,
    required this.color,
    required this.timeLabel,
    this.requiresAcknowledgement = false,
    this.isAcknowledged = false,
  });
}
