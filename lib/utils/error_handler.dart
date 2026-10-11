import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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
        text.contains('invalid_credential') ||
        text.contains('invalid_login_credentials') ||
        text.contains('invalid login credentials') ||
        text.contains('user-not-found') ||
        text.contains('user_not_found') ||
        text.contains('wrong-password') ||
        text.contains('wrong_password') ||
        text.contains('invalid-email') ||
        text.contains('invalid_email') ||
        text.contains('user-disabled') ||
        text.contains('user_disabled') ||
        text.contains('too-many-requests') ||
        text.contains('too_many_attempts') ||
        text.contains('channel-error') ||
        text.contains('network-request-failed') ||
        text.contains('operation-not-allowed');
  }

  /// Returns clear, user-friendly error messages for all auth and network errors.
  static String getErrorMessage(
    Object error, {
    String fallbackMessage = 'An unexpected error occurred. Please try again.',
  }) {
    debugPrint('ErrorHandler inspecting error: $error (${error.runtimeType})');

    if (error is FirebaseAuthException) {
      final code = error.code.toLowerCase().replaceAll('_', '-');
      switch (code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-login-credentials':
          return 'Invalid email or password. Please verify your credentials.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact your administrator.';
        case 'too-many-requests':
          return 'Too many login attempts. Access is temporarily paused. Please try again in a few moments.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection and try again.';
        case 'operation-not-allowed':
          return 'Email and password sign-in is not enabled for this project.';
        case 'channel-error':
          return 'Please enter both your email address and password.';
        default:
          if (error.message != null && error.message!.trim().isNotEmpty) {
            return error.message!;
          }
          return 'Authentication error (${error.code}). Please try again.';
      }
    }

    final text = error.toString().toLowerCase();

    // Check specific error patterns across Web and Native formats
    if (text.contains('invalid-credential') ||
        text.contains('invalid_credential') ||
        text.contains('invalid_login_credentials') ||
        text.contains('invalid login credentials') ||
        text.contains('wrong-password') ||
        text.contains('wrong_password') ||
        text.contains('user-not-found') ||
        text.contains('user_not_found')) {
      return 'Invalid email or password. Please verify your credentials.';
    }

    if (text.contains('invalid-email') || text.contains('invalid_email')) {
      return 'Please enter a valid email address.';
    }

    if (text.contains('user-disabled') || text.contains('user_disabled')) {
      return 'This account has been disabled. Please contact your administrator.';
    }

    if (text.contains('too-many-requests') || text.contains('too_many_attempts')) {
      return 'Too many login attempts. Please wait a moment and try again.';
    }

    if (text.contains('channel-error') || text.contains('given string is empty or null')) {
      return 'Please enter both your email address and password.';
    }

    if (text.contains('network') ||
        text.contains('socketexception') ||
        text.contains('clientexception') ||
        text.contains('connection')) {
      return 'Network connection issue. Please check your internet connection.';
    }

    if (text.contains('foreign key') || text.contains('users.id')) {
      return 'Account profile not found in institutional database. Please contact the administrator.';
    }

    if (text.contains('tursodb') || text.contains('database')) {
      return 'Database connection error. Please try again in a few seconds.';
    }

    return fallbackMessage;
  }
}
