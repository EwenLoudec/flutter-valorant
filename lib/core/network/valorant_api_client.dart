import 'dart:convert';

import 'package:http/http.dart' as http;

import 'response_cache.dart';

/// Thin wrapper around the public, keyless valorant-api.com REST API.
///
/// Responses are kept in a [ResponseCache]: a fresh copy is served without
/// touching the network, and a stale one still answers when the network is
/// down. The game data only changes with patches, so this is safe.
class ValorantApiClient {
  ValorantApiClient({http.Client? httpClient, ResponseCache? cache, bool useDefaultCache = true})
    : _httpClient = httpClient ?? http.Client(),
      _cache = cache ?? (useDefaultCache ? FileResponseCache.platformDefault() : null);

  static const _baseUrl = 'https://valorant-api.com/v1';

  /// How long a cached response is served before asking the network again.
  static const freshFor = Duration(hours: 12);

  final http.Client _httpClient;
  final ResponseCache? _cache;

  Future<List<dynamic>> getList(String path, {Map<String, String>? query}) async {
    final decoded = await _get(path, query);
    return decoded['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getOne(String path, {Map<String, String>? query}) async {
    final decoded = await _get(path, query);
    return decoded['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _get(String path, Map<String, String>? query) async {
    final uri = Uri.parse('$_baseUrl$path').replace(
      queryParameters: {'language': 'fr-FR', ...?query},
    );
    final key = uri.toString();

    final cached = await _cache?.read(key);
    if (cached != null && cached.age < freshFor) {
      final decoded = _tryDecode(cached.body);
      if (decoded != null) return decoded;
    }

    try {
      final response = await _httpClient.get(uri);
      if (response.statusCode != 200) {
        throw Exception('valorant-api.com a répondu ${response.statusCode} pour $path');
      }

      final body = _decodeBody(response);
      final decoded = _tryDecode(body);
      if (decoded == null) throw Exception('Réponse illisible de valorant-api.com pour $path');

      await _cache?.write(key, body);
      return decoded;
    } on Object {
      final stale = cached == null ? null : _tryDecode(cached.body);
      if (stale != null) return stale;
      rethrow;
    }
  }

  /// The API speaks UTF-8 even when the header forgets to say so; anything
  /// else falls back to the charset the response declares.
  static String _decodeBody(http.Response response) {
    try {
      return utf8.decode(response.bodyBytes);
    } on FormatException {
      return response.body;
    }
  }

  static Map<String, dynamic>? _tryDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}
