import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final notifications = [
      {
        'icon': Icons.check_circle_outline,
        'title': 'Application Sent',
        'subtitle': 'Your application to Google has been sent.',
        'time': '2h ago',
        'color': Colors.green,
      },
      {
        'icon': Icons.mark_email_read_outlined,
        'title': 'Application Viewed',
        'subtitle': 'Your application to Facebook has been viewed.',
        'time': '1d ago',
        'color': Colors.blue,
      },
      {
        'icon': Icons.calendar_today_outlined,
        'title': 'Interview Scheduled',
        'subtitle': 'You have an interview with Amazon tomorrow at 10:00 AM.',
        'time': '3d ago',
        'color': Colors.orange,
      },
      {
        'icon': Icons.cancel_outlined,
        'title': 'Application Rejected',
        'subtitle': 'Your application to Apple has been rejected.',
        'time': '5d ago',
        'color': Colors.red,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20.0),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationTile(context, notification, theme);
        },
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, Map<String, dynamic> notification, ThemeData theme) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: (notification['color'] as Color).withOpacity(0.1),
        child: Icon(
          notification['icon'] as IconData,
          color: notification['color'] as Color,
        ),
      ),
      title: Text(
        notification['title'] as String,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        notification['subtitle'] as String,
        style: theme.textTheme.bodyMedium,
      ),
      trailing: Text(
        notification['time'] as String,
        style: theme.textTheme.bodySmall,
      ),
    );
  }
}
