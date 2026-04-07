import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionExpiryHandler {
  static GlobalKey<NavigatorState>? _navigatorKey;
  static bool _isShowingDialog = false;

  static void configure(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  static bool isSessionExpiredError(Object error) {
    if (error is PostgrestException) {
      return error.code == 'PGRST303' ||
          error.message.toLowerCase().contains('jwt expired');
    }
    if (error is AuthException) {
      return error.message.toLowerCase().contains('jwt') &&
          error.message.toLowerCase().contains('expired');
    }

    final text = error.toString().toLowerCase();
    return text.contains('jwt expired') || text.contains('pgrst303');
  }

  static Future<void> showAndRedirect() async {
    final navigator = _navigatorKey?.currentState;
    final context = _navigatorKey?.currentContext;
    if (navigator == null || context == null || _isShowingDialog) {
      return;
    }

    _isShowingDialog = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Session Expired',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Session expired. Please log in again.',
            style: TextStyle(
              color: Color(0xFF475569),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    } finally {
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
      _isShowingDialog = false;
    }
  }
}
