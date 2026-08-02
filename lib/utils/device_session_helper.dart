import 'dart:async' show Timer;
import 'dart:io' show Platform, File;
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' as material;
import 'package:path_provider/path_provider.dart';
import '../services/auth_service.dart';
import '../services/turso_database_service.dart';
import 'web_token_helper.dart';

String? _webDeviceToken;

String generateSessionToken() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(256));
  return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

String getDeviceInfo() {
  if (kIsWeb) return 'Web Browser';
  if (Platform.isAndroid) return 'Android Device';
  if (Platform.isIOS) return 'iOS Device';
  if (Platform.isWindows) return 'Windows PC';
  if (Platform.isMacOS) return 'macOS Device';
  if (Platform.isLinux) return 'Linux Device';
  return 'Unknown Device';
}

Future<String> getOrCreateDeviceToken() async {
  if (kIsWeb) {
    _webDeviceToken ??= getWebLocalStorageToken();
    if (_webDeviceToken == null || _webDeviceToken!.isEmpty) {
      _webDeviceToken = generateSessionToken();
      saveWebLocalStorageToken(_webDeviceToken!);
    }
    return _webDeviceToken!;
  }

  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/device_token.txt');
    if (await file.exists()) {
      return await file.readAsString();
    } else {
      final token = generateSessionToken();
      await file.writeAsString(token);
      return token;
    }
  } catch (e) {
    _webDeviceToken ??= generateSessionToken();
    return _webDeviceToken!;
  }
}

class SessionMonitor {
  Timer? _timer;

  void start(dynamic context) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      final user = AuthService.instance.currentUser;
      if (user == null) return;

      final token = await getOrCreateDeviceToken();
      try {
        final activeSession = await TursoDatabaseService.instance.querySingle(
          '''
          SELECT id FROM user_device_sessions
          WHERE user_id = ? AND device_token = ? AND is_active = 1
          ''',
          [user.uid, token],
        );

        if (activeSession == null) {
          timer.cancel();
          await AuthService.instance.signOut();
          if (context.mounted) {
            material.ScaffoldMessenger.of(context).showSnackBar(
              const material.SnackBar(
                content: material.Text('You have been logged out because another device logged in.'),
                backgroundColor: material.Colors.red,
              ),
            );
            material.Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        }
      } catch (e) {
        // Ignore network errors to avoid false logouts
      }
    });
  }

  void stop() {
    _timer?.cancel();
  }
}
