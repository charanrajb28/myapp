import 'dart:convert';

import 'package:crypto/crypto.dart';

class QrPayloadSecurity {
  static const String _secret = String.fromEnvironment(
    'QR_SIGNING_SECRET',
    defaultValue: 'internship-app-secret-v1-change-me',
  );

  static Map<String, dynamic> buildRolePayload({
    required String internshipId,
    required String role,
    required String status,
    String issuerId = '',
  }) {
    final trimmedInternshipId = internshipId.trim();
    final trimmedRole = role.trim();
    final trimmedStatus = status.trim();
    final trimmedIssuerId = issuerId.trim();
    final nonce = _hashHex(
      '$trimmedInternshipId|$trimmedRole|$trimmedStatus|$trimmedIssuerId',
    ).substring(0, 16);

    final canonical = _canonicalPayload(
      internshipId: trimmedInternshipId,
      role: trimmedRole,
      status: trimmedStatus,
      issuerId: trimmedIssuerId,
      nonce: nonce,
    );

    final hash = _hashHex(canonical);
    final signature = _hmacHex(canonical);

    return {
      'v': 1,
      'alg': 'HMAC-SHA256',
      'type': 'internship_role_qr',
      'internshipId': trimmedInternshipId,
      'role': trimmedRole,
      'status': trimmedStatus,
      'issuerId': trimmedIssuerId,
      'nonce': nonce,
      'hash': hash,
      'sig': signature,
    };
  }

  static bool verifyRolePayload(
    Map<String, dynamic> payload, {
    required String expectedInternshipId,
  }) {
    final internshipId = payload['internshipId']?.toString().trim() ?? '';
    final role = payload['role']?.toString().trim() ?? '';
    final status = payload['status']?.toString().trim() ?? '';
    final issuerId = payload['issuerId']?.toString().trim() ?? '';
    final nonce = payload['nonce']?.toString().trim() ?? '';
    final type = payload['type']?.toString().trim() ?? '';
    final hash = payload['hash']?.toString().trim() ?? '';
    final sig = payload['sig']?.toString().trim() ?? '';

    if (type != 'internship_role_qr') return false;
    if (internshipId.isEmpty || internshipId != expectedInternshipId) {
      return false;
    }
    if (nonce.isEmpty || hash.isEmpty || sig.isEmpty) return false;

    final canonical = _canonicalPayload(
      internshipId: internshipId,
      role: role,
      status: status,
      issuerId: issuerId,
      nonce: nonce,
    );

    final expectedHash = _hashHex(canonical);
    final expectedSig = _hmacHex(canonical);

    return hash == expectedHash && sig == expectedSig;
  }

  static String _canonicalPayload({
    required String internshipId,
    required String role,
    required String status,
    required String issuerId,
    required String nonce,
  }) {
    return jsonEncode({
      'v': 1,
      'type': 'internship_role_qr',
      'internshipId': internshipId,
      'role': role,
      'status': status,
      'issuerId': issuerId,
      'nonce': nonce,
    });
  }

  static String _hashHex(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }

  static String _hmacHex(String value) {
    final mac = Hmac(sha256, utf8.encode(_secret));
    return mac.convert(utf8.encode(value)).toString();
  }
}
