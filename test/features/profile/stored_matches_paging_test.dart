import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:valorant_companion/core/network/henrik_api_client.dart';
import 'package:valorant_companion/features/profile/data/henrik_player_repository.dart';
import 'package:valorant_companion/features/profile/domain/player_query.dart';

Map<String, dynamic> _game(String id, String season) => {
  'meta': {
    'id': id,
    'map': {'name': 'Ascent'},
    'season': {'id': season, 'short': 'e11a5'},
  },
  'stats': {'team': 'Red', 'kills': 10, 'deaths': 10},
  'teams': {'red': 13, 'blue': 5},
};

void main() {
  const query = PlayerQuery(riotId: RiotId(name: 'Moi', tag: 'EUW'), region: ValorantRegion.eu);

  HenrikPlayerRepository repositoryServing(List<List<Map<String, dynamic>>> pages, List<int> asked) {
    final client = MockClient((request) async {
      final page = int.parse(request.url.queryParameters['page']!);
      asked.add(page);
      expect(request.url.path, '/valorant/v1/stored-matches/eu/Moi/EUW');
      expect(request.url.queryParameters['mode'], 'competitive');
      final data = page <= pages.length ? pages[page - 1] : const <Map<String, dynamic>>[];
      return http.Response(jsonEncode({'status': 200, 'data': data}), 200);
    });
    return HenrikPlayerRepository(apiKey: 'HDEV-test', client: HenrikApiClient(httpClient: client));
  }

  test('keeps reading while the act goes on, then stops', () async {
    final asked = <int>[];
    final repository = repositoryServing([
      [for (var index = 0; index < 3; index++) _game('a$index', 'now')],
      [_game('a2', 'now'), _game('a3', 'now'), _game('b0', 'before')],
      [_game('never', 'before')],
    ], asked);

    final matches = await repository.getStoredMatches(query, size: 3);

    expect(asked, [1, 2], reason: 'la page 2 sort de l\'acte : inutile de lire la 3');
    expect(matches.map((match) => match.id), ['a0', 'a1', 'a2', 'a3', 'b0'], reason: 'a2 n\'est compté qu\'une fois');
  });

  test('a short first page is the whole history', () async {
    final asked = <int>[];
    final repository = repositoryServing([
      [_game('a0', 'now')],
    ], asked);

    expect(await repository.getStoredMatches(query, size: 3), hasLength(1));
    expect(asked, [1]);
  });

  test('never reads more than the page limit', () async {
    final asked = <int>[];
    final repository = repositoryServing([
      for (var page = 0; page < 10; page++)
        [for (var index = 0; index < 2; index++) _game('p$page-$index', 'now')],
    ], asked);

    final matches = await repository.getStoredMatches(query, size: 2);

    expect(asked, hasLength(HenrikPlayerRepository.storedMatchesPages));
    expect(matches, hasLength(2 * HenrikPlayerRepository.storedMatchesPages));
  });
}
