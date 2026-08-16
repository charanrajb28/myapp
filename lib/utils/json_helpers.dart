import 'dart:convert';
import 'package:intl/intl.dart';

/// Formats database dates for presentation without exposing their ISO time.
///
/// Turso stores some date-only values as ISO timestamps (for example,
/// `2026-09-12T00:00:00.000`). Keep non-date text intact so legacy values
/// such as `TBD` remain useful to the UI.
String formatDisplayDate(dynamic value, {String fallback = 'TBD'}) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return fallback;

  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;

  return DateFormat('dd MMM yyyy').format(parsed.toLocal());
}

/// Safely converts dynamic input (List, JSON String, null, etc.) into a `List<dynamic>`.
List<dynamic> parseDynamicList(dynamic input) {
  if (input == null) return [];
  if (input is List) return input;
  if (input is String) {
    final str = input.trim();
    if (str.isEmpty) return [];
    if (str.startsWith('[') && str.endsWith(']')) {
      try {
        final decoded = jsonDecode(str);
        if (decoded is List) return decoded;
      } catch (_) {}
    }
  }
  return [];
}

/// Safely converts dynamic input into a `List<String>`.
List<String> parseStringList(dynamic input) {
  return parseDynamicList(input)
      .map((e) => e?.toString() ?? '')
      .where((e) => e.isNotEmpty)
      .toList();
}

/// Safely converts dynamic input into a `Map<String, dynamic>`.
Map<String, dynamic> parseMap(dynamic input) {
  if (input == null) return {};
  if (input is Map<String, dynamic>) return input;
  if (input is Map) {
    return input.map((k, v) => MapEntry(k.toString(), v));
  }
  if (input is String) {
    final str = input.trim();
    if (str.isEmpty) return {};
    if (str.startsWith('{') && str.endsWith('}')) {
      try {
        final decoded = jsonDecode(str);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), v));
        }
      } catch (_) {}
    }
  }
  return {};
}
