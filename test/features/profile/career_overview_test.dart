import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_companion/features/profile/domain/career_overview.dart';
import 'package:valorant_companion/features/profile/domain/match_detail.dart';
import 'package:valorant_companion/features/profile/domain/player_match.dart';

import '../../fixtures/henrik_fixtures.dart';

Map<String, dynamic> _kill(int round, int time, String killer, String killerTeam, String victim, String victimTeam) => {
  'round': round,
  'time_in_round_in_ms': time,
  'killer': {'puuid': killer, 'team': killerTeam},
  'victim': {'puuid': victim, 'team': victimTeam},
  'weapon': {'id': 'VANDAL-ID', 'name': 'Vandal'},
  'assistants': [],
};

void main() {
  group('MatchDetail.highlightsOf', () {
    test('counts KAST, first bloods, flawless rounds and kills per weapon', () {
      final detail = MatchDetail.fromJson(v4CompetitiveMatch(), puuid: fixturePuuid);
      final highlights = detail.highlightsOf(fixturePuuid)!;

      expect(highlights.rounds, 24);
      // Every round but the second, where the player died untraded.
      expect(highlights.kastRounds, 23);
      expect(highlights.firstBloods, 1);
      expect(highlights.aces, 0);
      // Rounds 3 to 12 were won by the player's team without a death.
      expect(highlights.flawlessRounds, 10);
      expect(highlights.weaponKills.single.weaponName, 'Sheriff');
      expect(highlights.weaponKills.single.weaponId, 'w');
      expect(highlights.weaponKills.single.kills, 1);
    });

    test('counts a death avenged within five seconds as traded', () {
      final json = v4CompetitiveMatch()
        ..['kills'] = [
          _kill(0, 10000, 'enemy', 'Red', fixturePuuid, 'Blue'),
          _kill(0, 13000, 'mate', 'Blue', 'enemy', 'Red'),
          _kill(1, 10000, 'enemy', 'Red', fixturePuuid, 'Blue'),
          _kill(1, 18000, 'mate', 'Blue', 'enemy', 'Red'),
        ];
      final highlights = MatchDetail.fromJson(json, puuid: fixturePuuid).highlightsOf(fixturePuuid)!;

      // Round 1 traded (3 s), round 2 too late (8 s): 23 of 24.
      expect(highlights.kastRounds, 23);
      expect(highlights.firstBloods, 0);
    });

    test('spots an ace', () {
      final json = v4CompetitiveMatch()
        ..['kills'] = [
          for (var index = 0; index < 5; index++) _kill(4, 1000 * index, fixturePuuid, 'Blue', 'enemy$index', 'Red'),
        ];
      final highlights = MatchDetail.fromJson(json, puuid: fixturePuuid).highlightsOf(fixturePuuid)!;

      expect(highlights.aces, 1);
      expect(highlights.weaponKills.single.kills, 5);
      expect(highlights.weaponKills.single.weaponId, 'vandal-id', reason: 'ids are lower-cased');
    });

    test('has nothing to say about a game without rounds', () {
      final json = v4CompetitiveMatch()..['rounds'] = [];
      expect(MatchDetail.fromJson(json, puuid: fixturePuuid).highlightsOf(fixturePuuid), isNull);
      expect(MatchDetail.fromJson(v4CompetitiveMatch(), puuid: 'stranger').highlightsOf('stranger'), isNull);
    });
  });

  group('CareerOverview', () {
    test('sums the headline figures, weapons, roles and agents', () {
      final match = PlayerMatch.fromJson(v4CompetitiveMatch(), puuid: fixturePuuid);
      final overview = CareerOverview.from([match], puuid: fixturePuuid, roleOfAgent: const {'jett': 'Duelliste'});

      expect(overview.matchCount, 1);
      expect(overview.winRate, 100);
      expect(overview.killDeathRatio, closeTo(10 / 8, 0.001));
      expect(overview.kadRatio, closeTo(13 / 8, 0.001));
      expect(overview.averageCombatScore, closeTo(200, 0.01));
      expect(overview.averageDamage, closeTo(2600 / 24, 0.01));
      expect(overview.headshotPercent, closeTo(100 / 3, 0.01));
      expect(overview.kastPercent, closeTo(23 * 100 / 24, 0.01));
      expect(overview.firstBloods, 1);
      expect(overview.flawlessRounds, 10);

      expect(overview.weapons.map((weapon) => weapon.weaponName), ['Sheriff', 'Vandal']);
      expect(overview.weapons.first.kills, 1);
      expect(overview.weapons.last.headshotPercent, closeTo(100 / 3, 0.01));

      expect(overview.roles.single.role, 'Duelliste');
      expect(overview.roles.single.kda, closeTo(13 / 8, 0.001));

      final jett = overview.agents.single;
      expect(jett.agentName, 'Jett');
      expect(jett.bestMapName, 'Ascent');
      expect(jett.bestMapWinRate, 100);
      expect(jett.averageDamage, closeTo(2600 / 24, 0.01));
    });

    test('leaves out the games without rounds and copes with nothing', () {
      final deathmatch = PlayerMatch(
        matchId: 'dm',
        mapName: 'Haven',
        mode: 'Deathmatch',
        startedAt: null,
        agentName: 'Jett',
        kills: 40,
        deaths: 10,
        assists: 0,
        score: 9000,
        roundsWon: 40,
        roundsLost: 0,
        outcome: MatchOutcome.win,
        shotsByWeapon: const [],
        queueId: 'deathmatch',
      );
      final overview = CareerOverview.from([deathmatch], puuid: fixturePuuid);

      expect(overview.isEmpty, isTrue);
      expect(overview.averageCombatScore, isNull);
      expect(overview.headshotPercent, isNull);
      expect(overview.kastPercent, isNull);
      expect(overview.killDeathRatio, 0);
    });
  });
}
