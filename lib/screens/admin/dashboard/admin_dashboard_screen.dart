import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../feedbacks/admin_feedbacks_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _totalStudents = 0;
  int _partnerCompanies = 0;
  int _activeInternships = 0;
  int _redAlerts = 0;
  bool _isLoading = true;
  bool _isSendingBroadcast = false;

  @override
  void initState() {
    super.initState();
    _fetchDashboardStats();
  }

  Future<void> _fetchDashboardStats() async {
    try {
      final client = Supabase.instance.client;

      // Fetch total students
      final studentsRes = await client.from('students').select('id').count(CountOption.exact);
      final studentsCount = studentsRes.count ?? 0;

      // Fetch partner companies
      final companiesRes = await client.from('companies').select('id').count(CountOption.exact);
      final companiesCount = companiesRes.count ?? 0;

      // Fetch active internships
      final internshipsRes = await client.from('applications').select('id').eq('status', 'Active').count(CountOption.exact);
      final internshipsCount = internshipsRes.count ?? 0;

      // Fetch red alerts count
      int redAlertsCount = 0;
      try {
        final alertsRes = await client.from('red_alerts').select('id').count(CountOption.exact);
        redAlertsCount = alertsRes.count ?? 0;
      } catch (e) {
        // Ignored if table doesnt exist
      }

      if (mounted) {
        setState(() {
          _totalStudents = studentsCount;
          _partnerCompanies = companiesCount;
          _activeInternships = internshipsCount;
          _redAlerts = redAlertsCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showBroadcastDialog() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedType = 'announcement';

    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Broadcast Notification'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'announcement',
                          child: Text('Announcement'),
                        ),
                        DropdownMenuItem(
                          value: 'general',
                          child: Text('General'),
                        ),
                        DropdownMenuItem(
                          value: 'academic',
                          child: Text('Academic'),
                        ),
                        DropdownMenuItem(
                          value: 'message',
                          child: Text('Message'),
                        ),
                        DropdownMenuItem(
                          value: 'interview',
                          child: Text('Interview'),
                        ),
                        DropdownMenuItem(
                          value: 'security',
                          child: Text('Security'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedType = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: messageController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty ||
                        messageController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Title and message are required.'),
                          backgroundColor: Color(0xFFDC2626),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  child: const Text('Send to All'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSend == true) {
      await _sendBroadcastNotification(
        title: titleController.text.trim(),
        message: messageController.text.trim(),
        type: selectedType,
      );
    }

    titleController.dispose();
    messageController.dispose();
  }

  Future<void> _sendBroadcastNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    setState(() => _isSendingBroadcast = true);
    try {
      final client = Supabase.instance.client;
      final studentsRes = await client
          .from('students')
          .select('user_id')
          .not('user_id', 'is', null);

      final userIds = (studentsRes as List)
          .map((item) => item['user_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (userIds.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No students available for broadcast.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
        return;
      }

      final payload = userIds
          .map(
            (userId) => {
              'user_id': userId,
              'title': title,
              'message': message,
              'notification_type': type,
              'is_read': false,
            },
          )
          .toList();

      await client.from('student_notifications').insert(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Broadcast sent to ${userIds.length} students'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to send broadcast: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSendingBroadcast = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Admin Dashboard',
            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Platform Overview',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const SizedBox(height: 24),

                    // Use Wrap so cards size to content and never overflow
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        _StatCard(title: 'Total Students', value: _totalStudents.toString(), icon: Icons.people_alt_rounded, color: const Color(0xFF3B82F6), constraints: constraints),
                        _StatCard(title: 'Partner Companies', value: _partnerCompanies.toString(), icon: Icons.domain_rounded, color: const Color(0xFF8B5CF6), constraints: constraints),
                        _StatCard(title: 'Active Internships', value: _activeInternships.toString(), icon: Icons.work_outline_rounded, color: const Color(0xFF10B981), constraints: constraints),
                        _StatCard(title: 'Red Alerts', value: _redAlerts.toString(), icon: Icons.warning_amber_rounded, color: const Color(0xFFEF4444), constraints: constraints),
                      ],
                    ),
                    
                    const SizedBox(height: 48),

                    Row(
                      children: [
                        const Text('Quick Actions',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        const Spacer(),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFF3B82F6)),
                          child: const Text('View All', style: TextStyle(fontWeight: FontWeight.w700)),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Column(
                      children: [
                        _ActionTile(
                          title: 'Broadcast Notification',
                          subtitle: 'Send one announcement to every student',
                          icon: Icons.campaign_rounded,
                          color: const Color(0xFFEC4899),
                          onTap: _isSendingBroadcast
                              ? () {}
                              : _showBroadcastDialog,
                        ),
                        const SizedBox(height: 12),
                        _ActionTile(
                          title: 'Generate Consent Letters',
                          subtitle: 'Create and batch process student proxy letters',
                          icon: Icons.document_scanner_rounded,
                          color: const Color(0xFF0EA5E9),
                          onTap: () {},
                        ),
                        const SizedBox(height: 12),
                        _ActionTile(
                          title: 'Issue Certificates',
                          subtitle: 'Approve and send final completion certificates',
                          icon: Icons.workspace_premium_rounded,
                          color: const Color(0xFFF59E0B),
                          onTap: () {},
                        ),
                        const SizedBox(height: 12),
                        _ActionTile(
                          title: 'Review Student Reports',
                          subtitle: 'Check weekly & monthly journal submissions',
                          icon: Icons.analytics_rounded,
                          color: const Color(0xFF6366F1),
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // ── Student Feedback Section ──
                    Row(
                      children: [
                        const Text('Recent Student Feedback',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AdminFeedbacksScreen()),
                            );
                          },
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFF3B82F6)),
                          child: const Text('View All', style: TextStyle(fontWeight: FontWeight.w700)),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    _FeedbackList(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final BoxConstraints constraints;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final safeWidth = constraints.maxWidth > 1200 ? 1200.0 : constraints.maxWidth;
    final cardWidth = safeWidth > 900
        ? (safeWidth - 24 * 2 - 14 * 3) / 4 - 0.5
        : safeWidth > 600
            ? (safeWidth - 24 * 2 - 14 * 2) / 3 - 0.5
            : (safeWidth - 24 * 2 - 14) / 2 - 0.5;

    return Container(
      width: cardWidth,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 18, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Stack(
        children: [
          // Background accent blob
          Positioned(
            right: -20, top: -20,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Small mock trend indicator
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.trending_up_rounded, size: 10, color: Color(0xFF10B981)),
                            SizedBox(width: 2),
                            Flexible(child: Text('+12%', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF10B981)), maxLines: 1)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.1, letterSpacing: -0.5),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: color.withValues(alpha: 0.02),
          highlightColor: color.withValues(alpha: 0.05),
          splashColor: color.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
               children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Text(subtitle,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF94A3B8), size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Supabase.instance.client
          .from('feedbacks')
          .select('*, students(name), companies(name)')
          .order('created_at', ascending: false)
          .limit(3),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || (snapshot.data as List).isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.mark_email_read_rounded, size: 48, color: Color(0xFF94A3B8)),
                  SizedBox(height: 16),
                  Text('No Feedbacks Yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  SizedBox(height: 4),
                  Text("Students haven't posted any feedback.", style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          );
        }

        final items = snapshot.data as List;
        return Column(
          children: items.map((f) {
            final date = DateTime.tryParse(f['created_at'].toString()) ?? DateTime.now();
            final now = DateTime.now();
            final difference = now.difference(date).inDays;
            final dateString = difference == 0 ? 'Today' : difference == 1 ? 'Yesterday' : '$difference days ago';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FeedbackTile(
                student: f['students']?['name'] ?? 'Unknown Student',
                company: f['companies']?['name'] ?? 'Unknown Company',
                type: f['type'] ?? 'Suggestion',
                comment: f['comment'] ?? '',
                date: dateString,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}


class _FeedbackTile extends StatelessWidget {
  final String student;
  final String company;
  final String type;
  final String comment;
  final String date;

  const _FeedbackTile({
    required this.student,
    required this.company,
    required this.type,
    required this.comment,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompliment = type == 'Compliment';
    final Color color = isCompliment ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final IconData icon = isCompliment ? Icons.favorite_rounded : Icons.warning_rounded;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
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
                    Text(student,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    Text('at $company',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Text(date,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            comment,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  type.toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
