import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM: Handling background message ${message.messageId}');
}

/// Centralized Firebase Cloud Messaging service replacing OneSignal.
class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool get isSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static Future<void> initialize(BuildContext? context) async {
    if (!isSupported) return;

    try {
      // 1. Request Push Notification Permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('FCM: Permission status: ${settings.authorizationStatus}');

      // 2. Configure Background Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Setup Local Notifications for Foreground Presentation
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('FCM: Notification tapped in foreground: ${response.payload}');
        },
      );

      // High importance notification channel for Android
      const androidChannel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'Channel used for critical student and posting alerts.',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // Set foreground presentation options
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM: Received foreground message: ${message.notification?.title}');
        final notification = message.notification;
        final android = message.notification?.android;

        if (notification != null && !kIsWeb) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                androidChannel.id,
                androidChannel.name,
                channelDescription: androidChannel.description,
                icon: android?.smallIcon ?? '@mipmap/ic_launcher',
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
          );
        }
      });

      // 5. Handle App Launch from Notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM: App opened from notification: ${message.notification?.title}');
      });

      // 6. Default Topic Subscription
      await subscribeToTopic('all_students');
    } catch (e) {
      debugPrint('FCM Initialization Error: $e');
    }
  }

  /// Subscribe device to an FCM topic (Supported natively on Mobile iOS/Android)
  static Future<void> subscribeToTopic(String topic) async {
    if (!isSupported || kIsWeb) return;
    try {
      final formattedTopic =
          topic.replaceAll(' ', '_').replaceAll('-', '_').toLowerCase();
      await _messaging.subscribeToTopic(formattedTopic);
      debugPrint('FCM: Subscribed to topic $formattedTopic');
    } catch (e) {
      debugPrint('FCM: Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe device from an FCM topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    if (!isSupported || kIsWeb) return;
    try {
      final formattedTopic =
          topic.replaceAll(' ', '_').replaceAll('-', '_').toLowerCase();
      await _messaging.unsubscribeFromTopic(formattedTopic);
      debugPrint('FCM: Unsubscribed from topic $formattedTopic');
    } catch (e) {
      debugPrint('FCM: Error unsubscribing from topic $topic: $e');
    }
  }

  /// Subscribe student to department and semester topics
  static Future<void> subscribeStudentTopics(
      {String? department, String? semester}) async {
    await subscribeToTopic('all_students');
    if (department != null && department.isNotEmpty) {
      await subscribeToTopic('dept_$department');
    }
    if (semester != null && semester.isNotEmpty) {
      await subscribeToTopic('sem_$semester');
    }
  }

  /// Handle user login
  static Future<void> login(String userId) async {
    await subscribeToTopic('all_students');
  }

  /// Handle user logout
  static Future<void> logout() async {
    await unsubscribeFromTopic('all_students');
  }

  /// Get current FCM Token
  static Future<String?> getToken() async {
    if (!isSupported) return null;
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('FCM: Error fetching token: $e');
      return null;
    }
  }
}
