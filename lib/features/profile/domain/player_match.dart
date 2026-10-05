import 'json_reading.dart';
import 'match_detail.dart';

enum MatchOutcome { win, loss, draw }

/// How a player's shots landed with one weapon, over one match.
class WeaponShots {
  const WeaponShots({
    required this.weaponName,
    required this.headshots,
    required this.bodyshots,
    required this.legshots,
  });

  final String weaponName;
  final int headshots;
  final int bodyshots;
  final int legshots;

  int get total => headshots + bodyshots + legshots;
}

/// One match of the player's history, reduced to what the profile shows.
class PlayerMatch {
  const PlayerMatch({
    required this.matchId,
    required this.mapName,
    required this.mode,
    required this.startedAt,
    required this.agentName,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.score,
    required this.roundsWon,
    required this.roundsLost,
    required this.outcome,
    required this.shotsByWeapon,
    this.mapId,
    this.queueId = '',
    this.detail,
  });

  /// Parses one entry of the HenrikDev match list. Several field names moved
  /// between v2 and v4 of that API, so each read falls back to the other
  /// spelling.
  factory PlayerMatch.fromJson(Map<String, dynamic> json, {required String puuid}) {
    final metadata = asMap(json['metadata']);
    final player = _findPlayer(json, puuid);
    final stats = asMap(player['stats']);
    final teamId = (player['team_id'] ?? player['team'])?.toString();
    final rounds = _roundScore(json, teamId);

    return PlayerMatch(
      matchId: (metadata['match_id'] ?? metadata['matchid'] ?? '').toString(),
      mapName: displayNameOf(metadata['map']),
      mode: displayNameOf(metadata['queue'] ?? metadata['mode']),
      startedAt: _startedAt(metadata),
      agentName: displayNameOf(player['agent'] ?? player['character']),
      kills: asInt(stats['kills']),
      deaths: asInt(stats['deaths']),
      assists: asInt(stats['assists']),
      score: asInt(stats['score']),
      roundsWon: rounds.$1,
      roundsLost: rounds.$2,
      outcome: _outcome(json, teamId, rounds),
      shotsByWeapon: _shotsByWeapon(json, puuid, player),
      mapId: idOf(metadata['map']) ?? asStringOrNull(metadata['map_id']),
      queueId: (idOf(metadata['queue']) ?? metadata['mode_id'] ?? '').toString().toLowerCase(),
      detail: player.isEmpty ? null : _detailOf(json, puuid),
    );
  }

  final String matchId;
  final String mapName;
  final String mode;
  final DateTime? startedAt;
  final String agentName;
  final int kills;
  final int deaths;
  final int assists;
  final int score;
  final int roundsWon;
  final int roundsLost;
  final MatchOutcome? outcome;
  final List<WeaponShots> shotsByWeapon;

  /// valorant-api.com uuid of the map, when the payload carries it.
  final String? mapId;

  /// Riot's queue id, e.g. `competitive`, lower-cased.
  final String queueId;

  /// The full scoreboard, rounds and kills, for the match screen.
  final MatchDetail? detail;

  bool get isCompetitive => queueId == 'competitive';

  /// Queues played without rounds, whose "score" is a kill count.
  static const _queuesWithoutRounds = {'deathmatch', 'hurm', 'ggteam', 'snowball'};

  /// Whether the game was played in rounds (competitive, unrated, swiftplay…).
  /// The per agent / map / side figures only make sense for those.
  bool get isRoundBased {
    final detail = this.detail;
    if (detail != null && detail.rounds.isNotEmpty) return detail.isRoundBased;
    return !_queuesWithoutRounds.contains(queueId);
  }

  int get headshots => shotsByWeapon.fold(0, (sum, shots) => sum + shots.headshots);
  int get totalShots => shotsByWeapon.fold(0, (sum, shots) => sum + shots.total);
  double? get headshotPercent => totalShots == 0 ? null : headshots * 100 / totalShots;
  double get killDeathRatio => deaths == 0 ? kills.toDouble() : kills / deaths;
}

Map<String, dynamic> _findPlayer(Map<String, dynamic> json, String puuid) {
  final players = json['players'];
  final entries = players is Map<String, dynamic> ? asList(players['all_players']) : asList(players);

  for (final entry in entries) {
    final player = asMap(entry);
    if (player['puuid'] == puuid) return player;
  }
  return const {};
}

DateTime? _startedAt(Map<String, dynamic> metadata) {
  final iso = (metadata['started_at'] ?? metadata['game_start_iso'])?.toString();
  if (iso != null) {
    final parsed = DateTime.tryParse(iso);
    if (parsed != null) return parsed.toLocal();
  }

  final epochSeconds = metadata['game_start'];
  if (epochSeconds is num) {
    return DateTime.fromMillisecondsSinceEpoch(epochSeconds.round() * 1000).toLocal();
  }
  return null;
}

/// Rounds won and lost by the player's team.
(int, int) _roundScore(Map<String, dynamic> json, String? teamId) {
  final team = _findTeam(json, teamId);
  if (team.isEmpty) return (0, 0);

  final rounds = team['rounds'];
  if (rounds is Map<String, dynamic>) {
    return (asInt(rounds['won']), asInt(rounds['lost']));
  }
  return (asInt(team['rounds_won']), asInt(team['rounds_lost']));
}

