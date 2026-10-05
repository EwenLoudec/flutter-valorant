import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:valorant_companion/core/network/response_cache.dart';
import 'package:valorant_companion/core/network/valorant_api_client.dart';

String _body(List<Object> data) => jsonEncode({'status': 200, 'data': data});

void main() {
  group('ValorantApiClient cache', () {
    test('serves a fresh cached copy without calling the network', () async {
      final cache = MemoryResponseCache();
      var calls = 0;
      final client = ValorantApiClient(
        cache: cache,
        httpClient: MockClient((request) async {
          calls++;
          return http.Response(_body(['réseau']), 200);
        }),
      );

      expect(await client.getList('/agents'), ['réseau']);
      expect(await client.getList('/agents'), ['réseau']);
      expect(calls, 1);
      expect(cache.entries.keys.single, contains('language=fr-FR'));
    });

    test('decodes accents from the raw bytes', () async {
      final client = ValorantApiClient(
        useDefaultCache: false,
        httpClient: MockClient((request) async => http.Response.bytes(utf8.encode(_body(['Contrôleur'])), 200)),
      );

      expect(await client.getList('/agents'), ['Contrôleur']);
    });

    test('falls back on a stale copy when the network is down', () async {
      final cache = MemoryResponseCache()
        ..entries['https://valorant-api.com/v1/maps?language=fr-FR'] = CachedResponse(
          body: _body(['ancienne']),
          savedAt: DateTime.now().subtract(const Duration(days: 3)),
        );
      final client = ValorantApiClient(
        cache: cache,
        httpClient: MockClient((request) async => throw http.ClientException('hors ligne')),
      );

      expect(await client.getList('/maps'), ['ancienne']);
    });

    test('refreshes a stale copy when the network answers', () async {
      final cache = MemoryResponseCache()
        ..entries['https://valorant-api.com/v1/maps?language=fr-FR'] = CachedResponse(
          body: _body(['ancienne']),
          savedAt: DateTime.now().subtract(const Duration(days: 3)),
        );
      final client = ValorantApiClient(
        cache: cache,
        httpClient: MockClient((request) async => http.Response(_body(['nouvelle']), 200)),
      );

      expect(await client.getList('/maps'), ['nouvelle']);
      expect(jsonDecode(cache.entries.values.single.body)['data'], ['nouvelle']);
    });

    test('fails without cache when the API refuses', () async {
      final client = ValorantApiClient(
        useDefaultCache: false,
        httpClient: MockClient((request) async => http.Response('oops', 500)),
      );

      expect(client.getList('/maps'), throwsException);
    });

    test('ignores a corrupted cache entry', () async {
      final cache = MemoryResponseCache()
        ..entries['https://valorant-api.com/v1/maps?language=fr-FR'] = CachedResponse(
          body: '{pas du json',
          savedAt: DateTime.now(),
        );
      final client = ValorantApiClient(
        cache: cache,
        httpClient: MockClient((request) async => http.Response(_body(['propre']), 200)),
      );

      expect(await client.getList('/maps'), ['propre']);
    });
  });
}
