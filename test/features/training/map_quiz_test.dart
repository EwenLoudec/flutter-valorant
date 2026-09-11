import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybmw/features/encyclopedia/domain/game_map.dart';
import 'package:mybmw/features/training/domain/map_quiz.dart';

/// Identity transform: a callout at (x, y) lands at (y, x) on the minimap.
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
      MapCallout(regionName: 'Catwalk', superRegionName: 'Mid', gameX: 0.5, gameY: 0.5),
      // Doublon exact d'un callout déjà listé : ne doit pas être demandé deux fois.
      MapCallout(regionName: 'Main', superRegionName: 'A', gameX: 0.21, gameY: 0.31),
      // Les spawns sont hors jeu.
      MapCallout(regionName: 'Spawn', superRegionName: 'AttackerSide', gameX: 0.1, gameY: 0.1),
      MapCallout(regionName: 'Spawn', superRegionName: 'DefenderSide', gameX: 0.9, gameY: 0.9),
    ],
  );
}

void main() {
  group('MapQuizRound.create', () {
    test('ne retient que les callouts jouables, sans doublon', () {
      final round = MapQuizRound.create(
        map: _map(),
        otherMapNames: const ['Bind', 'Haven', 'Split', 'Lotus'],
        random: Random(1),
      );

      final labels = [for (final question in round.questions) question.label];

      expect(labels.toSet().length, labels.length, reason: 'un callout ne doit pas tomber deux fois');
      expect(labels, hasLength(4));
      expect(labels, containsAll(['A Main', 'A Site', 'B Main', 'Mid Catwalk']));
      expect(labels.where((label) => label.contains('Spawn')), isEmpty);
    });

    test('propose quatre cartes dont la bonne', () {
      final round = MapQuizRound.create(
        map: _map(),
        otherMapNames: const ['Bind', 'Haven', 'Split', 'Lotus'],
        random: Random(2),
      );

      expect(round.mapChoices, hasLength(4));
      expect(round.mapChoices, contains('Ascent'));
      expect(round.mapChoices.toSet().length, 4);
    });

    test('place les questions là où la carte dit qu\'elles sont', () {
      final round = MapQuizRound.create(
        map: _map(),
        otherMapNames: const ['Bind'],
        random: Random(3),
      );
      final site = round.questions.firstWhere((question) => question.label == 'A Site');

      expect(site.target, const Offset(0.7, 0.6));
    });

    test('tire des questions différentes d\'une partie à l\'autre', () {
      final draws = <String>{};

      for (var seed = 0; seed < 12; seed++) {
        final round = MapQuizRound.create(
          map: _bigMap(),
          otherMapNames: const ['Bind'],
          random: Random(seed),
        );
        draws.add([for (final question in round.questions) question.label].join('/'));
      }

      expect(draws.length, greaterThan(6), reason: 'les tirages doivent varier');
    });

    test('répartit les questions entre les sites', () {
      final round = MapQuizRound.create(
        map: _bigMap(),
        otherMapNames: const ['Bind'],
        random: Random(7),
      );
      final sites = {for (final question in round.questions) question.superRegion};

      expect(round.questions, hasLength(MapQuizRound.defaultQuestionCount));
      expect(sites.length, greaterThanOrEqualTo(3), reason: 'pas six callouts du même site');
    });

    test('sans la manche « devine la carte », le total tombe à 600', () {
      final round = MapQuizRound.create(
        map: _bigMap(),
        otherMapNames: const ['Bind'],
        asksMapName: false,
        random: Random(8),
      );

      expect(round.asksMapName, isFalse);
      expect(round.maxScore, MapQuizRound.defaultQuestionCount * MapQuizRound.pointsPerCallout);
    });

    test('limite le nombre de questions demandé', () {
      final round = MapQuizRound.create(
        map: _map(),
        otherMapNames: const ['Bind'],
        questionCount: 2,
        random: Random(4),
      );

      expect(round.questions, hasLength(2));
      expect(round.maxScore, MapQuizRound.pointsPerMap + 2 * MapQuizRound.pointsPerCallout);
    });
  });

  group('MapQuizRound.judge', () {
    const question = CalloutQuestion(label: 'A Site', superRegion: 'A', target: Offset(0.5, 0.5));

    test('le sans-faute vaut le maximum', () {
      final answer = MapQuizRound.judge(question, const Offset(0.5, 0.5));

      expect(answer.points, MapQuizRound.pointsPerCallout);
      expect(answer.isPerfect, isTrue);
      expect(answer.verdict, 'Parfait');
    });

    test('une petite erreur reste parfaite, une moyenne vaut moins', () {
      final close = MapQuizRound.judge(question, const Offset(0.53, 0.5));
      final medium = MapQuizRound.judge(question, const Offset(0.62, 0.5));

      expect(close.points, MapQuizRound.pointsPerCallout);
      expect(medium.points, lessThan(MapQuizRound.pointsPerCallout));
      expect(medium.points, greaterThan(0));
    });

    test('à l\'autre bout de la carte, rien', () {
      final answer = MapQuizRound.judge(question, const Offset(0.95, 0.95));

      expect(answer.points, 0);
      expect(answer.verdict, 'Raté');
    });

    test('le score décroît avec la distance', () {
      final near = MapQuizRound.judge(question, const Offset(0.57, 0.5));
      final far = MapQuizRound.judge(question, const Offset(0.65, 0.5));

      expect(near.points, greaterThan(far.points));
      expect(near.distance, lessThan(far.distance));
    });
  });
}

/// A map with enough callouts on every site to exercise the draw.
GameMap _bigMap() {
  return GameMap(
    uuid: 'map-2',
    displayName: 'Lotus',
    tacticalDescription: 'Sites A/B/C',
    splash: null,
    displayIcon: 'https://example.test/minimap.png',
    xMultiplier: 1,
    yMultiplier: 1,
    xScalarToAdd: 0,
    yScalarToAdd: 0,
    callouts: [
      for (final site in ['A', 'B', 'C', 'Mid'])
        for (var index = 0; index < 5; index++)
          MapCallout(
            regionName: 'Zone$index',
            superRegionName: site,
            gameX: index / 10,
            gameY: site.hashCode % 10 / 10,
          ),
    ],
  );
}
