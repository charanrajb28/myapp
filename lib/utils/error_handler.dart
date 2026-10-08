import 'package:firebase_auth/firebase_auth.dart';

class ErrorHandler {
  /// Checks if an error is an authentication / credential error.
  static bool isAuthError(Object error) {
    if (error is FirebaseAuthException) {
      return true;
    }
    final text = error.toString().toLowerCase();
    return text.contains('firebase_auth') ||
        text.contains('auth/') ||
        text.contains('invalid-credential') ||
        text.contains('user-not-found') ||
        text.contains('wrong-password') ||
        text.contains('invalid-email') ||
        text.contains('user-disabled') ||
        text.contains('invalid login credentials');
  }

  /// Returns 'Invalid login credentials' for auth errors,
  /// and a friendly generic fallback message for all other errors
  /// to avoid exposing raw internal error details.
  static String getErrorMessage(
    Object error, {
    String fallbackMessage = 'An unexpected error occurred. Please try again.',
  }) {
    if (isAuthError(error)) {
      return 'Invalid login credentials';
    }
    return fallbackMessage;
  }
}
