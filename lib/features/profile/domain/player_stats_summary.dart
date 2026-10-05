import 'match_detail.dart';
import 'player_match.dart';
import 'rank_history.dart';

/// Wins and losses over a set of games or rounds.
class WinRecord {
  const WinRecord({this.wins = 0, this.losses = 0, this.draws = 0});

  final int wins;
  final int losses;
  final int draws;

  int get played => wins + losses + draws;
  double? get winRate => played == 0 ? null : wins * 100 / played;

  WinRecord add(MatchOutcome? outcome) => switch (outcome) {
    MatchOutcome.win => WinRecord(wins: wins + 1, losses: losses, draws: draws),
    MatchOutcome.loss => WinRecord(wins: wins, losses: losses + 1, draws: draws),
    MatchOutcome.draw => WinRecord(wins: wins, losses: losses, draws: draws + 1),
    null => this,
  };
}

/// How one agent went over the loaded games.
class AgentStats {
  const AgentStats({
    required this.agentName,
    required this.record,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.score,
    required this.rounds,
  });

  final String agentName;
  final WinRecord record;
  final int kills;
  final int deaths;
  final int assists;
  final int score;
  final int rounds;

  int get games => record.played;
  double get killDeathRatio => deaths == 0 ? kills.toDouble() : kills / deaths;
  double? get averageCombatScore => rounds == 0 ? null : score / rounds;
}

/// How one map went over the loaded games.
class MapStats {
  const MapStats({required this.mapName, required this.record, required this.roundsWon, required this.roundsLost});

  final String mapName;
  final WinRecord record;
  final int roundsWon;
  final int roundsLost;
}

/// Rounds won on each side of the map.
class SideStats {
  const SideStats({required this.attack, required this.defense});

  final WinRecord attack;
  final WinRecord defense;

  bool get isEmpty => attack.played == 0 && defense.played == 0;
}

/// The last games played in a row, as a session.
class SessionSummary {
  const SessionSummary({
    required this.matches,
    required this.record,
    required this.rankedRatingChange,
    required this.rankedGames,
    required this.kills,
    required this.deaths,
  });

  final List<PlayerMatch> matches;
  final WinRecord record;

  /// Sum of the RR movements of the session's competitive games, null when
  /// none of them is in the RR history.
  final int? rankedRatingChange;
  final int rankedGames;
  final int kills;
  final int deaths;

  DateTime? get startedAt => matches.isEmpty ? null : matches.last.startedAt;
  double get killDeathRatio => deaths == 0 ? kills.toDouble() : kills / deaths;
}

/// The current run of identical results, most recent game first.
class Streak {
  const Streak({required this.outcome, required this.length});

  final MatchOutcome outcome;
  final int length;
}

/// Everything the profile derives from the loaded match history: per agent,
/// per map, per side, plus the latest session and streak. Nothing here
/// costs a request.
class PlayerStatsSummary {
  const PlayerStatsSummary({
    required this.matchCount,
    required this.overall,
    required this.agents,
    required this.maps,
    required this.sides,
    required this.session,
    required this.streak,
  });

  /// Two games further apart than this belong to different sessions.
  static const sessionGap = Duration(hours: 3);

