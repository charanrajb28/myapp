enum StudentNotificationType {
  academic,
  message,
  announcement,
  interview,
  security,
  general,
}

class StudentNotification {
  final String id;
  final String title;
  final String message;
  final String timeLabel;
  final StudentNotificationType type;
  final bool isRead;
  final String sender;

  const StudentNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timeLabel,
    required this.type,
    required this.isRead,
    this.sender = 'System Admin',
  });

  StudentNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? timeLabel,
    StudentNotificationType? type,
    bool? isRead,
    String? sender,
  }) {
    return StudentNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timeLabel: timeLabel ?? this.timeLabel,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      sender: sender ?? this.sender,
    );
  }
}
