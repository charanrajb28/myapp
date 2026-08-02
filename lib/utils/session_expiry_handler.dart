import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SessionExpiryHandler {
  static bool isSessionExpiredError(Object error) {
    if (error is FirebaseAuthException) {
      return error.code == 'id-token-expired' ||
          error.code == 'user-token-expired';
    }

    final text = error.toString().toLowerCase();
    return text.contains('token-expired') || text.contains('jwt expired');
  }

  static Future<bool> tryRefreshSession() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.getIdToken(true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[SessionExpiryHandler] Silent refresh failed: $e');
      return false;
    }
  }
}
