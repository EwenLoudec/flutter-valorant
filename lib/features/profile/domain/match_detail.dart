import 'json_reading.dart';

/// How a team spent its credits on one round, read from the average value of
/// the loadouts it carried. The thresholds are an estimate: Riot publishes no
/// official buy classification.
enum BuyType {
  pistol('Pistolets'),
  eco('Éco'),
  force('Force buy'),
  full('Full buy');

  const BuyType(this.label);

  final String label;

  /// Below this average loadout a team is saving.
  static const ecoBelow = 1500;

  /// A rifle with heavy shields costs 3 900 credits.
  static const fullFrom = 3900;

  static BuyType fromAverageLoadout(double average) {
    if (average < ecoBelow) return BuyType.eco;
    if (average < fullFrom) return BuyType.force;
    return BuyType.full;
  }
}

/// Which half of the round a team is playing.
enum RoundSide {
  attack('Attaque'),
  defense('Défense');

  const RoundSide(this.label);

  final String label;
}

/// One of the ten players of a match, with their whole scoreboard line.
class MatchPlayer {
  const MatchPlayer({
    required this.puuid,
    required this.name,
    required this.tag,
    required this.teamId,
    required this.agentName,
    required this.agentId,
    required this.tierId,
    required this.tierName,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.score,
    required this.headshots,
    required this.bodyshots,
    required this.legshots,
    required this.damageDealt,
  });

  factory MatchPlayer.fromJson(Map<String, dynamic> json) {
    final stats = asMap(json['stats']);
    final damage = stats['damage'];
    final tier = json['tier'] ?? json['currenttier'];

    return MatchPlayer(
      puuid: json['puuid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      tag: json['tag']?.toString() ?? '',
      teamId: (json['team_id'] ?? json['team'])?.toString() ?? '',
      agentName: displayNameOf(json['agent'] ?? json['character']),
      agentId: idOf(json['agent']),
      tierId: tier is Map<String, dynamic> ? asInt(tier['id']) : asInt(tier),
      tierName: tier is Map<String, dynamic>
          ? tier['name']?.toString() ?? ''
          : json['currenttier_patched']?.toString() ?? '',
      kills: asInt(stats['kills']),
      deaths: asInt(stats['deaths']),
      assists: asInt(stats['assists']),
      score: asInt(stats['score']),
      headshots: asInt(stats['headshots']),
      bodyshots: asInt(stats['bodyshots']),
      legshots: asInt(stats['legshots']),
      damageDealt: damage is Map<String, dynamic> ? asInt(damage['dealt']) : asInt(json['damage_made']),
    );
  }

  final String puuid;
  final String name;
  final String tag;
  final String teamId;
  final String agentName;
  final String? agentId;
  final int tierId;
  final String tierName;
  final int kills;
  final int deaths;
  final int assists;
  final int score;
  final int headshots;
  final int bodyshots;
  final int legshots;
  final int damageDealt;

  String get label => tag.isEmpty ? name : '$name#$tag';

  int get totalShots => headshots + bodyshots + legshots;
  double? get headshotPercent => totalShots == 0 ? null : headshots * 100 / totalShots;

  /// Average combat score: the in-game scoreboard divides the score by the
  /// number of rounds played.
  double averageCombatScore(int rounds) => rounds == 0 ? 0 : score / rounds;
  double averageDamage(int rounds) => rounds == 0 ? 0 : damageDealt / rounds;
}

/// One round: who took it, how, and what both teams had bought.
class MatchRound {
  const MatchRound({
    required this.index,
    required this.winningTeam,
    required this.result,
    required this.plantSite,
    required this.planterTeam,
    required this.isDefused,
    required this.averageLoadoutByTeam,
  });

  factory MatchRound.fromJson(Map<String, dynamic> json, int index, Map<String, String> teamOf) {
    final plant = asMap(json['plant'] ?? json['plant_events']);
    final defuse = asMap(json['defuse'] ?? json['defuse_events']);

    final planter = asMap(plant['player'] ?? plant['planted_by']);
    final planterPuuid = planter['puuid']?.toString();
    final planterTeam = asStringOrNull(planter['team']) ?? (planterPuuid == null ? null : teamOf[planterPuuid]);

    final totals = <String, int>{};
    final counts = <String, int>{};
    for (final entry in asList(json['stats'] ?? json['player_stats'])) {
      final stats = asMap(entry);
      final player = asMap(stats['player']);
      final puuid = (stats['puuid'] ?? player['puuid'])?.toString();
      final team = asStringOrNull(player['team']) ?? asStringOrNull(stats['player_team']) ?? teamOf[puuid];
      if (team == null) continue;

      final economy = asMap(stats['economy']);
      totals[team] = (totals[team] ?? 0) + asInt(economy['loadout_value']);
      counts[team] = (counts[team] ?? 0) + 1;
    }

    return MatchRound(
      index: index,
      winningTeam: (json['winning_team'] ?? '').toString(),
      result: (json['result'] ?? json['end_type'] ?? '').toString(),
      plantSite: asStringOrNull(plant['site'] ?? plant['plant_site']),
      planterTeam: planterTeam,
      isDefused: defuse.isNotEmpty,
      averageLoadoutByTeam: {
        for (final team in totals.keys) team: totals[team]! / counts[team]!,
      },
    );
  }

