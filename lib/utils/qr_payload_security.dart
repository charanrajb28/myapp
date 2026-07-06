import 'dart:convert';

import 'package:crypto/crypto.dart';

class QrPayloadSecurity {
  static const String _secret = String.fromEnvironment(
    'QR_SIGNING_SECRET',
    defaultValue: 'internship-app-secret-v1-change-me',
  );

  /// Builds a signed QR payload that includes full internship details.
  /// [date] is the ISO-8601 date string this QR is valid for (e.g. "2026-07-06").
  /// Leave [date] empty to create a long-lived QR (valid for any day).
  static Map<String, dynamic> buildRolePayload({
    required String internshipId,
    required String role,
    required String status,
    String issuerId = '',
    String company = '',
    String startDate = '',
    String endDate = '',
    String date = '',
  }) {
    final trimmedInternshipId = internshipId.trim();
    final trimmedRole = role.trim();
    final trimmedStatus = status.trim();
    final trimmedIssuerId = issuerId.trim();
    final trimmedCompany = company.trim();
    final trimmedStartDate = startDate.trim();
    final trimmedEndDate = endDate.trim();
    final trimmedDate = date.trim();

    final nonce = _hashHex(
      '$trimmedInternshipId|$trimmedRole|$trimmedStatus|$trimmedIssuerId|$trimmedDate',
    ).substring(0, 16);

    final canonical = _canonicalPayload(
      internshipId: trimmedInternshipId,
      role: trimmedRole,
      status: trimmedStatus,
      issuerId: trimmedIssuerId,
      company: trimmedCompany,
      startDate: trimmedStartDate,
      endDate: trimmedEndDate,
      date: trimmedDate,
      nonce: nonce,
    );

    final hash = _hashHex(canonical);
    final signature = _hmacHex(canonical);

    return {
      'v': 2,
      'alg': 'HMAC-SHA256',
      'type': 'internship_role_qr',
      'internshipId': trimmedInternshipId,
      'role': trimmedRole,
      'status': trimmedStatus,
      'issuerId': trimmedIssuerId,
      'company': trimmedCompany,
      'startDate': trimmedStartDate,
      'endDate': trimmedEndDate,
      'date': trimmedDate,
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

    // v2 fields (optional, default to empty for backward compat)
    final company = payload['company']?.toString().trim() ?? '';
    final startDate = payload['startDate']?.toString().trim() ?? '';
    final endDate = payload['endDate']?.toString().trim() ?? '';
    final date = payload['date']?.toString().trim() ?? '';
    final version = payload['v'];

    if (type != 'internship_role_qr') return false;
    if (internshipId.isEmpty || internshipId != expectedInternshipId) {
      return false;
    }
    if (nonce.isEmpty || hash.isEmpty || sig.isEmpty) return false;

    // Try v2 canonical first, then fall back to v1 for backward compatibility
    if (version == 2 || version == '2') {
      final canonical = _canonicalPayload(
        internshipId: internshipId,
        role: role,
        status: status,
        issuerId: issuerId,
        company: company,
        startDate: startDate,
        endDate: endDate,
        date: date,
        nonce: nonce,
      );
      final expectedHash = _hashHex(canonical);
      final expectedSig = _hmacHex(canonical);
      if (hash == expectedHash && sig == expectedSig) {
        return true;
      }

      // Try JSON-encoded canonical (backward-compat for older builds)
      final canonicalJson = _canonicalPayloadJsonV2(
        internshipId: internshipId,
        role: role,
        status: status,
        issuerId: issuerId,
        company: company,
        startDate: startDate,
        endDate: endDate,
        date: date,
        nonce: nonce,
      );
      final expectedHashJson = _hashHex(canonicalJson);
      final expectedSigJson = _hmacHex(canonicalJson);
      if (hash == expectedHashJson && sig == expectedSigJson) {
        return true;
      }
      return false;
    }

    // v1 fallback
    final canonical = _canonicalPayloadV1(
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
    required String company,
    required String startDate,
    required String endDate,
    required String date,
    required String nonce,
  }) {
    return '2|internship_role_qr|$internshipId|$role|$status|$issuerId|$company|$startDate|$endDate|$date|$nonce';
  }

  /// JSON-based v2 canonical (for backward compatibility).
  static String _canonicalPayloadJsonV2({
    required String internshipId,
    required String role,
    required String status,
    required String issuerId,
    required String company,
    required String startDate,
    required String endDate,
    required String date,
    required String nonce,
  }) {
    return jsonEncode({
      'v': 2,
      'type': 'internship_role_qr',
      'internshipId': internshipId,
      'role': role,
      'status': status,
      'issuerId': issuerId,
      'company': company,
      'startDate': startDate,
      'endDate': endDate,
      'date': date,
      'nonce': nonce,
    });
  }

  /// Legacy v1 canonical (for verifying old QR codes).
  static String _canonicalPayloadV1({
    required String internshipId,
    required String role,
    required String status,
    required String issuerId,
    required String nonce,
  }) {
    return '1|internship_role_qr|$internshipId|$role|$status|$issuerId|$nonce';
  }

  static String _hashHex(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }

  static String _hmacHex(String value) {
    final mac = Hmac(sha256, utf8.encode(_secret));
    return mac.convert(utf8.encode(value)).toString();
  }
}
