import 'player_match.dart';
import 'player_stats_summary.dart';

/// Wins, kills and deaths of one role (duelist, initiator…).
class RoleStats {
  const RoleStats({
    required this.role,
    required this.record,
    required this.kills,
    required this.deaths,
    required this.assists,
  });

  final String role;
  final WinRecord record;
  final int kills;
  final int deaths;
  final int assists;

  /// (Kills + assists) / deaths, as trackers show it.
  double get kda => deaths == 0 ? (kills + assists).toDouble() : (kills + assists) / deaths;
}

/// Kills and shot spread of one weapon.
class WeaponStats {
  const WeaponStats({
    required this.weaponName,
    required this.weaponId,
    required this.kills,
    required this.headshots,
    required this.bodyshots,
    required this.legshots,
  });

  final String weaponName;

  /// valorant-api.com uuid, lower-cased, to show the weapon's picture.
  final String? weaponId;
  final int kills;
  final int headshots;
  final int bodyshots;
  final int legshots;

  int get shots => headshots + bodyshots + legshots;
  double? get headshotPercent => shots == 0 ? null : headshots * 100 / shots;
  double? get bodyshotPercent => shots == 0 ? null : bodyshots * 100 / shots;
  double? get legshotPercent => shots == 0 ? null : legshots * 100 / shots;
}

/// One agent's line of the "top agents" table.
class AgentOverview {
  const AgentOverview({
    required this.agentName,
    required this.record,
    required this.kills,
    required this.deaths,
    required this.score,
    required this.damage,
    required this.rounds,
    required this.bestMapName,
    required this.bestMapWinRate,
  });

  final String agentName;
  final WinRecord record;
  final int kills;
  final int deaths;
  final int score;
  final int damage;
  final int rounds;
  final String? bestMapName;
  final double? bestMapWinRate;

  int get games => record.played;
  double get killDeathRatio => deaths == 0 ? kills.toDouble() : kills / deaths;
  double? get averageCombatScore => rounds == 0 ? null : score / rounds;
  double? get averageDamage => rounds == 0 || damage == 0 ? null : damage / rounds;
}

/// The tracker-style overview of the loaded round-based games: the headline
/// figures, then roles, weapons and agents. Everything comes from the match
/// payloads already loaded.
class CareerOverview {
  const CareerOverview({
    required this.matchCount,
    required this.record,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.score,
    required this.damage,
    required this.rounds,
    required this.headshots,
    required this.bodyshots,
    required this.legshots,
    required this.highlightRounds,
    required this.kastRounds,
    required this.firstBloods,
    required this.aces,
    required this.flawlessRounds,
    required this.roles,
    required this.weapons,
    required this.agents,
  });

