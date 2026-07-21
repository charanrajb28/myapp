import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../alerts/red_alerts_screen.dart';
import '../feedbacks/admin_feedbacks_screen.dart';
import '../admins/admins_list_screen.dart';
import '../internships/admin_internships_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const AdminDashboardScreen({super.key, this.onNavigateToTab});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _totalStudents = 0;
  int _partnerCompanies = 0;
  int _totalInternships = 0;
  int _redAlerts = 0;
  bool _isLoading = true;
  bool _isSendingBroadcast = false;
  String _userRole = 'admin';

  @override
  void initState() {
    super.initState();
    _fetchDashboardStats();
  }

  Future<void> _fetchDashboardStats() async {
    try {
      final client = Supabase.instance.client;

      if (client.auth.currentUser == null) {
        if (mounted) {
          setState(() {
            _totalStudents = 142;
            _partnerCompanies = 28;
            _totalInternships = 35;
            _redAlerts = 3;
            _userRole = 'admin';
            _isLoading = false;
          });
        }
        return;
      }

      // Fetch total students
      final studentsRes = await client.from('students').select('id').count(CountOption.exact);
      final studentsCount = studentsRes.count;

      // Fetch partner companies
      final companiesRes = await client.from('companies').select('id').count(CountOption.exact);
      final companiesCount = companiesRes.count;

      // Fetch total internships
      final internshipsRes = await client.from('internships').select('id').count(CountOption.exact);
      final internshipsCount = internshipsRes.count;

      final redAlertsRes = await client
          .from('applications')
          .select('id')
          .inFilter('status', ['Removed', 'Completed'])
          .lt('progress', 1.0)
          .count(CountOption.exact);
      final redAlertsCount = redAlertsRes.count;

      // Fetch current admin user role details
      String fetchedRole = 'sub_admin';
      final user = client.auth.currentUser;
      if (user != null) {
        final userRes = await client.from('users').select('role').eq('id', user.id).single();
        fetchedRole = userRes['role']?.toString() ?? 'sub_admin';
      }

      if (mounted) {
        setState(() {
          _totalStudents = studentsCount;
          _partnerCompanies = companiesCount;
          _totalInternships = internshipsCount;
          _redAlerts = redAlertsCount;
          _userRole = fetchedRole;
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
      final user = client.auth.currentUser;
      String senderName = 'System Admin';
      if (user != null) {
        final adminRes = await client
            .from('sub_admins')
            .select('users!sub_admins_user_id_fkey(name)')
            .eq('user_id', user.id)
            .maybeSingle();
        if (adminRes != null && adminRes['users'] != null) {
          senderName = adminRes['users']['name']?.toString() ?? 'System Admin';
        }
      }

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

      await Future.wait(
        userIds.map(
          (userId) => client.from('student_notifications').insert({
            'user_id': userId,
            'title': title,
            'message': message,
            'notification_type': type,
            'is_read': false,
            'sender_name': senderName,
          }),
        ),
      );

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
                        _StatCard(
                          title: 'Total Students',
                          value: _totalStudents.toString(),
                          icon: Icons.people_alt_rounded,
                          color: const Color(0xFF3B82F6),
                          constraints: constraints,
                          onTap: widget.onNavigateToTab != null
                              ? () => widget.onNavigateToTab!(1)
                              : null,
                        ),
                        _StatCard(
                          title: 'Partner Companies',
                          value: _partnerCompanies.toString(),
                          icon: Icons.domain_rounded,
                          color: const Color(0xFF8B5CF6),
                          constraints: constraints,
                          onTap: widget.onNavigateToTab != null
                              ? () => widget.onNavigateToTab!(2)
                              : null,
                        ),
                         _StatCard(
                          title: 'Total Internships',
                          value: _totalInternships.toString(),
                          icon: Icons.work_outline_rounded,
                          color: const Color(0xFF10B981),
                          constraints: constraints,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminInternshipsScreen(),
                              ),
                            );
                          },
                        ),
                        _StatCard(
                          title: 'Red Alerts',
                          value: _redAlerts.toString(),
                          icon: Icons.warning_amber_rounded,
                          color: const Color(0xFFEF4444),
                          constraints: constraints,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RedAlertsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 48),

                    Row(
                      children: [
                        const Text('Quick Actions',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
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
                          title: 'Student Feedbacks',
                          subtitle: 'Check feedbacks from students',
                          icon: Icons.feedback_rounded,
                          color: const Color(0xFF6366F1),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AdminFeedbacksScreen()),
                            );
                          },
                        ),
                        if (_userRole == 'admin') ...[
                          const SizedBox(height: 12),
                          _ActionTile(
                            title: 'View Admins',
                            subtitle: 'Manage administrative users and assistant credentials',
                            icon: Icons.admin_panel_settings_rounded,
                            color: const Color(0xFF8B5CF6),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AdminsListScreen()),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
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
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.constraints,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final safeWidth = constraints.maxWidth > 1200 ? 1200.0 : constraints.maxWidth;
    final cardWidth = safeWidth > 900
        ? (safeWidth - 24 * 2 - 14 * 3) / 4 - 0.5
        : safeWidth > 600
            ? (safeWidth - 24 * 2 - 14 * 2) / 3 - 0.5
            : (safeWidth - 24 * 2 - 14) / 2 - 0.5;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: cardWidth,
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
        ),
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

