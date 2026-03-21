import 'package:flutter/material.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  State<StudentNotificationsScreen> createState() => _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState extends State<StudentNotificationsScreen> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      title: 'Course Enrollment Confirmed',
      message: 'You have been successfully enrolled in "Cloud Computing 101".',
      time: '5 min ago',
      type: NotificationType.academic,
      isRead: false,
    ),
    NotificationItem(
      title: 'New Message from Mentor',
      message: 'Ravi Krishnan sent you a message regarding your internship milestones.',
      time: '1 hour ago',
      type: NotificationType.message,
      isRead: false,
    ),
    NotificationItem(
      title: 'Holiday Notice',
      message: 'The university will remain closed on Mar 28 for the festive season.',
      time: '4 hours ago',
      type: NotificationType.announcement,
      isRead: true,
    ),
    NotificationItem(
      title: 'Interview Scheduled',
      message: 'Your interview with Nexus Robotics has been set for Mar 24 at 10 AM.',
      time: '1 day ago',
      type: NotificationType.interview,
      isRead: true,
    ),
    NotificationItem(
      title: 'Security Alert',
      message: 'A new login was detected from a Chrome browser on Windows.',
      time: '2 days ago',
      type: NotificationType.security,
      isRead: true,
    ),
  ];

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
            onPressed: () {
              setState(() {
                for (var n in _notifications) {
                  n.isRead = true;
                }
              });
            },
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
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_none_rounded,
                        size: 40, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We\'ll notify you when something\nimportant happens.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final item = _notifications[index];
                return _NotificationCard(
                  item: item,
                  onTap: () {
                    setState(() {
                      item.isRead = true;
                    });
                  },
                );
              },
            ),
    );
  }
}

enum NotificationType { academic, message, announcement, interview, security }

class NotificationItem {
  final String title;
  final String message;
  final String time;
  final NotificationType type;
  bool isRead;

  NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
  });
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  Color _typeColor(NotificationType type) {
    switch (type) {
      case NotificationType.academic:
        return const Color(0xFF10B981);
      case NotificationType.message:
        return const Color(0xFF3B82F6);
      case NotificationType.announcement:
        return const Color(0xFFF59E0B);
      case NotificationType.interview:
        return const Color(0xFF8B5CF6);
      case NotificationType.security:
        return const Color(0xFFEF4444);
    }
  }

  IconData _typeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.academic:
        return Icons.school_rounded;
      case NotificationType.message:
        return Icons.chat_bubble_rounded;
      case NotificationType.announcement:
        return Icons.campaign_rounded;
      case NotificationType.interview:
        return Icons.event_rounded;
      case NotificationType.security:
        return Icons.security_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.transparent : const Color(0xFFF1F5F9).withValues(alpha: 0.5),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        item.time,
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
                      color: item.isRead ? const Color(0xFF64748B) : const Color(0xFF475569),
                      height: 1.4,
                      fontWeight: item.isRead ? FontWeight.w400 : FontWeight.w500,
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
