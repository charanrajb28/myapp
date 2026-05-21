import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student_notification.dart';
import '../screens/student/student_portal_repository.dart';

class StudentNotificationsState {
  final List<StudentNotification> notifications;
  final bool isLoading;
  final String? errorMessage;

  StudentNotificationsState({
    required this.notifications,
    required this.isLoading,
    this.errorMessage,
  });

  StudentNotificationsState copyWith({
    List<StudentNotification>? notifications,
    bool? isLoading,
    String? errorMessage,
  }) {
    return StudentNotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class StudentNotificationsNotifier extends Notifier<StudentNotificationsState> {
  late final StudentPortalRepository _repository;

  @override
  StudentNotificationsState build() {
    _repository = ref.watch(studentPortalRepositoryProvider);
    // Fetch notifications asynchronously upon initialization
    Future.microtask(() => loadNotifications());
    return StudentNotificationsState(notifications: [], isLoading: false);
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final notifications = await _repository.fetchStudentNotifications();
      state = state.copyWith(notifications: notifications, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllNotificationsRead();
      state = state.copyWith(
        notifications: state.notifications.map((n) => n.copyWith(isRead: true)).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markNotificationRead(id);
      state = state.copyWith(
        notifications: state.notifications.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }
}

final studentPortalRepositoryProvider = Provider<StudentPortalRepository>((ref) {
  return StudentPortalRepository();
});

final studentNotificationsProvider = NotifierProvider.autoDispose<StudentNotificationsNotifier, StudentNotificationsState>(() {
  return StudentNotificationsNotifier();
});