  final int index;
  final String winningTeam;

  /// Riot's own wording, e.g. `Elimination` or `Bomb defused`.
  final String result;
  final String? plantSite;
  final String? planterTeam;
  final bool isDefused;

  /// Team id -> average loadout value of its players at the start of the round.
  final Map<String, double> averageLoadoutByTeam;

  int get number => index + 1;
  bool get isPlanted => plantSite != null || planterTeam != null;

  bool isWonBy(String teamId) => winningTeam.toLowerCase() == teamId.toLowerCase();

  double? averageLoadoutOf(String teamId) {
    for (final entry in averageLoadoutByTeam.entries) {
      if (entry.key.toLowerCase() == teamId.toLowerCase()) return entry.value;
    }
    return null;
  }

  /// The API spells the same endings several ways (`Defuse`, `Bomb defused`…),
  /// so they are recognised by their stem.
  RoundEnd get end {
    final value = result.toLowerCase();
    if (value.contains('defus')) return RoundEnd.defused;
    if (value.contains('deton') || value.contains('explod')) return RoundEnd.detonated;
    if (value.contains('time')) return RoundEnd.timeExpired;
    if (value.contains('surrender')) return RoundEnd.surrendered;
    if (value.contains('elimin')) return RoundEnd.elimination;
    return RoundEnd.other;
  }

  String get resultLabel => switch (end) {
    RoundEnd.other => result.isEmpty ? '—' : result,
    final known => known.label,
  };
}

/// How a round ended.
enum RoundEnd {
  elimination('Élimination'),
  detonated('Spike explosé'),
  defused('Spike désamorcé'),
  timeExpired('Temps écoulé'),
  surrendered('Abandon'),
  other('');

  const RoundEnd(this.label);

  final String label;
}

/// A kill, where it happened on the map and with what.
class MatchKill {
  const MatchKill({
    required this.round,
    required this.timeInRoundMs,
    required this.killerPuuid,
    required this.killerName,
    required this.victimPuuid,
    required this.victimName,
    required this.weaponName,
    required this.victimX,
    required this.victimY,
  });

  factory MatchKill.fromJson(Map<String, dynamic> json) {
    final killer = asMap(json['killer']);
    final victim = asMap(json['victim']);
    final location = asMap(json['location'] ?? json['victim_death_location']);

    return MatchKill(
      round: asInt(json['round']),
      timeInRoundMs: asInt(json['time_in_round_in_ms'] ?? json['kill_time_in_round']),
      killerPuuid: (killer['puuid'] ?? json['killer_puuid'])?.toString() ?? '',
      killerName: (killer['name'] ?? json['killer_display_name'])?.toString() ?? '',
      victimPuuid: (victim['puuid'] ?? json['victim_puuid'])?.toString() ?? '',
      victimName: (victim['name'] ?? json['victim_display_name'])?.toString() ?? '',
      weaponName: displayNameOf(json['weapon'] ?? json['damage_weapon_name']),
      victimX: asDoubleOrNull(location['x']),
      victimY: asDoubleOrNull(location['y']),
    );
  }

  final int round;
  final int timeInRoundMs;
  final String killerPuuid;
  final String killerName;
  final String victimPuuid;
  final String victimName;
  final String weaponName;

  /// Where the victim fell, in game coordinates.
  final double? victimX;
  final double? victimY;

  bool get hasLocation => victimX != null && victimY != null;
}

/// Everything a match payload says beyond the player's own line: the full
/// scoreboard, the rounds and the kills. Built from the very same response as
/// the match history, so opening a match costs no request.
class MatchDetail {
  const MatchDetail({
    required this.mapId,
    required this.queueId,
    required this.gameLength,
    required this.playerTeamId,
    required this.players,
    required this.rounds,
    required this.kills,
  });

  /// Rounds per half of the modes that play two halves. Other modes are not
  /// split into attack and defense.
  static const _roundsPerHalf = {'competitive': 12, 'unrated': 12, 'premier': 12, 'swiftplay': 4, 'spikerush': 3};

  factory MatchDetail.fromJson(Map<String, dynamic> json, {required String puuid}) {
    final metadata = asMap(json['metadata']);
    final playersJson = json['players'];
    final entries = playersJson is Map<String, dynamic> ? asList(playersJson['all_players']) : asList(playersJson);
    final players = [for (final entry in entries) MatchPlayer.fromJson(asMap(entry))];
    final teamOf = {for (final player in players) player.puuid: player.teamId};

    final roundsJson = asList(json['rounds']);
    final queue = metadata['queue'];
    final lengthMs = asInt(metadata['game_length_in_ms'] ?? metadata['game_length']);

    return MatchDetail(
      mapId: idOf(metadata['map']) ?? asStringOrNull(metadata['map_id']),
      queueId: (idOf(queue) ?? metadata['mode_id'] ?? metadata['queue'] ?? '').toString().toLowerCase(),
      // v2 reported seconds, v4 milliseconds.
      gameLength: Duration(milliseconds: lengthMs > 0 && lengthMs < 20000 ? lengthMs * 1000 : lengthMs),
      playerTeamId: teamOf[puuid],
      players: players,
      rounds: [for (final (index, round) in roundsJson.indexed) MatchRound.fromJson(asMap(round), index, teamOf)],
      kills: [for (final kill in asList(json['kills'])) MatchKill.fromJson(asMap(kill))],
    );
  }

