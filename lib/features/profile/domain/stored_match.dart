import 'json_reading.dart';
import 'player_stats_summary.dart';

/// One game of the light history HenrikDev keeps for every account: no round
/// detail, but the map, the agent, the season and the player's figures. It
/// reaches back far enough to sum up a whole act.
class StoredMatch {
  const StoredMatch({
    required this.id,
    required this.mapName,
    required this.mode,
    required this.startedAt,
    required this.seasonId,
    required this.seasonShort,
    required this.agentId,
    required this.agentName,
    required this.tier,
    required this.score,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.headshots,
    required this.bodyshots,
    required this.legshots,
    required this.damageMade,
    required this.teamRounds,
    required this.enemyRounds,
  });

  static StoredMatch? fromJson(Object? json) {
    final entry = asMap(json);
    final meta = asMap(entry['meta']);
    final stats = asMap(entry['stats']);
    final id = asStringOrNull(meta['id']);
    if (id == null || stats.isEmpty) return null;

    final teams = asMap(entry['teams']);
    final team = (asStringOrNull(stats['team']) ?? '').toLowerCase();
    final red = asInt(teams['red']);
    final blue = asInt(teams['blue']);
    final shots = asMap(stats['shots']);
    final character = stats['character'];

    return StoredMatch(
      id: id,
      mapName: displayNameOf(meta['map']),
      mode: asStringOrNull(meta['mode']) ?? '',
      startedAt: dateOf(meta['started_at']),
      seasonId: idOf(meta['season']),
      seasonShort: asStringOrNull(asMap(meta['season'])['short']),
      agentId: idOf(character),
      agentName: displayNameOf(character),
      tier: asInt(stats['tier']),
      score: asInt(stats['score']),
      kills: asInt(stats['kills']),
      deaths: asInt(stats['deaths']),
      assists: asInt(stats['assists']),
      headshots: asInt(shots['head']),
      bodyshots: asInt(shots['body']),
      legshots: asInt(shots['leg']),
      damageMade: asInt(asMap(stats['damage'])['made']),
      teamRounds: team == 'blue' ? blue : red,
      enemyRounds: team == 'blue' ? red : blue,
    );
  }

  static List<StoredMatch> listFromJson(Object? data) => [for (final entry in asList(data)) ?fromJson(entry)];

  final String id;
  final String mapName;
  final String mode;
  final DateTime? startedAt;
  final String? seasonId;

  /// Like "e11a5": episode 11, act 5.
  final String? seasonShort;
  final String? agentId;
  final String agentName;

  /// The player's competitive tier during that game.
  final int tier;
  final int score;
  final int kills;
  final int deaths;
  final int assists;
  final int headshots;
  final int bodyshots;
  final int legshots;
  final int damageMade;
  final int teamRounds;
  final int enemyRounds;

  int get rounds => teamRounds + enemyRounds;
  bool get isWin => teamRounds > enemyRounds;
  bool get isDraw => teamRounds == enemyRounds;
}

/// Kills, deaths, shots, damage and score summed over a set of games.
class StoredTotals {
  const StoredTotals._({
    required this.record,
    required this.rounds,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.headshots,
    required this.shots,
    required this.damage,
    required this.score,
  });

  factory StoredTotals.of(Iterable<StoredMatch> matches) {
    var wins = 0, losses = 0, draws = 0, rounds = 0, kills = 0, deaths = 0, assists = 0;
    var headshots = 0, shots = 0, damage = 0, score = 0;
    for (final match in matches) {
      if (match.isWin) {
        wins++;
      } else if (match.isDraw) {
        draws++;
      } else {
        losses++;
      }
      rounds += match.rounds;
      kills += match.kills;
      deaths += match.deaths;
      assists += match.assists;
      headshots += match.headshots;
      shots += match.headshots + match.bodyshots + match.legshots;
      damage += match.damageMade;
      score += match.score;
    }
    return StoredTotals._(
      record: WinRecord(wins: wins, losses: losses, draws: draws),
      rounds: rounds,
      kills: kills,
      deaths: deaths,
      assists: assists,
      headshots: headshots,
      shots: shots,
      damage: damage,
      score: score,
    );
  }

  final WinRecord record;
  final int rounds;
  final int kills;
  final int deaths;
  final int assists;
  final int headshots;
  final int shots;
  final int damage;
  final int score;

  int get matches => record.played;

  double? get killDeathRatio => matches == 0 ? null : kills / (deaths == 0 ? 1 : deaths);
  double? get kdaRatio => matches == 0 ? null : (kills + assists) / (deaths == 0 ? 1 : deaths);
  double? get headshotPercent => shots == 0 ? null : headshots * 100 / shots;
  double? get averageDamage => rounds == 0 ? null : damage / rounds;
  double? get averageCombatScore => rounds == 0 ? null : score / rounds;
  double? get killsPerMatch => matches == 0 ? null : kills / matches;
}

/// A group of games sharing a map or an agent.
class StoredGroup {
  const StoredGroup({required this.name, required this.id, required this.totals});

  final String name;
  final String? id;
  final StoredTotals totals;
}

/// The competitive act at a glance, as tracker sites show it: the overall
/// figures, then per map and per agent.
class SeasonStats {
  const SeasonStats._({
    required this.seasonId,
    required this.seasonShort,
    required this.totals,
    required this.maps,
    required this.agents,
    required this.peakTier,
  });

  /// Keeps the games of [seasonId], or of the latest game's season when the
  /// act is unknown.
  factory SeasonStats.from(List<StoredMatch> matches, {String? seasonId}) {
    final season = seasonId ?? (matches.isEmpty ? null : matches.first.seasonId);
    final played = [
      for (final match in matches)
        if (match.rounds > 0 && (season == null || match.seasonId == season)) match,
    ];

    List<StoredGroup> groupBy(String Function(StoredMatch) name, String? Function(StoredMatch) id) {
      final groups = <String, List<StoredMatch>>{};
      for (final match in played) {
        final key = name(match);
        if (key.isEmpty) continue;
        groups.putIfAbsent(key, () => []).add(match);
      }
      return [
        for (final entry in groups.entries)
          StoredGroup(name: entry.key, id: id(entry.value.first), totals: StoredTotals.of(entry.value)),
      ]..sort((a, b) {
        final byGames = b.totals.matches.compareTo(a.totals.matches);
        return byGames != 0 ? byGames : (b.totals.record.winRate ?? 0).compareTo(a.totals.record.winRate ?? 0);
      });
    }

    var peak = 0;
    for (final match in played) {
      if (match.tier > peak) peak = match.tier;
    }

    return SeasonStats._(
      seasonId: season,
      seasonShort: played.isEmpty ? null : played.first.seasonShort,
      totals: StoredTotals.of(played),
      maps: groupBy((match) => match.mapName, (match) => null),
      agents: groupBy((match) => match.agentName, (match) => match.agentId),
      peakTier: peak == 0 ? null : peak,
    );
  }

  final String? seasonId;
  final String? seasonShort;
  final StoredTotals totals;

  /// Most played first.
  final List<StoredGroup> maps;

  /// Most played first.
  final List<StoredGroup> agents;

  /// The highest tier held during the act's games.
  final int? peakTier;

  bool get isEmpty => totals.matches == 0;

  /// "e11a5" read as "Épisode 11 · Acte 5".
  String? get seasonLabel {
    final match = RegExp(r'^e(\d+)a(\d+)$').firstMatch(seasonShort ?? '');
    if (match == null) return null;
    return 'Épisode ${match.group(1)} · Acte ${match.group(2)}';
  }
}
