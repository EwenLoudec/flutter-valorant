import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_companion/features/lineups/domain/lineup.dart';
import 'package:valorant_companion/features/lineups/domain/lineup_collections.dart';
import 'package:valorant_companion/features/lineups/domain/lineup_media.dart';
import 'package:valorant_companion/features/lineups/domain/lineup_transfer.dart';

Lineup _lineup(String id, {bool isBundled = false}) => Lineup(
  id: id,
  mapName: 'Ascent',
  agentName: 'Viper',
  abilitySlot: 'Grenade',
  abilityName: 'Nuage toxique',
  side: LineupSide.defense,
  from: const LineupAnchor(calloutName: 'Main', calloutRegion: 'B'),
  to: const LineupAnchor(x: 0.4, y: 0.6),
  title: 'One-way B Main',
  description: 'Se poser contre la caisse.',
  difficulty: LineupDifficulty.easy,
  isVerified: true,
  isBundled: isBundled,
  position: 'Coin de la caisse',
  aim: 'Haut du lampadaire',
  throwStyle: LineupThrow.values.last,
  media: const [LineupMedia(role: LineupMediaRole.aim, kind: LineupMediaKind.photo, path: '/data/x.jpg')],
  demoUrl: 'https://www.youtube.com/watch?v=abc',
);

void main() {
  group('LineupTransfer', () {
    test('round-trips a spot, without its device files', () {
      final text = LineupTransfer.export([_lineup('user-1')]);
      final decoded = jsonDecode(text) as Map<String, dynamic>;
      expect(decoded['format'], LineupTransfer.format);
      expect((decoded['lineups'] as List<dynamic>).single, isNot(contains('media')));

      final result = LineupTransfer.import(text, existingIds: const {});
      final imported = result.lineups.single;
      expect(imported.id, 'user-1');
      expect(imported.title, 'One-way B Main');
      expect(imported.position, 'Coin de la caisse');
      expect(imported.to?.x, 0.4);
      expect(imported.demoUrl, 'https://www.youtube.com/watch?v=abc');
      expect(imported.media, isEmpty);
      expect(imported.isBundled, isFalse);
      expect(result.skipped, 0);
    });

    test('gives a fresh id when the spot already exists', () {
      final text = LineupTransfer.export([_lineup('user-1'), _lineup('user-1')]);
      final result = LineupTransfer.import(text, existingIds: {'user-1'}, now: DateTime(2026));
      final ids = result.lineups.map((lineup) => lineup.id).toList();

      expect(ids, hasLength(2));
      expect(ids.toSet(), hasLength(2));
      expect(ids, isNot(contains('user-1')));
    });

    test('turns a bundled spot into the player\'s own', () {
      final result = LineupTransfer.import(LineupTransfer.export([_lineup('ascent-01', isBundled: true)]), existingIds: const {});
      expect(result.lineups.single.isBundled, isFalse);
    });

    test('skips unreadable entries and accepts a bare list', () {
      final raw = jsonEncode([
        _lineup('a').toJson(),
        {'map': 'Bind'},
        'nope',
        {'map': 'Bind', 'agent': 'Sova', 'id': 42},
      ]);
      final result = LineupTransfer.import(raw, existingIds: const {});
      expect(result.lineups.map((lineup) => lineup.id), ['a']);
      expect(result.skipped, 3);
    });

    test('explains what is wrong with the text', () {
      expect(
        () => LineupTransfer.import('pas du json', existingIds: const {}),
        throwsA(isA<LineupImportException>().having((error) => error.message, 'message', contains('illisible'))),
      );
      expect(
        () => LineupTransfer.import('{"format": "autre", "lineups": []}', existingIds: const {}),
        throwsA(isA<LineupImportException>()),
      );
      expect(() => LineupTransfer.import('{"lineups": []}', existingIds: const {}), throwsA(isA<LineupImportException>()));
      expect(() => LineupTransfer.import('42', existingIds: const {}), throwsA(isA<LineupImportException>()));
    });
  });

  group('LineupSearch', () {
    final lineup = _lineup('a');

    test('matches every word against the spot', () {
      expect(lineup.matches(''), isTrue);
      expect(lineup.matches('viper'), isTrue);
      expect(lineup.matches('B main'), isTrue);
      expect(lineup.matches('ascent c'), isTrue, reason: '« c » is the key of the Grenade slot');
      expect(lineup.matches('viper bind'), isFalse);
      expect(lineup.matches('défense'), isTrue);
    });
  });

  group('LineupCollections', () {
    test('stars and unstars a spot', () {
      final starred = const LineupCollections().toggleFavorite('a');
      expect(starred.isFavorite('a'), isTrue);
      expect(starred.toggleFavorite('a').isFavorite('a'), isFalse);
    });

    test('creates, fills and deletes collections', () {
      var collections = const LineupCollections().create('  Viper Ascent  ').create('');
      expect(collections.collections.keys, ['Viper Ascent']);

      collections = collections.toggleIn('Viper Ascent', 'a').toggleIn('Retakes', 'a').toggleIn('Retakes', 'b');
      expect(collections.collectionsOf('a'), ['Viper Ascent', 'Retakes']);
      expect(collections.collections['Retakes'], ['a', 'b']);

      collections = collections.toggleIn('Retakes', 'a');
      expect(collections.collections['Retakes'], ['b']);

      collections = collections.delete('Retakes');
      expect(collections.collections.keys, ['Viper Ascent']);
    });

    test('reads back what it stored, ignoring garbage', () {
      final stored = const LineupCollections().toggleFavorite('a').toggleIn('Mes spots', 'b');
      final restored = LineupCollections.fromJson(
        stored.favorites.toList(),
        jsonDecode(jsonEncode(stored.collectionsToJson())),
      );
      expect(restored.isFavorite('a'), isTrue);
      expect(restored.collections['Mes spots'], ['b']);

      final broken = LineupCollections.fromJson('x', {'ok': ['a', 3], 'ko': 'b'});
      expect(broken.favorites, isEmpty);
      expect(broken.collections, {'ok': ['a']});
    });
  });
}