Map<String, dynamic> _findTeam(Map<String, dynamic> json, String? teamId) {
  if (teamId == null) return const {};
  final teams = json['teams'];

  if (teams is Map<String, dynamic>) return asMap(teams[teamId.toLowerCase()]);

  for (final entry in asList(teams)) {
    final team = asMap(entry);
    if ((team['team_id'] ?? team['team'])?.toString().toLowerCase() == teamId.toLowerCase()) {
      return team;
    }
  }
  return const {};
}

MatchOutcome? _outcome(Map<String, dynamic> json, String? teamId, (int, int) rounds) {
  final team = _findTeam(json, teamId);
  final won = team['won'] ?? team['has_won'];
  if (won is bool) return won ? MatchOutcome.win : MatchOutcome.loss;

  if (rounds.$1 == 0 && rounds.$2 == 0) return null;
  if (rounds.$1 == rounds.$2) return MatchOutcome.draw;
  return rounds.$1 > rounds.$2 ? MatchOutcome.win : MatchOutcome.loss;
}

/// Riot never reports accuracy per weapon, so it is rebuilt round by round:
/// each round records the weapon the player was holding and where their
/// damage landed. Rounds without a shot fired are skipped.
List<WeaponShots> _shotsByWeapon(Map<String, dynamic> json, String puuid, Map<String, dynamic> player) {
  final headshots = <String, int>{};
  final bodyshots = <String, int>{};
  final legshots = <String, int>{};

  for (final roundEntry in asList(json['rounds'])) {
    for (final statEntry in _roundPlayerStats(asMap(roundEntry))) {
      final roundStats = asMap(statEntry);
      final statPuuid = (roundStats['puuid'] ?? asMap(roundStats['player'])['puuid'])?.toString();
      if (statPuuid != puuid) continue;

      final weapon = _weaponOf(roundStats);
      if (weapon.isEmpty) continue;

      final shots = _roundShots(roundStats);
      if (shots.$1 + shots.$2 + shots.$3 == 0) continue;

      headshots[weapon] = (headshots[weapon] ?? 0) + shots.$1;
      bodyshots[weapon] = (bodyshots[weapon] ?? 0) + shots.$2;
      legshots[weapon] = (legshots[weapon] ?? 0) + shots.$3;
    }
  }

  if (headshots.isEmpty) return _matchWideShots(player);

  final weapons = [
    for (final weapon in headshots.keys)
      WeaponShots(
        weaponName: weapon,
        headshots: headshots[weapon] ?? 0,
        bodyshots: bodyshots[weapon] ?? 0,
        legshots: legshots[weapon] ?? 0,
      ),
  ];
  weapons.sort((a, b) => b.total.compareTo(a.total));
  return weapons;
}

String _weaponOf(Map<String, dynamic> roundStats) {
  final economy = asMap(roundStats['economy']);
  final weapon = roundStats['weapon'] ?? economy['weapon'];
  return displayNameOf(weapon).trim();
}

/// Head, body and leg shots of one player during one round.
(int, int, int) _roundShots(Map<String, dynamic> roundStats) {
  final stats = asMap(roundStats['stats']);
  if (stats.containsKey('headshots')) {
    return (asInt(stats['headshots']), asInt(stats['bodyshots']), asInt(stats['legshots']));
  }

  var headshots = 0;
  var bodyshots = 0;
  var legshots = 0;
  for (final eventEntry in asList(roundStats['damage_events'] ?? roundStats['damage'])) {
    final event = asMap(eventEntry);
    headshots += asInt(event['headshots']);
    bodyshots += asInt(event['bodyshots']);
    legshots += asInt(event['legshots']);
  }
  return (headshots, bodyshots, legshots);
}

/// Fallback when a match carries no round detail: the totals the API reports
/// for the whole match, which are not split per weapon.
List<WeaponShots> _matchWideShots(Map<String, dynamic> player) {
  final stats = asMap(player['stats']);
  final headshots = asInt(stats['headshots']);
  final bodyshots = asInt(stats['bodyshots']);
  final legshots = asInt(stats['legshots']);
  if (headshots + bodyshots + legshots == 0) return const [];

  return [
    WeaponShots(
      weaponName: 'Toutes armes',
      headshots: headshots,
      bodyshots: bodyshots,
      legshots: legshots,
    ),
  ];
}

/// v2 listed the players of a round under `player_stats`, v4 under `stats`.
List<dynamic> _roundPlayerStats(Map<String, dynamic> round) {
  final legacy = round['player_stats'];
  if (legacy is List<dynamic>) return legacy;
  return asList(round['stats']);
}

/// The match screen is a bonus: a payload it cannot read must never cost the
/// history line itself.
MatchDetail? _detailOf(Map<String, dynamic> json, String puuid) {
  try {
    return MatchDetail.fromJson(json, puuid: puuid);
  } on Object {
    return null;
  }
}