  /// valorant-api.com uuid of the map, when the payload carries it.
  final String? mapId;
  final String queueId;
  final Duration gameLength;
  final String? playerTeamId;
  final List<MatchPlayer> players;
  final List<MatchRound> rounds;
  final List<MatchKill> kills;

  int get roundCount => rounds.length;

  /// Deathmatch and team deathmatch come back as a single round: there is
  /// no timeline, buy or side to show, and ACS / ADR would mean nothing.
  bool get isRoundBased => rounds.length > 1;

  /// Deathmatch puts every player in a team of their own.
  bool get isFreeForAll => players.length > 2 && teamIds.length == players.length;

  /// Everyone, best score first — the scoreboard of a free-for-all.
  List<MatchPlayer> get playersByScore => [...players]..sort((a, b) => b.score.compareTo(a.score));

  /// The other team of a two-team match.
  String? get enemyTeamId {
    final own = playerTeamId;
    if (own == null) return null;
    for (final player in players) {
      if (player.teamId.toLowerCase() != own.toLowerCase()) return player.teamId;
    }
    return null;
  }

  /// One team's players, best score first.
  List<MatchPlayer> playersOf(String teamId) {
    return [
      for (final player in players)
        if (player.teamId.toLowerCase() == teamId.toLowerCase()) player,
    ]..sort((a, b) => b.score.compareTo(a.score));
  }

  /// The teams that took part, the player's own first.
  List<String> get teamIds {
    final ids = <String>[];
    for (final player in players) {
      if (!ids.any((id) => id.toLowerCase() == player.teamId.toLowerCase())) ids.add(player.teamId);
    }
    final own = playerTeamId;
    if (own != null) ids.sort((a, b) => (b == own ? 1 : 0).compareTo(a == own ? 1 : 0));
    return ids;
  }

  int? get _halfLength => _roundsPerHalf[queueId];

  /// The team on attack during [roundIndex], or null when the mode does not
  /// split into halves. A plant proves who attacked; without one, the half
  /// takes the side the plants of the other half imply, then Riot's rule
  /// that the red team attacks first.
  String? attackingTeam(int roundIndex) {
    final round = roundIndex < rounds.length ? rounds[roundIndex] : null;
    final planter = round?.planterTeam;
    if (planter != null) return planter;

    final half = _halfLength;
    if (half == null) return null;

    final regulation = half * 2;
    final bool isFirstHalfSide;
    if (roundIndex < half) {
      isFirstHalfSide = true;
    } else if (roundIndex < regulation) {
      isFirstHalfSide = false;
    } else if (half == 12) {
      // Overtime swaps sides every round, starting from the first half's.
      isFirstHalfSide = (roundIndex - regulation).isEven;
    } else {
      return null;
    }

    final firstHalfAttacker = _firstHalfAttacker(half);
    if (firstHalfAttacker == null) return null;
    return isFirstHalfSide ? firstHalfAttacker : _otherTeam(firstHalfAttacker);
  }

  String? _firstHalfAttacker(int half) {
    for (final round in rounds) {
      final planter = round.planterTeam;
      if (planter == null) continue;
      if (round.index < half) return planter;
      if (round.index < half * 2) return _otherTeam(planter);
    }
    return teamIds.firstWhere((id) => id.toLowerCase() == 'red', orElse: () => '').nullIfEmpty;
  }

  String? _otherTeam(String teamId) {
    for (final id in teamIds) {
      if (id.toLowerCase() != teamId.toLowerCase()) return id;
    }
    return null;
  }

  /// Which side the player's team was on during [roundIndex].
  RoundSide? playerSide(int roundIndex) {
    final own = playerTeamId;
    final attacker = attackingTeam(roundIndex);
    if (own == null || attacker == null) return null;
    return attacker.toLowerCase() == own.toLowerCase() ? RoundSide.attack : RoundSide.defense;
  }

  /// Pistol rounds open each half; elsewhere the loadouts tell the buy.
  BuyType? buyOf(String teamId, int roundIndex) {
    final half = _halfLength;
    if (half != null && (roundIndex == 0 || roundIndex == half)) return BuyType.pistol;

    final round = roundIndex < rounds.length ? rounds[roundIndex] : null;
    final average = round?.averageLoadoutOf(teamId);
    if (average == null) return null;
    return BuyType.fromAverageLoadout(average);
  }
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
