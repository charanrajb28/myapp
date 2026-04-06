import 'package:flutter/material.dart';

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
    _notifications = [];
    _isLoading = true;
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await _repository.fetchStudentNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
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
                      onTap: () => _markRead(item),
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
}
