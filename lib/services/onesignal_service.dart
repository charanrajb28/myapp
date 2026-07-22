import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Centralized service to manage OneSignal SDK initialization, permissions,
/// identity mapping, tags, and subscriptions.
class OneSignalService {
  static const String appId = 'cc861caf-d431-4c34-973e-e4a00e631d76';

  /// Check if the current platform is supported by onesignal_flutter (iOS & Android)
  static bool get isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static void initialize(BuildContext? context) {
    if (!isSupported) {
      debugPrint('OneSignal: Platform $defaultTargetPlatform is not supported by onesignal_flutter (Mobile iOS/Android only). Skipping initialization.');
      return;
    }

    // 1. Logging configuration
    OneSignal.Debug.setLogLevel(OSLogLevel.warn);

    // 2. SDK Initialization
    OneSignal.initialize(appId);

    // 3. Configure foreground notifications to show in the system tray and prevent duplicates/in-app alerts
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.preventDefault();
      event.notification.display();
    });

    // 4. Prompt for push notification permission
    requestPermission();
  }

  /// Map the logged-in student's UUID to OneSignal's external user ID.
  static Future<void> login(String userId) async {
    if (!isSupported) return;
    try {
      await OneSignal.login(userId);
    } catch (e) {
      debugPrint('OneSignal: Error logging in user $userId: $e');
    }
  }

  /// Remove the mapped user identity on logout.
  static Future<void> logout() async {
    if (!isSupported) return;
    try {
      await OneSignal.logout();
    } catch (e) {
      debugPrint('OneSignal: Error logging out user: $e');
    }
  }

  /// Prompt the user to grant push notification permissions.
  static Future<void> requestPermission() async {
    if (!isSupported) return;
    try {
      await OneSignal.Notifications.requestPermission(true);
    } catch (e) {
      debugPrint('OneSignal: Error requesting push permissions: $e');
    }
  }

  /// Set user tags (e.g. semester, department) for targeted audience targeting.
  static Future<void> sendTag(String key, String value) async {
    if (!isSupported) return;
    try {
      OneSignal.User.addTagWithKey(key, value);
    } catch (e) {
      debugPrint('OneSignal: Error sending tag $key: $value: $e');
    }
  }

  /// Set multiple user tags.
  static Future<void> sendTags(Map<String, String> tags) async {
    if (!isSupported) return;
    try {
      OneSignal.User.addTags(tags);
    } catch (e) {
      debugPrint('OneSignal: Error sending tags $tags: $e');
    }
  }
}