  /// [roleOfAgent] maps an agent name (lower case) to its role; agents it
  /// does not know are grouped under no role.
  factory CareerOverview.from(
    List<PlayerMatch> matches, {
    required String puuid,
    Map<String, String> roleOfAgent = const {},
  }) {
    final games = [
      for (final match in matches)
        if (match.isRoundBased) match,
    ];

    var record = const WinRecord();
    var kills = 0, deaths = 0, assists = 0, score = 0, damage = 0, rounds = 0;
    var headshots = 0, bodyshots = 0, legshots = 0;
    var highlightRounds = 0, kastRounds = 0, firstBloods = 0, aces = 0, flawless = 0;

    final roles = <String, RoleStats>{};
    final weaponKills = <String, ({String name, String? id, int kills})>{};
    final weaponShots = <String, ({String name, int head, int body, int leg})>{};
    final agentLines = <String, _AgentAccumulator>{};

    for (final match in games) {
      record = record.add(match.outcome);
      final matchRounds = match.roundsWon + match.roundsLost;
      final detail = match.detail;
      final self = detail?.players.where((player) => player.puuid == puuid).firstOrNull;
      final matchDamage = self?.damageDealt ?? 0;

      kills += match.kills;
      deaths += match.deaths;
      assists += match.assists;
      score += match.score;
      damage += matchDamage;
      rounds += matchRounds;

      for (final shots in match.shotsByWeapon) {
        headshots += shots.headshots;
        bodyshots += shots.bodyshots;
        legshots += shots.legshots;
        final key = shots.weaponName.toLowerCase();
        final current = weaponShots[key];
        weaponShots[key] = (
          name: shots.weaponName,
          head: (current?.head ?? 0) + shots.headshots,
          body: (current?.body ?? 0) + shots.bodyshots,
          leg: (current?.leg ?? 0) + shots.legshots,
        );
      }

      final highlights = detail?.highlightsOf(puuid);
      if (highlights != null) {
        highlightRounds += highlights.rounds;
        kastRounds += highlights.kastRounds;
        firstBloods += highlights.firstBloods;
        aces += highlights.aces;
        flawless += highlights.flawlessRounds;
        for (final weapon in highlights.weaponKills) {
          final key = weapon.weaponName.toLowerCase();
          if (key.isEmpty) continue;
          final current = weaponKills[key];
          weaponKills[key] = (
            name: weapon.weaponName,
            id: weapon.weaponId ?? current?.id,
            kills: (current?.kills ?? 0) + weapon.kills,
          );
        }
      }

      final role = roleOfAgent[match.agentName.toLowerCase()];
      if (role != null) {
        final current = roles[role];
        roles[role] = RoleStats(
          role: role,
          record: (current?.record ?? const WinRecord()).add(match.outcome),
          kills: (current?.kills ?? 0) + match.kills,
          deaths: (current?.deaths ?? 0) + match.deaths,
          assists: (current?.assists ?? 0) + match.assists,
        );
      }

      if (match.agentName.isNotEmpty) {
        agentLines.putIfAbsent(match.agentName, _AgentAccumulator.new).add(match, matchDamage, matchRounds);
      }
    }

    final weapons =
        [
            for (final key in {...weaponKills.keys, ...weaponShots.keys})
              WeaponStats(
                weaponName: weaponKills[key]?.name ?? weaponShots[key]!.name,
                weaponId: weaponKills[key]?.id,
                kills: weaponKills[key]?.kills ?? 0,
                headshots: weaponShots[key]?.head ?? 0,
                bodyshots: weaponShots[key]?.body ?? 0,
                legshots: weaponShots[key]?.leg ?? 0,
              ),
          ]
          // The match-wide fallback line is not a weapon.
          ..removeWhere((weapon) => weapon.weaponName == 'Toutes armes')
          ..sort((a, b) {
            final byKills = b.kills.compareTo(a.kills);
            return byKills != 0 ? byKills : b.shots.compareTo(a.shots);
          });

    final agents = [for (final entry in agentLines.entries) entry.value.build(entry.key)]
      ..sort((a, b) {
        final byGames = b.games.compareTo(a.games);
        return byGames != 0 ? byGames : b.kills.compareTo(a.kills);
      });

    final roleList = roles.values.toList()..sort((a, b) => b.record.played.compareTo(a.record.played));

    return CareerOverview(
      matchCount: games.length,
      record: record,
      kills: kills,
      deaths: deaths,
      assists: assists,
      score: score,
      damage: damage,
      rounds: rounds,
      headshots: headshots,
      bodyshots: bodyshots,
      legshots: legshots,
      highlightRounds: highlightRounds,
      kastRounds: kastRounds,
      firstBloods: firstBloods,
      aces: aces,
      flawlessRounds: flawless,
      roles: roleList,
      weapons: weapons,
      agents: agents,
    );
  }

  final int matchCount;
  final WinRecord record;
  final int kills;
  final int deaths;
  final int assists;
  final int score;
  final int damage;
  final int rounds;
  final int headshots;
  final int bodyshots;
  final int legshots;

  /// Rounds whose kill feed was available, the base of KAST.
  final int highlightRounds;
  final int kastRounds;
  final int firstBloods;
  final int aces;
  final int flawlessRounds;
  final List<RoleStats> roles;
  final List<WeaponStats> weapons;
  final List<AgentOverview> agents;

  bool get isEmpty => matchCount == 0;

  double get killDeathRatio => deaths == 0 ? kills.toDouble() : kills / deaths;
  double get kadRatio => deaths == 0 ? (kills + assists).toDouble() : (kills + assists) / deaths;
  double? get averageCombatScore => rounds == 0 ? null : score / rounds;
  double? get averageDamage => rounds == 0 || damage == 0 ? null : damage / rounds;
  double? get killsPerRound => rounds == 0 ? null : kills / rounds;
  double? get winRate => record.winRate;

  int get shots => headshots + bodyshots + legshots;
  double? get headshotPercent => shots == 0 ? null : headshots * 100 / shots;
  double? get kastPercent => highlightRounds == 0 ? null : kastRounds * 100 / highlightRounds;
}

class _AgentAccumulator {
  var record = const WinRecord();
  var kills = 0;
  var deaths = 0;
  var score = 0;
  var damage = 0;
  var rounds = 0;
  final maps = <String, WinRecord>{};

  void add(PlayerMatch match, int matchDamage, int matchRounds) {
    record = record.add(match.outcome);
    kills += match.kills;
    deaths += match.deaths;
    score += match.score;
    damage += matchDamage;
    rounds += matchRounds;
    if (match.mapName.isNotEmpty && match.outcome != null) {
      maps[match.mapName] = (maps[match.mapName] ?? const WinRecord()).add(match.outcome);
    }
  }

  AgentOverview build(String agentName) {
    MapEntry<String, WinRecord>? best;
    for (final entry in maps.entries) {
      final rate = entry.value.winRate ?? 0;
      final bestRate = best?.value.winRate ?? -1;
      if (rate > bestRate || (rate == bestRate && entry.value.played > (best?.value.played ?? 0))) best = entry;
    }

    return AgentOverview(
      agentName: agentName,
      record: record,
      kills: kills,
      deaths: deaths,
      score: score,
      damage: damage,
      rounds: rounds,
      bestMapName: best?.key,
      bestMapWinRate: best?.value.winRate,
    );
  }
}
