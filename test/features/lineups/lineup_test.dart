import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:mybmw/features/encyclopedia/domain/game_map.dart';
import 'package:mybmw/features/lineups/data/lineup_sources.dart';
import 'package:mybmw/features/lineups/domain/lineup.dart';
import 'package:mybmw/features/lineups/domain/lineup_media.dart';
import 'package:mybmw/features/lineups/domain/resolved_lineup.dart';

/// A map whose transform is the identity, so a callout at (x, y) lands at
/// (y, x) on the minimap — the swap valorant-api documents.
GameMap _map() {
  return const GameMap(
    uuid: 'map-1',
    displayName: 'Ascent',
    tacticalDescription: 'Sites A/B',
    splash: null,
    displayIcon: 'https://example.test/minimap.png',
    xMultiplier: 1,
    yMultiplier: 1,
    xScalarToAdd: 0,
    yScalarToAdd: 0,
    callouts: [
      MapCallout(regionName: 'Main', superRegionName: 'A', gameX: 0.2, gameY: 0.3),
      MapCallout(regionName: 'Site', superRegionName: 'A', gameX: 0.6, gameY: 0.7),
      MapCallout(regionName: 'Main', superRegionName: 'B', gameX: 0.8, gameY: 0.9),
    ],
  );
}

Lineup _lineup({
  Map<String, dynamic>? from,
  Map<String, dynamic>? to,
  bool isBundled = true,
}) {
  return Lineup.fromJson({
    'id': 'test-1',
    'map': 'Ascent',
    'agent': 'Sova',
    'ability': 'Ability2',
    'abilityName': 'Flèche de reconnaissance',
    'side': 'attack',
    'from': from ?? {'callout': 'Main', 'region': 'A'},
    'to': ?to,
    'title': 'Recon A',
    'description': 'Révèle le site',
    'difficulty': 'hard',
  }, isBundled: isBundled);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Lineup', () {
    test('reads a throw, with its in-game key', () {
      final lineup = _lineup(to: {'callout': 'Site', 'region': 'A'});

      expect(lineup.isThrow, isTrue);
      expect(lineup.abilityKey, 'E');
      expect(lineup.side, LineupSide.attack);
      expect(lineup.difficulty, LineupDifficulty.hard);
      expect(lineup.from.label, 'A Main');
      expect(lineup.to?.label, 'A Site');
      expect(lineup.isVerified, isFalse);
    });

    test('a spot without a target is a placement', () {
      expect(_lineup().isThrow, isFalse);
    });

    test('survives a round trip through storage', () {
      final lineup = _lineup(
        from: {'x': 0.25, 'y': 0.75, 'callout': 'Main', 'region': 'A'},
        to: {'callout': 'Site', 'region': 'A'},
        isBundled: false,
      ).copyWith(
        isVerified: true,
        position: 'Dos au mur du fond',
        aim: 'Coin du toit',
        throwStyle: LineupThrow.jumpThrow,
        demoUrl: 'https://youtu.be/demo',
        media: const [
          LineupMedia(
            role: LineupMediaRole.aim,
            kind: LineupMediaKind.photo,
            path: '/data/lineups/test-1-aim.png',
          ),
        ],
      );

      final restored = Lineup.fromJson(
        jsonDecode(jsonEncode(lineup.toJson())) as Map<String, dynamic>,
        isBundled: false,
      );

      expect(restored.id, lineup.id);
      expect(restored.from.x, 0.25);
      expect(restored.from.y, 0.75);
      expect(restored.to?.calloutName, 'Site');
      expect(restored.isVerified, isTrue);
      expect(restored.position, 'Dos au mur du fond');
      expect(restored.aim, 'Coin du toit');
      expect(restored.throwStyle, LineupThrow.jumpThrow);
      expect(restored.demoUrl, 'https://youtu.be/demo');
      expect(restored.mediaFor(LineupMediaRole.aim)?.path, '/data/lineups/test-1-aim.png');
      expect(restored.difficulty, LineupDifficulty.hard);
      expect(restored.completedSteps, Lineup.totalSteps);
    });

    test('reads a spot saved before the guide fields existed', () {
      final restored = Lineup.fromJson({
        'id': 'legacy-1',
        'map': 'Ascent',
        'agent': 'Sova',
        'ability': 'Ability2',
        'abilityName': 'Flèche de reconnaissance',
        'side': 'attack',
        'from': {'callout': 'Main', 'region': 'A'},
        'title': 'Ancien spot',
        'image': '/data/lineups/legacy-1.png',
      }, isBundled: false);

      expect(restored.mediaFor(LineupMediaRole.aim)?.path, '/data/lineups/legacy-1.png');
      expect(restored.throwStyle, LineupThrow.unspecified);
      // Placement (pas de cible) + une photo : seules la position et le type
      // de lancer manquent encore.
      expect(restored.completedSteps, 2);
    });

    test('builds a demo search for the exact trajectory', () {
      final uri = _lineup(to: {'callout': 'Site', 'region': 'A'}).demoSearchUri;

      expect(uri.host, 'www.youtube.com');
      expect(uri.queryParameters['search_query'], 'Sova Ascent lineup A Main A Site');
    });

    test('links to the community lineups of its own map', () {
      final uri = _lineup().mapLineupsUri;

      expect(uri.toString(), 'https://op.gg/valorant/lineups?map=ascent');
    });
  });

  group('ResolvedLineup', () {
    test('places a callout anchor where the map says', () {
      final resolved = ResolvedLineup.resolve(_lineup(to: {'callout': 'Site', 'region': 'A'}), _map());

      expect(resolved, isNotNull);
      expect(resolved!.from, const Offset(0.3, 0.2));
      expect(resolved.to, const Offset(0.7, 0.6));
    });

    test('tells apart two callouts sharing a name', () {
      final resolved = ResolvedLineup.resolve(
        _lineup(from: {'callout': 'Main', 'region': 'B'}),
        _map(),
      );

      expect(resolved!.from, const Offset(0.9, 0.8));
    });

    test('prefers hand-placed coordinates over the callout', () {
      final resolved = ResolvedLineup.resolve(
        _lineup(from: {'x': 0.1, 'y': 0.9, 'callout': 'Main', 'region': 'A'}),
        _map(),
      );

      expect(resolved!.from, const Offset(0.1, 0.9));
    });

    test('drops a spot pointing at a callout the map does not have', () {
      final resolved = ResolvedLineup.resolve(
        _lineup(to: {'callout': 'Heaven', 'region': 'A'}),
        _map(),
      );

      expect(resolved, isNull);
    });
  });

  group('bundled spots', () {
    test('parse, and every id is unique', () async {
      final lineups = await BundledLineupsSource().load();

      expect(lineups.length, greaterThanOrEqualTo(50));
      expect({for (final lineup in lineups) lineup.id}.length, lineups.length);

      for (final lineup in lineups) {
        expect(lineup.mapName, isNotEmpty, reason: '${lineup.id} sans carte');
        expect(lineup.agentName, isNotEmpty, reason: '${lineup.id} sans agent');
        expect(lineup.title, isNotEmpty, reason: '${lineup.id} sans titre');
        expect(lineup.abilityKey, isNotEmpty, reason: '${lineup.id} a un slot inconnu');
        expect(lineup.from.calloutName, isNotNull, reason: '${lineup.id} sans point de départ');
        expect(lineup.isBundled, isTrue);
      }
    });

    test('all ship a playable demo video', () async {
      final lineups = await BundledLineupsSource().load();
      final videoId = RegExp(r'^https://www\.youtube\.com/watch\?v=[\w-]{11}$');

      for (final lineup in lineups) {
        expect(lineup.demoUrl, isNotNull, reason: '${lineup.id} sans vidéo');
        expect(videoId.hasMatch(lineup.demoUrl!), isTrue, reason: '${lineup.id} : ${lineup.demoUrl}');
        expect(lineup.demoTitle, isNotEmpty, reason: '${lineup.id} sans titre de vidéo');
        // La vidéo compte comme média, donc la fiche démarre à au moins 1/4.
        expect(lineup.completedSteps, greaterThanOrEqualTo(1));
      }
    });

    test('cover every agent of the catalogue shipped in the asset', () async {
      final lineups = await BundledLineupsSource().load();
      final raw = jsonDecode(await rootBundle.loadString(BundledLineupsSource.assetPath));

      expect((raw as Map<String, dynamic>)['version'], 1);
      expect({for (final lineup in lineups) lineup.agentName}.length, greaterThanOrEqualTo(29));
    });
  });
}
