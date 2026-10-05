import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_companion/features/profile/domain/match_detail.dart';
import 'package:valorant_companion/features/profile/domain/player_match.dart';

import '../../fixtures/henrik_fixtures.dart';

const _puuid = fixturePuuid;

void main() {
  group('MatchDetail.fromJson', () {
    late MatchDetail detail;

    setUp(() => detail = MatchDetail.fromJson(v4CompetitiveMatch(), puuid: _puuid));

    test('reads the scoreboard of every player', () {
      expect(detail.players, hasLength(3));
      expect(detail.playerTeamId, 'Blue');
      expect(detail.enemyTeamId, 'Red');
      expect(detail.queueId, 'competitive');
      expect(detail.mapId, 'MAP-UUID');
      expect(detail.gameLength.inMinutes, 35);

      final me = detail.players.firstWhere((player) => player.puuid == _puuid);
      expect(me.tierId, 18);
      expect(me.damageDealt, 2600);
      expect(me.headshotPercent, closeTo(25, 0.01));
      expect(me.averageCombatScore(detail.roundCount), closeTo(200, 0.01));
      expect(me.averageDamage(detail.roundCount), closeTo(108.3, 0.1));
    });

    test('lists the player team first, best score first', () {
      expect(detail.teamIds, ['Blue', 'Red']);
      expect(detail.playersOf('Blue').map((player) => player.puuid), [_puuid, 'mate']);
    });

    test('reads rounds, plants and the result wording', () {
      expect(detail.rounds, hasLength(24));
      final first = detail.rounds.first;
      expect(first.isWonBy('Red'), isTrue);
      expect(first.isPlanted, isTrue);
      expect(first.plantSite, 'A');
      expect(first.resultLabel, 'Spike explosé');
      expect(detail.rounds[2].resultLabel, 'Spike désamorcé');
      expect(detail.rounds[1].averageLoadoutOf('Blue'), 1000);
    });

    test('derives the sides from the plants and the halves', () {
      expect(detail.attackingTeam(0), 'Red');
      expect(detail.playerSide(0), RoundSide.defense);
      expect(detail.playerSide(5), RoundSide.defense);
      expect(detail.playerSide(12), RoundSide.attack);
      expect(detail.playerSide(23), RoundSide.attack);
      // Overtime starts back on the first half's sides.
      expect(detail.attackingTeam(24), 'Red');
      expect(detail.attackingTeam(25), 'Blue');
    });

    test('classifies the buys, pistol rounds first', () {
      expect(detail.buyOf('Blue', 0), BuyType.pistol);
      expect(detail.buyOf('Blue', 12), BuyType.pistol);
      expect(detail.buyOf('Blue', 1), BuyType.eco);
      expect(detail.buyOf('Red', 1), BuyType.force);
      expect(detail.buyOf('Blue', 2), BuyType.full);
    });

    test('reads the kills with their location', () {
      expect(detail.kills, hasLength(2));
      final kill = detail.kills.first;
      expect(kill.killerPuuid, _puuid);
      expect(kill.weaponName, 'Sheriff');
      expect(kill.hasLocation, isTrue);
      expect(kill.victimX, 1200);
    });

    test('leaves the sides unknown for modes without halves', () {
      final json = v4CompetitiveMatch();
      (json['metadata'] as Map<String, dynamic>)['queue'] = {'id': 'deathmatch', 'name': 'Deathmatch'};
      (json['rounds'] as List<dynamic>).clear();
      final deathmatch = MatchDetail.fromJson(json, puuid: _puuid);

      expect(deathmatch.playerSide(3), isNull);
      expect(deathmatch.buyOf('Blue', 0), isNull);
    });

    test('recognises the short spellings of the round endings', () {
      MatchRound round(String result) => MatchRound.fromJson({'result': result}, 0, const {});

      expect(round('Defuse').end, RoundEnd.defused);
      expect(round('Bomb defused').resultLabel, 'Spike désamorcé');
      expect(round('Detonate').end, RoundEnd.detonated);
      expect(round('Round timer expired').end, RoundEnd.timeExpired);
      expect(round('Surrendered').end, RoundEnd.surrendered);
      expect(round('Elimination').resultLabel, 'Élimination');
      expect(round('Mystère').resultLabel, 'Mystère');
      expect(round('').resultLabel, '—');
    });

    test('treats a deathmatch as a free-for-all without rounds', () {
      final deathmatch = MatchDetail.fromJson({
        'metadata': {
          'queue': {'id': 'deathmatch', 'name': 'Deathmatch'},
        },
        'players': [
          for (final id in ['me', 'a', 'b', 'c'])
            {'puuid': id, 'team_id': id, 'stats': {'score': id == 'me' ? 4000 : 1000, 'kills': 10}},
        ],
        'rounds': [
          {'winning_team': 'me', 'result': 'Elimination', 'stats': []},
        ],
      }, puuid: 'me');

      expect(deathmatch.isFreeForAll, isTrue);
      expect(deathmatch.isRoundBased, isFalse);
      expect(deathmatch.playersByScore.first.puuid, 'me');
      expect(detail.isFreeForAll, isFalse);
      expect(detail.isRoundBased, isTrue);
    });

    test('survives an empty payload', () {
      final empty = MatchDetail.fromJson(const {}, puuid: _puuid);
      expect(empty.players, isEmpty);
      expect(empty.playerTeamId, isNull);
      expect(empty.teamIds, isEmpty);
      expect(empty.attackingTeam(0), isNull);
    });
  });

  group('PlayerMatch with a v4 payload', () {
    test('rebuilds the accuracy per weapon from the rounds `stats` list', () {
      final match = PlayerMatch.fromJson(v4CompetitiveMatch(), puuid: _puuid);

      expect(match.shotsByWeapon.single.weaponName, 'Vandal');
      expect(match.shotsByWeapon.single.headshots, 24);
      expect(match.shotsByWeapon.single.bodyshots, 48);
      expect(match.mapId, 'MAP-UUID');
      expect(match.isCompetitive, isTrue);
      expect(match.detail?.rounds, hasLength(24));
      expect(match.outcome, MatchOutcome.win);
    });

    test('keeps the history line when the detail is unreadable', () {
      final json = v4CompetitiveMatch()..['rounds'] = [
        {'stats': [
          {'player': {'puuid': _puuid, 'team': 'Blue'}, 'economy': {'loadout_value': 'beaucoup'}},
        ]},
        42,
      ];
      final match = PlayerMatch.fromJson(json, puuid: _puuid);

      expect(match.kills, 10);
      expect(match.outcome, MatchOutcome.win);
    });

    test('carries no detail when the player is missing', () {
      final match = PlayerMatch.fromJson(v4CompetitiveMatch(), puuid: 'stranger');
      expect(match.detail, isNull);
    });
  });
}
