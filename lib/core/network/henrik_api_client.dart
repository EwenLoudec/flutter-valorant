import 'dart:convert';

import 'package:http/http.dart' as http;

enum HenrikApiErrorKind { missingKey, invalidKey, playerNotFound, rateLimited, unavailable }

/// Failure returned by [HenrikApiClient], already carrying a message meant to
/// be shown as-is in the UI.
class HenrikApiException implements Exception {
  const HenrikApiException(this.kind, this.message);

  final HenrikApiErrorKind kind;
  final String message;

  /// Whether trying the very same request again could succeed.
  bool get isTransient =>
      kind == HenrikApiErrorKind.rateLimited || kind == HenrikApiErrorKind.unavailable;

  @override
  String toString() => message;
}

/// Thin wrapper around api.henrikdev.xyz, the community REST API exposing
/// live player data (account, MMR, match history). It needs a free API key,
/// requested on the HenrikDev Discord, sent in the Authorization header.
class HenrikApiClient {
  HenrikApiClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  static const _baseUrl = 'https://api.henrikdev.xyz/valorant';

  final http.Client _httpClient;

  Future<Map<String, dynamic>> getObject(
    String path, {
    required String apiKey,
    Map<String, String>? query,
  }) async {
    final data = await _get(path, apiKey: apiKey, query: query);
    return data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getList(
    String path, {
    required String apiKey,
    Map<String, String>? query,
  }) async {
    final data = await _get(path, apiKey: apiKey, query: query);
    return data as List<dynamic>;
  }

  Future<dynamic> _get(String path, {required String apiKey, Map<String, String>? query}) async {
    if (apiKey.isEmpty) {
      throw const HenrikApiException(
        HenrikApiErrorKind.missingKey,
        'Aucune clé API HenrikDev enregistrée.',
      );
    }

    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);

    late final http.Response response;
    try {
      response = await _httpClient.get(uri, headers: {'Authorization': apiKey});
    } on Object catch (error) {
      throw HenrikApiException(HenrikApiErrorKind.unavailable, 'Connexion impossible : $error');
    }

    if (response.statusCode != 200) throw _errorFor(response);

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['data'];
  }

  HenrikApiException _errorFor(http.Response response) {
    return switch (response.statusCode) {
      401 || 403 => const HenrikApiException(
        HenrikApiErrorKind.invalidKey,
        'Clé API refusée. Vérifiez la clé HenrikDev enregistrée.',
      ),
      404 => const HenrikApiException(
        HenrikApiErrorKind.playerNotFound,
        'Joueur introuvable. Vérifiez le Riot ID et la région.',
      ),
      429 => const HenrikApiException(
        HenrikApiErrorKind.rateLimited,
        'Trop de requêtes envoyées. Réessayez dans quelques secondes.',
      ),
      _ => HenrikApiException(
        HenrikApiErrorKind.unavailable,
        'L\'API HenrikDev a répondu ${response.statusCode}.',
      ),
    };
  }
}