  /// Deathmatch-like games are left out: their kill counts read as rounds,
  /// and their "wins" would inflate every win rate.
  factory PlayerStatsSummary.from(List<PlayerMatch> matches, {List<RankHistoryEntry> rankHistory = const []}) {
    final sorted = [...matches.where((match) => match.isRoundBased)]
      ..sort((a, b) {
        final aDate = a.startedAt;
        final bDate = b.startedAt;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });

    var overall = const WinRecord();
    final agents = <String, AgentStats>{};
    final maps = <String, MapStats>{};
    var attack = const WinRecord();
    var defense = const WinRecord();

    for (final match in sorted) {
      overall = overall.add(match.outcome);
      final rounds = match.roundsWon + match.roundsLost;

      if (match.agentName.isNotEmpty) {
        final current = agents[match.agentName];
        agents[match.agentName] = AgentStats(
          agentName: match.agentName,
          record: (current?.record ?? const WinRecord()).add(match.outcome),
          kills: (current?.kills ?? 0) + match.kills,
          deaths: (current?.deaths ?? 0) + match.deaths,
          assists: (current?.assists ?? 0) + match.assists,
          score: (current?.score ?? 0) + match.score,
          rounds: (current?.rounds ?? 0) + rounds,
        );
      }

      if (match.mapName.isNotEmpty && match.outcome != null) {
        final current = maps[match.mapName];
        maps[match.mapName] = MapStats(
          mapName: match.mapName,
          record: (current?.record ?? const WinRecord()).add(match.outcome),
          roundsWon: (current?.roundsWon ?? 0) + match.roundsWon,
          roundsLost: (current?.roundsLost ?? 0) + match.roundsLost,
        );
      }

      final detail = match.detail;
      final team = detail?.playerTeamId;
      if (detail == null || team == null) continue;
      for (final round in detail.rounds) {
        if (round.winningTeam.isEmpty) continue;
        final outcome = round.isWonBy(team) ? MatchOutcome.win : MatchOutcome.loss;
        switch (detail.playerSide(round.index)) {
          case RoundSide.attack:
            attack = attack.add(outcome);
          case RoundSide.defense:
            defense = defense.add(outcome);
          case null:
            break;
        }
      }
    }

    final agentList = agents.values.toList()
      ..sort((a, b) {
        final byGames = b.games.compareTo(a.games);
        return byGames != 0 ? byGames : b.kills.compareTo(a.kills);
      });
    final mapList = maps.values.toList()
      ..sort((a, b) {
        final byGames = b.record.played.compareTo(a.record.played);
        return byGames != 0 ? byGames : (b.record.winRate ?? 0).compareTo(a.record.winRate ?? 0);
      });

    return PlayerStatsSummary(
      matchCount: sorted.length,
      overall: overall,
      agents: agentList,
      maps: mapList,
      sides: SideStats(attack: attack, defense: defense),
      session: _session(sorted, rankHistory),
      streak: _streak(sorted),
    );
  }

  /// How many round-based games the figures come from.
  final int matchCount;
  final WinRecord overall;
  final List<AgentStats> agents;
  final List<MapStats> maps;
  final SideStats sides;
  final SessionSummary? session;
  final Streak? streak;

  bool get isEmpty => overall.played == 0 && agents.isEmpty;

  /// The best and worst maps, among those played at least [minimumGames]
  /// times. Null when fewer than two maps qualify.
  (MapStats best, MapStats worst)? bestAndWorstMaps({int minimumGames = 2}) {
    final eligible = [
      for (final map in maps)
        if (map.record.played >= minimumGames && map.record.winRate != null) map,
    ];
    if (eligible.length < 2) return null;

    eligible.sort((a, b) => b.record.winRate!.compareTo(a.record.winRate!));
    return (eligible.first, eligible.last);
  }

  static SessionSummary? _session(List<PlayerMatch> sorted, List<RankHistoryEntry> rankHistory) {
    if (sorted.isEmpty) return null;

    final session = <PlayerMatch>[sorted.first];
    for (final match in sorted.skip(1)) {
      final previous = session.last.startedAt;
      final current = match.startedAt;
      if (previous == null || current == null) break;
      if (previous.difference(current) > sessionGap) break;
      session.add(match);
    }

    final changeByMatch = {for (final entry in rankHistory) entry.matchId: entry.lastChange};
    var rankedGames = 0;
    var change = 0;
    for (final match in session) {
      final delta = changeByMatch[match.matchId];
      if (delta == null) continue;
      rankedGames++;
      change += delta;
    }

    var record = const WinRecord();
    for (final match in session) {
      record = record.add(match.outcome);
    }

    return SessionSummary(
      matches: session,
      record: record,
      rankedRatingChange: rankedGames == 0 ? null : change,
      rankedGames: rankedGames,
      kills: session.fold(0, (sum, match) => sum + match.kills),
      deaths: session.fold(0, (sum, match) => sum + match.deaths),
    );
  }

  static Streak? _streak(List<PlayerMatch> sorted) {
    MatchOutcome? outcome;
    var length = 0;

    for (final match in sorted) {
      final current = match.outcome;
      // Deathmatch and the like have no result: they neither extend nor
      // break a streak. A draw ends it.
      if (current == null) continue;
      if (current == MatchOutcome.draw) break;
      if (outcome == null) {
        outcome = current;
        length = 1;
      } else if (current == outcome) {
        length++;
      } else {
        break;
      }
    }

    if (outcome == null) return null;
    return Streak(outcome: outcome, length: length);
  }
}
