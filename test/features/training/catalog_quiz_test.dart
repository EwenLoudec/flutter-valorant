import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_companion/features/encyclopedia/domain/agent.dart';
import 'package:valorant_companion/features/encyclopedia/domain/game_map.dart';
import 'package:valorant_companion/features/encyclopedia/domain/rank_tier.dart';
import 'package:valorant_companion/features/encyclopedia/domain/weapon.dart';
import 'package:valorant_companion/features/lineups/domain/lineup.dart';
import 'package:valorant_companion/features/lineups/domain/resolved_lineup.dart';
import 'package:valorant_companion/features/training/domain/agent_quiz.dart';
import 'package:valorant_companion/features/training/domain/catalog_quiz.dart';
import 'package:valorant_companion/features/training/domain/daily_challenge.dart';
import 'package:valorant_companion/features/training/domain/lineup_quiz.dart';
import 'package:valorant_companion/features/training/domain/quiz_run.dart';

Weapon _weapon(String name, {int skins = 2}) => Weapon(
  uuid: name,
  displayName: name,
  category: 'Rifle',
  displayIcon: 'https://img/$name.png',
  cost: 1000,
  fireRate: null,
  magazineSize: null,
  damageRanges: const [],
  skinPreviews: [
    for (var index = 0; index < skins; index++)
      WeaponSkinPreview(displayName: '$name skin $index', displayIcon: 'https://img/$name-$index.png'),
  ],
);

RankTier _tier(int tier, String name) => RankTier(
  tier: tier,
  tierName: name,
  divisionName: name.split(' ').first,
  color: const Color(0xFFFFFFFF),
  backgroundColor: const Color(0xFF000000),
  largeIcon: 'https://img/rank-$tier.png',
);

Agent _agent(String name) => Agent(
  uuid: name,
  displayName: name,
  description: '',
  roleName: 'Duelliste',
  displayIcon: 'https://img/$name.png',
  fullPortrait: 'https://img/$name-full.png',
  backgroundGradientColors: const [],
  abilities: [
    for (final slot in ['Ability1', 'Ability2', 'Grenade', 'Ultimate'])
      AgentAbility(
        slot: slot,
        displayName: '$name $slot',
        description: 'Une description assez longue pour être posée en question, compétence $slot.',
        displayIcon: 'https://img/$name-$slot.png',
      ),
  ],
);

final _weapons = [for (final name in ['Vandal', 'Phantom', 'Sheriff', 'Spectre', 'Operator', 'Judge']) _weapon(name)];
final _tiers = [
  for (final (index, name) in ['Fer 1', 'Fer 2', 'Bronze 1', 'Argent 1', 'Or 1', 'Radiant'].indexed) _tier(index + 3, name),
];
final _agents = [for (final name in ['Jett', 'Sova', 'Omen', 'Sage', 'Raze', 'Viper']) _agent(name)];

