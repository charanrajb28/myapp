import 'dart:convert';

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
