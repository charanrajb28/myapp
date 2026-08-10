import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/services/supabase_compat.dart';
import '../models/student_notification.dart';
import '../screens/student/student_portal_repository.dart';
import '../services/fcm_service.dart';

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
  RealtimeChannel? _realtimeSubscription;
  Timer? _pollTimer;
  bool _hasInitialLoaded = false;

  @override
  StudentNotificationsState build() {
    _repository = ref.watch(studentPortalRepositoryProvider);
    // Fetch notifications asynchronously upon initialization
    Future.microtask(() => loadNotifications());
    _setupRealtimeSubscription();
    _startPollingTimer();

    ref.onDispose(() {
      _realtimeSubscription?.unsubscribe();
      _pollTimer?.cancel();
    });

    return StudentNotificationsState(notifications: [], isLoading: false);
  }

  void _startPollingTimer() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _pollNotifications());
  }

  Future<void> _pollNotifications() async {
    try {
      final freshList = await _repository.fetchStudentNotifications();
      if (!_hasInitialLoaded) {
        _hasInitialLoaded = true;
        state = state.copyWith(notifications: freshList);
        return;
      }

      final existingIds = state.notifications.map((n) => n.id).toSet();
      final brandNewUnread = freshList.where((n) => !n.isRead && !existingIds.contains(n.id)).toList();

      for (final item in brandNewUnread) {
        FCMService.showNotification(
          title: item.title,
          body: item.message,
        );
      }

      state = state.copyWith(notifications: freshList);
    } catch (e) {
      debugPrint('Error polling notifications: $e');
    }
  }

  void _setupRealtimeSubscription() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      _realtimeSubscription = Supabase.instance.client
          .channel('public:student_notifications:${user.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'student_notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: user.id,
            ),
            callback: (payload) {
              loadNotifications();
            },
          )
          .subscribe();
    } catch (e) {
      // Ignore if realtime connection fails
    }
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final notifications = await _repository.fetchStudentNotifications();
      _hasInitialLoaded = true;
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
