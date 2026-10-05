import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_companion/features/profile/domain/leaderboard.dart';
import 'package:valorant_companion/features/profile/domain/player_match.dart';
import 'package:valorant_companion/features/profile/domain/player_stats_summary.dart';
import 'package:valorant_companion/features/profile/domain/rank_history.dart';

import '../../fixtures/henrik_fixtures.dart';

PlayerMatch _match({
  required String id,
  required DateTime at,
  required MatchOutcome? outcome,
  String agent = 'Jett',
  String map = 'Ascent',
  int kills = 20,
  int deaths = 10,
}) {
  return PlayerMatch(
    matchId: id,
    mapName: map,
    mode: 'Compétitif',
    startedAt: at,
    agentName: agent,
    kills: kills,
    deaths: deaths,
    assists: 2,
    score: 4000,
    roundsWon: outcome == MatchOutcome.win ? 13 : 7,
    roundsLost: outcome == MatchOutcome.win ? 7 : 13,
    outcome: outcome,
    shotsByWeapon: const [],
    queueId: 'competitive',
  );
}

void main() {
  final now = DateTime(2026, 10, 5, 22);

  group('PlayerStatsSummary', () {
    test('groups the games per agent and per map', () {
      final summary = PlayerStatsSummary.from([
        _match(id: '1', at: now, outcome: MatchOutcome.win, agent: 'Jett', map: 'Ascent'),
        _match(id: '2', at: now.subtract(const Duration(hours: 1)), outcome: MatchOutcome.loss, agent: 'Jett', map: 'Bind'),
        _match(id: '3', at: now.subtract(const Duration(hours: 2)), outcome: MatchOutcome.win, agent: 'Sova', map: 'Ascent'),
      ]);

      expect(summary.overall.played, 3);
      expect(summary.agents.first.agentName, 'Jett');
      expect(summary.agents.first.games, 2);
      expect(summary.agents.first.record.winRate, 50);
      expect(summary.agents.first.killDeathRatio, 2);
      expect(summary.agents.first.averageCombatScore, closeTo(200, 0.01));
      expect(summary.maps.first.mapName, 'Ascent');
      expect(summary.maps.first.record.wins, 2);
    });

    test('keeps the session to games played close together', () {
      final summary = PlayerStatsSummary.from(
        [
          _match(id: '1', at: now, outcome: MatchOutcome.win),
          _match(id: '2', at: now.subtract(const Duration(hours: 1)), outcome: MatchOutcome.win),
          _match(id: '3', at: now.subtract(const Duration(days: 1)), outcome: MatchOutcome.loss),
        ],
        rankHistory: [
          RankHistoryEntry.fromJson(const {'match_id': '1', 'last_change': 21, 'elo': 1500}),
          RankHistoryEntry.fromJson(const {'match_id': '2', 'last_change': 18, 'elo': 1479}),
          RankHistoryEntry.fromJson(const {'match_id': '3', 'last_change': -15, 'elo': 1461}),
        ],
      );

      final session = summary.session!;
      expect(session.matches.map((match) => match.matchId), ['1', '2']);
      expect(session.record.wins, 2);
      expect(session.rankedRatingChange, 39);
      expect(session.rankedGames, 2);
    });

    test('reports no RR balance without history', () {
      final summary = PlayerStatsSummary.from([_match(id: '1', at: now, outcome: MatchOutcome.win)]);
      expect(summary.session?.rankedRatingChange, isNull);
    });

    test('counts the current streak, skipping games without a result', () {
      final summary = PlayerStatsSummary.from([
        _match(id: '1', at: now, outcome: MatchOutcome.loss),
        _match(id: '2', at: now.subtract(const Duration(minutes: 40)), outcome: null),
        _match(id: '3', at: now.subtract(const Duration(minutes: 80)), outcome: MatchOutcome.loss),
        _match(id: '4', at: now.subtract(const Duration(minutes: 120)), outcome: MatchOutcome.win),
      ]);

      expect(summary.streak?.outcome, MatchOutcome.loss);
      expect(summary.streak?.length, 2);
    });

    test('sorts unordered games before building the session', () {
      final summary = PlayerStatsSummary.from([
        _match(id: 'old', at: now.subtract(const Duration(days: 2)), outcome: MatchOutcome.loss),
        _match(id: 'new', at: now, outcome: MatchOutcome.win),
      ]);
      expect(summary.session?.matches.single.matchId, 'new');
      expect(summary.streak?.outcome, MatchOutcome.win);
    });

    test('splits the rounds between attack and defense', () {
      final match = PlayerMatch.fromJson(v4CompetitiveMatch(), puuid: 'me');
      final summary = PlayerStatsSummary.from([match]);

      // First half on defense: lost round 1, won rounds 2 to 12.
      expect(summary.sides.defense.played, 12);
      expect(summary.sides.defense.wins, 11);
      // Second half on attack: every round lost.
      expect(summary.sides.attack.played, 12);
      expect(summary.sides.attack.wins, 0);
    });

    test('names the best and the worst map once two qualify', () {
      final summary = PlayerStatsSummary.from([
        _match(id: '1', at: now, outcome: MatchOutcome.win, map: 'Ascent'),
        _match(id: '2', at: now, outcome: MatchOutcome.win, map: 'Ascent'),
        _match(id: '3', at: now, outcome: MatchOutcome.loss, map: 'Bind'),
        _match(id: '4', at: now, outcome: MatchOutcome.loss, map: 'Bind'),
      ]);
      final maps = summary.bestAndWorstMaps();
      expect(maps?.$1.mapName, 'Ascent');
      expect(maps?.$2.mapName, 'Bind');
      expect(PlayerStatsSummary.from(const []).bestAndWorstMaps(), isNull);
      expect(PlayerStatsSummary.from(const []).isEmpty, isTrue);
    });
  });

  group('RankHistoryEntry', () {
    test('reads the v2 history, most recent first, dropping entries without elo', () {
      final entries = RankHistoryEntry.listFromJson({
        'account': {'name': 'a', 'tag': 'b', 'puuid': 'c'},
        'history': [
          {
            'match_id': 'old',
            'tier': {'id': 15, 'name': 'Platinum 1'},
            'map': {'id': 'x', 'name': 'Bind'},
            'season': {'id': 's', 'short': 'e10a1'},
            'rr': 40,
            'last_change': -12,
            'elo': 1240,
            'date': '2026-10-01T10:00:00.000Z',
          },
          {
            'match_id': 'new',
            'tier': {'id': 15, 'name': 'Platinum 1'},
            'map': {'id': 'x', 'name': 'Ascent'},
            'rr': 61,
            'last_change': 21,
            'elo': 1261,
            'date': '2026-10-02T10:00:00.000Z',
          },
          {'match_id': 'broken'},
        ],
      });

      expect(entries.map((entry) => entry.matchId), ['new', 'old']);
      expect(entries.first.tierName, 'Platinum 1');
      expect(entries.first.mapName, 'Ascent');
      expect(entries.last.seasonShort, 'e10a1');
      expect(entries.last.lastChange, -12);
    });

    test('accepts a bare list and garbage', () {
      expect(RankHistoryEntry.listFromJson([
        {'match_id': 'a', 'elo': 100},
      ]), hasLength(1));
      expect(RankHistoryEntry.listFromJson(null), isEmpty);
      expect(RankHistoryEntry.listFromJson('nope'), isEmpty);
    });
  });

  group('Leaderboard', () {
    test('reads the v3 players in rank order', () {
      final leaderboard = Leaderboard.fromJson({
        'updated_at': '2026-10-05T08:00:00.000Z',
        'thresholds': [],
        'players': [
          {
            'leaderboard_rank': 2,
            'name': 'Second',
            'tag': 'EU2',
            'tier': 27,
            'rr': 900,
            'wins': 300,
            'card': 'card-uuid',
            'is_anonymized': false,
          },
          {'leaderboard_rank': 1, 'name': '', 'tag': '', 'tier': 27, 'rr': 1100, 'wins': 410, 'is_anonymized': true},
        ],
      });

      expect(leaderboard.players.map((player) => player.rank), [1, 2]);
      expect(leaderboard.players.first.label, 'Joueur anonyme');
      expect(leaderboard.players.last.label, 'Second#EU2');
      expect(
        leaderboard.players.last.cardImageUrl,
        'https://media.valorant-api.com/playercards/card-uuid/smallart.png',
      );
      expect(leaderboard.players.first.cardImageUrl, isNull);
      expect(leaderboard.updatedAt, isNotNull);
    });

    test('filters by name', () {
      final player = LeaderboardPlayer.fromJson(const {'leaderboard_rank': 1, 'name': 'TenZ', 'tag': 'NA1'});
      expect(player.matches('tenz'), isTrue);
      expect(player.matches('  '), isTrue);
      expect(player.matches('aspas'), isFalse);
    });
  });
}
