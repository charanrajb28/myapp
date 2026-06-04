import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles JWT token expiry transparently by refreshing the session silently.
/// The user is never logged out due to token expiry — only an explicit
/// [signOut] call (triggered by the user) causes a redirect to login.
class SessionExpiryHandler {
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

  /// Silently refreshes the Supabase session when a JWT-expired error is
  /// detected. Returns `true` if the refresh succeeded (caller can retry
  /// their request), or `false` if the session cannot be renewed (e.g. the
  /// refresh token itself is invalid / user has been deleted).
  static Future<bool> tryRefreshSession() async {
    try {
      final response =
          await Supabase.instance.client.auth.refreshSession();
      return response.session != null;
    } catch (e) {
      debugPrint('[SessionExpiryHandler] Silent refresh failed: $e');
      return false;
    }
  }
}
