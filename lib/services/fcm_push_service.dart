import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import '../utils/device_session_helper.dart';
import 'turso_database_service.dart';

class FcmPushService {
  static const _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
  static AuthClient? _authClient;
  static String? _projectId;

  /// Saves the current device's FCM token to TursoDB for the logged-in user
  static Future<void> saveUserFcmToken(String userId) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      debugPrint('🔑 FCM Token obtained for $userId: $fcmToken');

      // Update user table
      await TursoDatabaseService.instance.execute(
        'UPDATE users SET fcm_token = ? WHERE id = ?',
        [fcmToken, userId],
      );

      // Update active device session table
      final deviceToken = await getOrCreateDeviceToken();
      await TursoDatabaseService.instance.execute(
        '''
        UPDATE user_device_sessions 
        SET fcm_token = ? 
        WHERE user_id = ? AND device_token = ? AND is_active = 1
        ''',
        [fcmToken, userId, deviceToken],
      );
    } catch (e) {
      debugPrint('⚠️ Error saving FCM token: $e');
    }
  }

  static const String _b64Env = String.fromEnvironment('FCM_SERVICE_ACCOUNT_B64');
  static const String _jsonEnv = String.fromEnvironment('FCM_SERVICE_ACCOUNT_JSON');

  /// Initialize authenticated OAuth2 HTTP Client using environment variables or fallback file
  static Future<AuthClient?> _getAuthClient() async {
    if (_authClient != null) return _authClient;

    try {
      String jsonString = '';
      if (_b64Env.isNotEmpty) {
        jsonString = utf8.decode(base64.decode(_b64Env));
      } else if (_jsonEnv.isNotEmpty) {
        jsonString = _jsonEnv;
      } else {
        try {
          jsonString = await rootBundle.loadString('assets/service_account.json');
        } catch (_) {
          jsonString = '';
        }
      }

      if (jsonString.isEmpty) {
        debugPrint('❌ FCM Service Account credentials not provided in environment or assets.');
        return null;
      }

      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      _projectId = jsonMap['project_id']?.toString() ?? 'aaroha-af3cb';

      final credentials = ServiceAccountCredentials.fromJson(jsonMap);
      _authClient = await clientViaServiceAccount(credentials, _scopes);
      return _authClient;
    } catch (e) {
      debugPrint('❌ Error loading service account credentials: $e');
      return null;
    }
  }

  /// Sends a native Android heads-up push notification to a specific user via FCM HTTP v1 API
  static Future<bool> sendToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // Find FCM token(s) for the target user from user_device_sessions or users table
      final sessionRows = await TursoDatabaseService.instance.query(
        '''
        SELECT fcm_token FROM user_device_sessions 
        WHERE user_id = ? AND is_active = 1 AND fcm_token IS NOT NULL AND fcm_token != ''
        ''',
        [userId],
      );

      List<String> fcmTokens = sessionRows
          .map((r) => r['fcm_token']?.toString() ?? '')
          .where((t) => t.isNotEmpty)
          .toList();

      if (fcmTokens.isEmpty) {
        final userRow = await TursoDatabaseService.instance.querySingle(
          'SELECT fcm_token FROM users WHERE id = ? AND fcm_token IS NOT NULL AND fcm_token != \'\'',
          [userId],
        );
        final token = userRow?['fcm_token']?.toString();
        if (token != null && token.isNotEmpty) {
          fcmTokens.add(token);
        }
      }

      if (fcmTokens.isEmpty) {
        debugPrint('⚠️ No FCM Token found for user $userId to send push notification.');
        return false;
      }

      bool success = false;
      for (final token in fcmTokens) {
        final sent = await sendToToken(
          token: token,
          title: title,
          body: body,
          data: data,
        );
        if (sent) success = true;
      }
      return success;
    } catch (e) {
      debugPrint('❌ Error sending FCM push to user $userId: $e');
      return false;
    }
  }

  /// Sends push notification directly to a specific FCM device token
  static Future<bool> sendToToken({
    required String token,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    final client = await _getAuthClient();
    if (client == null || _projectId == null) {
      debugPrint('❌ FCM AuthClient initialization failed.');
      return false;
    }

    final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$_projectId/messages:send');

    final payload = {
      'message': {
        'token': token,
        'notification': {
          'title': title,
          'body': body,
        },
        'android': {
          'priority': 'HIGH',
          'notification': {
            'channel_id': 'high_importance_channel',
            'sound': 'default',
            'default_vibrate_timings': true,
            'notification_priority': 'PRIORITY_MAX',
            'visibility': 'PUBLIC',
          },
        },
        'data': data ?? {'click_action': 'FLUTTER_NOTIFICATION_CLICK'},
      }
    };

    try {
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM HTTP v1 push sent successfully to token: ${token.substring(0, 10)}...');
        return true;
      } else {
        debugPrint('❌ FCM HTTP v1 error (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending FCM payload: $e');
      return false;
    }
  }

  /// Sends a push notification broadcast to an FCM topic (e.g., 'all_students')
  static Future<bool> sendToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    final client = await _getAuthClient();
    if (client == null || _projectId == null) return false;

    final formattedTopic = topic.replaceAll(' ', '_').replaceAll('-', '_').toLowerCase();
    final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$_projectId/messages:send');

    final payload = {
      'message': {
        'topic': formattedTopic,
        'notification': {
          'title': title,
          'body': body,
        },
        'android': {
          'priority': 'HIGH',
          'notification': {
            'channel_id': 'high_importance_channel',
            'sound': 'default',
            'default_vibrate_timings': true,
            'notification_priority': 'PRIORITY_MAX',
            'visibility': 'PUBLIC',
          },
        },
        'data': data ?? {'click_action': 'FLUTTER_NOTIFICATION_CLICK'},
      }
    };

    try {
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM HTTP v1 broadcast sent to topic: $formattedTopic');
        return true;
      } else {
        debugPrint('❌ FCM Topic push error (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending FCM topic push: $e');
      return false;
    }
  }
}
