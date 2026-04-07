import 'package:flutter/material.dart';
import 'dart:async';

import '../../../models/student_notification.dart';
import '../student_portal_repository.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  State<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState extends State<StudentNotificationsScreen> {
  final _repository = StudentPortalRepository();
  bool _isLoading = true;
  List<StudentNotification> _notifications = [];

  @override
  void reassemble() {
    super.reassemble();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadNotifications();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final notifications = await _repository
          .fetchStudentNotifications()
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _notifications = [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load notifications: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _repository.markAllNotificationsRead();
      if (!mounted) return;
      setState(() {
        _notifications =
            _notifications.map((n) => n.copyWith(isRead: true)).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update notifications: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _markRead(StudentNotification item) async {
    if (item.isRead) return;
    try {
      await _repository.markNotificationRead(item.id);
      if (!mounted) return;
      setState(() {
        _notifications = _notifications
            .map((notification) => notification.id == item.id
                ? notification.copyWith(isRead: true)
                : notification)
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update notification: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _notifications.isEmpty ? null : _markAllAsRead,
            icon: const Icon(Icons.done_all_rounded, color: Color(0xFF64748B)),
            tooltip: 'Mark all as read',
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const _NotificationsEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final item = _notifications[index];
                    return _NotificationCard(
                      item: item,
                      onTap: () async {
                        await _markRead(item);
                        if (!context.mounted) return;
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                _NotificationDetailScreen(item: item),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

class _NotificationsEmptyState extends StatelessWidget {
  const _NotificationsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 40,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No notifications available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You will see updates here when the admin or system sends one.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final StudentNotification item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  Color _typeColor(StudentNotificationType type) {
    switch (type) {
      case StudentNotificationType.academic:
        return const Color(0xFF10B981);
      case StudentNotificationType.message:
        return const Color(0xFF3B82F6);
      case StudentNotificationType.announcement:
        return const Color(0xFFF59E0B);
      case StudentNotificationType.interview:
        return const Color(0xFF8B5CF6);
      case StudentNotificationType.security:
        return const Color(0xFFEF4444);
      case StudentNotificationType.general:
        return const Color(0xFF64748B);
    }
  }

  IconData _typeIcon(StudentNotificationType type) {
    switch (type) {
      case StudentNotificationType.academic:
        return Icons.school_rounded;
      case StudentNotificationType.message:
        return Icons.chat_bubble_rounded;
      case StudentNotificationType.announcement:
        return Icons.campaign_rounded;
      case StudentNotificationType.interview:
        return Icons.event_rounded;
      case StudentNotificationType.security:
        return Icons.security_rounded;
      case StudentNotificationType.general:
        return Icons.notifications_active_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel = _typeLabel(item.type);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: item.isRead
              ? Colors.transparent
              : const Color(0xFFF1F5F9).withValues(alpha: 0.5),
          border: const Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _typeColor(item.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _typeIcon(item.type),
                    color: _typeColor(item.type),
                    size: 24,
                  ),
                ),
                if (!item.isRead)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _typeColor(item.type).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          typeLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: _typeColor(item.type),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                item.isRead ? FontWeight.w600 : FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Text(
                        item.timeLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: item.isRead
                          ? const Color(0xFF64748B)
                          : const Color(0xFF475569),
                      height: 1.4,
                      fontWeight:
                          item.isRead ? FontWeight.w400 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(StudentNotificationType type) {
    switch (type) {
      case StudentNotificationType.academic:
        return 'Academic';
      case StudentNotificationType.message:
        return 'Message';
      case StudentNotificationType.announcement:
        return 'Announcement';
      case StudentNotificationType.interview:
        return 'Interview';
      case StudentNotificationType.security:
        return 'Security';
      case StudentNotificationType.general:
        return 'General';
    }
  }
}

class _NotificationDetailScreen extends StatelessWidget {
  final StudentNotification item;

  const _NotificationDetailScreen({required this.item});

  @override
  Widget build(BuildContext context) {
    final accent = _typeColor(item.type);
    final typeLabel = _typeLabel(item.type);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF64748B)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.14),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withValues(alpha: 0.18)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: accent.withValues(alpha: 0.20)),
                        ),
                        child: Icon(
                          _typeIcon(item.type),
                          color: accent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _metaChip(
                                  icon: Icons.label_rounded,
                                  label: typeLabel,
                                  color: accent,
                                ),
                                _metaChip(
                                  icon: Icons.schedule_rounded,
                                  label: item.timeLabel,
                                  color: const Color(0xFF64748B),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('MESSAGE'),
                  const SizedBox(height: 10),
                  Text(
                    item.message,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.75,
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
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

  Widget _sectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          color: const Color(0xFF0F172A),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF94A3B8),
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  static Color _typeColor(StudentNotificationType type) {
    switch (type) {
      case StudentNotificationType.academic:
        return const Color(0xFF10B981);
      case StudentNotificationType.message:
        return const Color(0xFF3B82F6);
      case StudentNotificationType.announcement:
        return const Color(0xFFF59E0B);
      case StudentNotificationType.interview:
        return const Color(0xFF8B5CF6);
      case StudentNotificationType.security:
        return const Color(0xFFEF4444);
      case StudentNotificationType.general:
        return const Color(0xFF64748B);
    }
  }

  static IconData _typeIcon(StudentNotificationType type) {
    switch (type) {
      case StudentNotificationType.academic:
        return Icons.school_rounded;
      case StudentNotificationType.message:
        return Icons.chat_bubble_rounded;
      case StudentNotificationType.announcement:
        return Icons.campaign_rounded;
      case StudentNotificationType.interview:
        return Icons.event_rounded;
      case StudentNotificationType.security:
        return Icons.security_rounded;
      case StudentNotificationType.general:
        return Icons.notifications_active_rounded;
    }
  }

  static String _typeLabel(StudentNotificationType type) {
    switch (type) {
      case StudentNotificationType.academic:
        return 'Academic';
      case StudentNotificationType.message:
        return 'Message';
      case StudentNotificationType.announcement:
        return 'Announcement';
      case StudentNotificationType.interview:
        return 'Interview';
      case StudentNotificationType.security:
        return 'Security';
      case StudentNotificationType.general:
        return 'General';
    }
  }
}
