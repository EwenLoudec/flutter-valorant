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
  });

  /// Parses one entry of the HenrikDev match list. Several field names moved
  /// between v2 and v4 of that API, so each read falls back to the other
  /// spelling.
  factory PlayerMatch.fromJson(Map<String, dynamic> json, {required String puuid}) {
    final metadata = _asMap(json['metadata']);
    final player = _findPlayer(json, puuid);
    final stats = _asMap(player['stats']);
    final teamId = (player['team_id'] ?? player['team'])?.toString();
    final rounds = _roundScore(json, teamId);

    return PlayerMatch(
      matchId: (metadata['match_id'] ?? metadata['matchid'] ?? '').toString(),
      mapName: _displayName(metadata['map']),
      mode: _displayName(metadata['queue'] ?? metadata['mode']),
      startedAt: _startedAt(metadata),
      agentName: _displayName(player['agent'] ?? player['character']),
      kills: _asInt(stats['kills']),
      deaths: _asInt(stats['deaths']),
      assists: _asInt(stats['assists']),
      score: _asInt(stats['score']),
      roundsWon: rounds.$1,
      roundsLost: rounds.$2,
      outcome: _outcome(json, teamId, rounds),
      shotsByWeapon: _shotsByWeapon(json, puuid, player),
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

  int get headshots => shotsByWeapon.fold(0, (sum, shots) => sum + shots.headshots);
  int get totalShots => shotsByWeapon.fold(0, (sum, shots) => sum + shots.total);
  double? get headshotPercent => totalShots == 0 ? null : headshots * 100 / totalShots;
  double get killDeathRatio => deaths == 0 ? kills.toDouble() : kills / deaths;
}

Map<String, dynamic> _asMap(Object? value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

List<dynamic> _asList(Object? value) => value is List<dynamic> ? value : const <dynamic>[];

int _asInt(Object? value) => switch (value) {
  final int number => number,
  final num number => number.round(),
  final String text => int.tryParse(text) ?? 0,
  _ => 0,
};

/// Maps, agents and queues come either as `{"id": .., "name": ..}` (v4) or as
/// a bare string (v2).
String _displayName(Object? value) {
  if (value is Map<String, dynamic>) return (value['name'] ?? value['mode_type'] ?? '').toString();
  return value?.toString() ?? '';
}

Map<String, dynamic> _findPlayer(Map<String, dynamic> json, String puuid) {
  final players = json['players'];
  final entries = players is Map<String, dynamic> ? _asList(players['all_players']) : _asList(players);

  for (final entry in entries) {
    final player = _asMap(entry);
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
    return (_asInt(rounds['won']), _asInt(rounds['lost']));
  }
  return (_asInt(team['rounds_won']), _asInt(team['rounds_lost']));
}

Map<String, dynamic> _findTeam(Map<String, dynamic> json, String? teamId) {
  if (teamId == null) return const {};
  final teams = json['teams'];

  if (teams is Map<String, dynamic>) return _asMap(teams[teamId.toLowerCase()]);

  for (final entry in _asList(teams)) {
    final team = _asMap(entry);
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

  for (final roundEntry in _asList(json['rounds'])) {
    for (final statEntry in _asList(_asMap(roundEntry)['player_stats'])) {
      final roundStats = _asMap(statEntry);
      final statPuuid = (roundStats['puuid'] ?? _asMap(roundStats['player'])['puuid'])?.toString();
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
  final economy = _asMap(roundStats['economy']);
  final weapon = roundStats['weapon'] ?? economy['weapon'];
  return _displayName(weapon).trim();
}

/// Head, body and leg shots of one player during one round.
(int, int, int) _roundShots(Map<String, dynamic> roundStats) {
  final stats = _asMap(roundStats['stats']);
  if (stats.containsKey('headshots')) {
    return (_asInt(stats['headshots']), _asInt(stats['bodyshots']), _asInt(stats['legshots']));
  }

  var headshots = 0;
  var bodyshots = 0;
  var legshots = 0;
  for (final eventEntry in _asList(roundStats['damage_events'] ?? roundStats['damage'])) {
    final event = _asMap(eventEntry);
    headshots += _asInt(event['headshots']);
    bodyshots += _asInt(event['bodyshots']);
    legshots += _asInt(event['legshots']);
  }
  return (headshots, bodyshots, legshots);
}

/// Fallback when a match carries no round detail: the totals the API reports
/// for the whole match, which are not split per weapon.
List<WeaponShots> _matchWideShots(Map<String, dynamic> player) {
  final stats = _asMap(player['stats']);
  final headshots = _asInt(stats['headshots']);
  final bodyshots = _asInt(stats['bodyshots']);
  final legshots = _asInt(stats['legshots']);
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
