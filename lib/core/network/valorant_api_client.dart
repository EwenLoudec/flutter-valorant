import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin wrapper around the public, keyless valorant-api.com REST API.
class ValorantApiClient {
  ValorantApiClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  static const _baseUrl = 'https://valorant-api.com/v1';

  final http.Client _httpClient;

  Future<List<dynamic>> getList(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$_baseUrl$path').replace(
      queryParameters: {'language': 'fr-FR', ...?query},
    );

    final response = await _httpClient.get(uri);
    if (response.statusCode != 200) {
      throw Exception('valorant-api.com a répondu ${response.statusCode} pour $path');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['data'] as List<dynamic>;
  }
}
