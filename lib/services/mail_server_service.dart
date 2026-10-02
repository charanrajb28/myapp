import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/mail_server_config.dart';

class MailServerService {
  static Future<void> sendPasswordResetEmail(String email) async {
    final response = await http.post(
      Uri.parse('${MailServerConfig.baseUrl}/api/send-password-reset'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': MailServerConfig.apiKey,
      },
      body: jsonEncode({'email': email.trim()}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(_errorMessage(response));
    }
  }

  static Future<void> sendWelcomeEmail({
    required String email,
    required String name,
    required String tempPassword,
    required String accountType,
    String enrollmentId = '',
    String college = '',
    String department = '',
    String semester = '',
    String phone = '',
    String parentName = '',
    String parentContact = '',
    String parentEmail = '',
  }) async {
    final response = await http.post(
      Uri.parse('${MailServerConfig.baseUrl}/api/send-welcome'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': MailServerConfig.apiKey,
      },
      body: jsonEncode({
        'email': email.trim(),
        'name': name.trim(),
        'tempPassword': tempPassword,
        'accountType': accountType,
        'enrollmentId': enrollmentId,
        'college': college,
        'department': department,
        'semester': semester,
        'phone': phone,
        'parentName': parentName,
        'parentContact': parentContact,
        'parentEmail': parentEmail,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(_errorMessage(response));
    }
  }

  static String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['error'] != null) {
        return body['error'].toString();
      }
    } catch (_) {}
    return 'Mail server returned HTTP ${response.statusCode}.';
  }
}
