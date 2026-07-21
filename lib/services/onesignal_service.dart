import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Centralized service to manage OneSignal SDK initialization, permissions,
/// identity mapping, tags, and subscriptions.
class OneSignalService {
  static const String appId = 'cc861caf-d431-4c34-973e-e4a00e631d76';
  static bool _hasShownVerificationDialog = false;

  /// Check if the current platform is supported by onesignal_flutter (iOS & Android)
  static bool get isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Initializes the OneSignal SDK, sets the logging level, and hooks up observers.
  static void initialize(BuildContext? context) {
    if (!isSupported) {
      debugPrint('OneSignal: Platform $defaultTargetPlatform is not supported by onesignal_flutter (Mobile iOS/Android only). Skipping initialization.');
      return;
    }

    // 1. Logging configuration
    OneSignal.Debug.setLogLevel(OSLogLevel.warn);

    // 2. Register push subscription observer for verification dialog
    _registerSubscriptionObserver(context);

    // 3. SDK Initialization
    OneSignal.initialize(appId);
  }

  /// Register push subscription observer to verify subscription and present verification dialog.
  static void _registerSubscriptionObserver(BuildContext? context) {
    void checkSubscription(String? subscriptionId) {
      if (subscriptionId == null ||
          subscriptionId.isEmpty ||
          subscriptionId.startsWith('local-')) {
        return;
      }

      if (_hasShownVerificationDialog) return;
      _hasShownVerificationDialog = true;

      if (context != null && context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Your OneSignal SDK integration is complete!'),
            content: const Text(
              'You can now send Push Notifications & In-App Messages through OneSignal. Tap below to enable push notifications.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  requestPermission();
                },
                child: const Text('Got it'),
              ),
            ],
          ),
        );
      }
    }

    // Check immediate current status
    final currentId = OneSignal.User.pushSubscription.id;
    checkSubscription(currentId);

    // Observe changes
    OneSignal.User.pushSubscription.addObserver((state) {
      checkSubscription(state.current.id);
    });
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
