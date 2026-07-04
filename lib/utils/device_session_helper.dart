import 'dart:async' show Timer;
import 'dart:io' show Platform, File;
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' as material;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;

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
    return 'fallback_${DateTime.now().millisecondsSinceEpoch}';
  }
}

class SessionMonitor {
  Timer? _timer;

  void start(dynamic context) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      final user = supabase_flutter.Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final token = await getOrCreateDeviceToken();
      try {
        final activeSession = await supabase_flutter.Supabase.instance.client
            .from('user_device_sessions')
            .select()
            .eq('user_id', user.id)
            .eq('device_token', token)
            .eq('is_active', true)
            .maybeSingle();

        if (activeSession == null) {
          timer.cancel();
          await supabase_flutter.Supabase.instance.client.auth.signOut();
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