void main() {
  group('CatalogQuiz.weapons', () {
    test('mixes silhouettes and skins, each with four distinct choices', () {
      final round = CatalogQuiz.weapons(weapons: _weapons, random: Random(3));

      expect(round.questions, hasLength(CatalogQuiz.questionCount));
      expect(round.questions.map((question) => question.kind).toSet(), {
        AgentQuestionKind.weaponSilhouette,
        AgentQuestionKind.weaponSkin,
      });
      for (final question in round.questions) {
        expect(question.choices.toSet(), hasLength(4));
        expect(question.choices, contains(question.answer));
      }
    });

    test('needs four weapons', () {
      expect(CatalogQuiz.weapons(weapons: _weapons.take(3).toList()).questions, isEmpty);
    });

    test('falls back on silhouettes when no weapon has skins', () {
      final round = CatalogQuiz.weapons(weapons: [for (final weapon in _weapons) _weapon(weapon.displayName, skins: 0)]);
      expect(round.questions.every((question) => question.kind == AgentQuestionKind.weaponSilhouette), isTrue);
      expect(round.questions, isNotEmpty);
    });
  });

  group('CatalogQuiz.ranks', () {
    test('asks each emblem at most once', () {
      final round = CatalogQuiz.ranks(tiers: _tiers, random: Random(1));
      expect(round.questions, hasLength(_tiers.length));
      expect(round.questions.map((question) => question.answer).toSet(), hasLength(_tiers.length));
      expect(round.maxScore, _tiers.length * AgentQuizRound.pointsPerQuestion);
    });
  });

  group('CatalogQuiz.daily', () {
    test('gives everyone the same draw on a given day', () {
      final date = DateTime(2026, 10, 5, 9);
      final first = CatalogQuiz.daily(date: date, agents: _agents, weapons: _weapons, tiers: _tiers);
      final second = CatalogQuiz.daily(
        date: DateTime(2026, 10, 5, 22),
        agents: _agents,
        weapons: _weapons,
        tiers: _tiers,
      );
      final otherDay = CatalogQuiz.daily(date: DateTime(2026, 10, 6), agents: _agents, weapons: _weapons, tiers: _tiers);

      String signature(AgentQuizRound round) =>
          round.questions.map((question) => '${question.kind.name}:${question.answer}:${question.choices}').join('|');

      expect(first.questions, hasLength(DailyChallenge.questionCount));
      expect(signature(first), signature(second));
      expect(signature(first), isNot(signature(otherDay)));
    });
  });

  group('DailyStreak', () {
    final monday = DateTime(2026, 10, 5);
    final tuesday = DateTime(2026, 10, 6);
    final thursday = DateTime(2026, 10, 8);

    test('grows day after day and resets after a skipped day', () {
      final first = const DailyStreak().complete(monday, 700);
      expect(first.length, 1);
      expect(first.isDoneOn(monday), isTrue);

      final second = first.complete(tuesday, 800);
      expect(second.length, 2);
      expect(second.lastScore, 800);

      expect(second.lengthOn(thursday), 0, reason: 'Wednesday was skipped');
      expect(second.complete(thursday, 500).length, 1);
    });

    test('ignores a second run on the same day', () {
      final done = const DailyStreak().complete(monday, 700);
      expect(identical(done.complete(monday, 1000), done), isTrue);
    });

    test('keeps the streak alive until the end of the next day', () {
      final done = const DailyStreak().complete(monday, 700);
      expect(done.lengthOn(tuesday), 1);
      expect(done.isDoneOn(tuesday), isFalse);
    });

    test('handles month changes', () {
      final done = const DailyStreak().complete(DateTime(2026, 10, 31), 100);
      expect(done.complete(DateTime(2026, 11, 1), 100).length, 2);
      expect(DailyChallenge.dayKey(DateTime(2026, 1, 2)), '2026-01-02');
    });
  });

  group('LineupQuizRound', () {
    const map = GameMap(
      uuid: 'ascent',
      displayName: 'Ascent',
      tacticalDescription: 'A/B',
      splash: null,
      displayIcon: null,
      xMultiplier: 1,
      yMultiplier: 1,
      xScalarToAdd: 0,
      yScalarToAdd: 0,
      callouts: [],
    );

    ResolvedLineup spot(String id, {Offset? to}) => ResolvedLineup(
      lineup: Lineup(
        id: id,
        mapName: 'Ascent',
        agentName: 'Sova',
        abilitySlot: 'Ability2',
        abilityName: 'Flèche de reconnaissance',
        side: LineupSide.attack,
        from: const LineupAnchor(calloutName: 'Main', calloutRegion: 'A'),
        to: to == null ? null : const LineupAnchor(calloutName: 'Site', calloutRegion: 'A'),
        title: 'Spot $id',
        description: '',
        difficulty: LineupDifficulty.medium,
        isVerified: false,
        isBundled: true,
      ),
      from: const Offset(0.1, 0.1),
      to: to,
    );

    test('only asks throws, two per map at most, never twice the same target', () {
      final round = LineupQuizRound.create(
        lineupsByMap: {
          map: [
            spot('placement'),
            spot('a', to: const Offset(0.5, 0.5)),
            spot('same-target', to: const Offset(0.5, 0.5)),
            spot('b', to: const Offset(0.2, 0.8)),
            spot('c', to: const Offset(0.8, 0.2)),
          ],
        },
        random: Random(2),
      );

      expect(round.questions, hasLength(2));
      expect(round.questions.every((question) => question.lineup.to != null), isTrue);
      expect(round.questions.map((question) => question.target).toSet(), hasLength(2));
      expect(round.maxScore, 200);
    });

    test('scores a tap by its distance to the landing point', () {
      final question = LineupQuestion(map: map, lineup: spot('a', to: const Offset(0.5, 0.5)));
      expect(question.judge(const Offset(0.5, 0.5)).points, 100);
      expect(question.judge(const Offset(0.95, 0.95)).points, 0);
      expect(question.prompt, contains('Flèche de reconnaissance'));
      expect(question.prompt, contains('A Main'));
    });

    test('is empty without throws', () {
      expect(LineupQuizRound.create(lineupsByMap: {map: [spot('placement')]}).questions, isEmpty);
    });
  });

  test('QuizRun labels the new exercises', () {
    QuizRun run(QuizKind kind, String mode) =>
        QuizRun(kind: kind, label: 'x', mode: mode, score: 0, maxScore: 1, playedAt: DateTime(2026));

    expect(run(QuizKind.daily, 'daily').modeLabel, 'Défi du jour');
    expect(run(QuizKind.lineup, 'placement').modeLabel, 'Placement sur le plan');
    expect(run(QuizKind.weapon, 'mixed').modeKey, 'weapon|x|mixed');
    expect(QuizKind.fromCode('rank'), QuizKind.rank);
  });
}
