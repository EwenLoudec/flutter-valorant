/// Forgiving readers for the HenrikDev payloads, whose field names and types
/// moved between API versions. A missing or mistyped field reads as empty,
/// never as a crash.
Map<String, dynamic> asMap(Object? value) => value is Map<String, dynamic> ? value : const <String, dynamic>{};

List<dynamic> asList(Object? value) => value is List<dynamic> ? value : const <dynamic>[];

int asInt(Object? value) => switch (value) {
  final int number => number,
  final num number => number.round(),
  final String text => int.tryParse(text) ?? double.tryParse(text)?.round() ?? 0,
  _ => 0,
};

double? asDoubleOrNull(Object? value) => switch (value) {
  final num number => number.toDouble(),
  final String text => double.tryParse(text),
  _ => null,
};

String? asStringOrNull(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

/// Maps, agents and queues come either as `{"id": .., "name": ..}` (v4) or as
/// a bare string (v2).
String displayNameOf(Object? value) {
  if (value is Map<String, dynamic>) return (value['name'] ?? value['mode_type'] ?? '').toString();
  return value?.toString() ?? '';
}

/// The `id` of an `{"id": .., "name": ..}` object, when there is one.
String? idOf(Object? value) {
  if (value is Map<String, dynamic>) return asStringOrNull(value['id']);
  return null;
}

/// Reads an ISO date, or epoch seconds as a fallback, in local time.
DateTime? dateOf(Object? value) {
  if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.round() * 1000).toLocal();
  final text = asStringOrNull(value);
  if (text == null) return null;
  return DateTime.tryParse(text)?.toLocal();
}
