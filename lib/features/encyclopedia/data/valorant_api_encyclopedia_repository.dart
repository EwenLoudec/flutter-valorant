import '../../../core/network/valorant_api_client.dart';
import '../domain/agent.dart';
import '../domain/competitive_season.dart';
import '../domain/content_tier.dart';
import '../domain/game_map.dart';
import '../domain/rank_tier.dart';
import '../domain/weapon.dart';
import '../domain/weapon_skin.dart';
import 'encyclopedia_repository.dart';

class ValorantApiEncyclopediaRepository implements EncyclopediaRepository {
  ValorantApiEncyclopediaRepository({ValorantApiClient? client}) : _client = client ?? ValorantApiClient();

  final ValorantApiClient _client;

  @override
  Future<List<Agent>> getAgents() async {
    final data = await _client.getList('/agents', query: {'isPlayableCharacter': 'true'});
    final agents = data.map((json) => Agent.fromJson(json as Map<String, dynamic>)).toList();
    agents.sort((a, b) => a.displayName.compareTo(b.displayName));
    return agents;
  }

  @override
  Future<List<Weapon>> getWeapons() async {
    final data = await _client.getList('/weapons');
    final weapons = data
        .map((json) => Weapon.fromJson(json as Map<String, dynamic>))
        .where((weapon) => weapon.category != 'Melee')
        .toList();
    weapons.sort((a, b) => a.cost.compareTo(b.cost));
    return weapons;
  }

  @override
  Future<List<WeaponSkin>> getWeaponSkins(String weaponUuid) async {
    final data = await _client.getOne('/weapons/$weaponUuid');
    return (data['skins'] as List<dynamic>? ?? [])
        .map((s) => WeaponSkin.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, ContentTier>> getContentTiers() async {
    final data = await _client.getList('/contenttiers');
    final tiers = data.map((json) => ContentTier.fromJson(json as Map<String, dynamic>));
    return {for (final tier in tiers) tier.uuid: tier};
  }

  @override
  Future<List<GameMap>> getMaps() async {
    final data = await _client.getList('/maps');
    final maps = data
        .map((json) => GameMap.fromJson(json as Map<String, dynamic>))
        // Deathmatch arenas and the practice range also come back from this
        // endpoint; real competitive maps are the only ones with site info.
        .where((map) => map.tacticalDescription != null)
        .toList();
    maps.sort((a, b) => a.displayName.compareTo(b.displayName));
    return maps;
  }

  @override
  Future<List<RankTier>> getRankTiers() async {
    final data = await _client.getList('/competitivetiers');
    // The last entry in the list is always the current, active episode's tier set.
    final currentEpisode = data.last as Map<String, dynamic>;
    final tiers = (currentEpisode['tiers'] as List<dynamic>)
        .map((json) => RankTier.fromJson(json as Map<String, dynamic>))
        // Tiers 0-2 are "Unranked" and two unused placeholder slots.
        .where((tier) => tier.tier >= 3)
        .toList();
    tiers.sort((a, b) => a.tier.compareTo(b.tier));
    return tiers;
  }

  @override
  Future<CompetitiveSeason?> getCurrentSeason() async {
    final data = await _client.getList('/seasons');
    final now = DateTime.now().toUtc();
    final seasons = data.cast<Map<String, dynamic>>();

    Map<String, dynamic>? currentAct;
    for (final season in seasons) {
      if (season['type'] != 'EAresSeasonType::Act') continue;
      final start = DateTime.tryParse(season['startTime'] as String? ?? '');
      final end = DateTime.tryParse(season['endTime'] as String? ?? '');
      if (start == null || end == null) continue;
      if (now.isAfter(start) && now.isBefore(end)) {
        currentAct = season;
        break;
      }
    }
    if (currentAct == null) return null;

    final parentUuid = currentAct['parentUuid'] as String?;
    Map<String, dynamic>? parent;
    for (final season in seasons) {
      if (season['uuid'] == parentUuid) {
        parent = season;
        break;
      }
    }

    return CompetitiveSeason(
      episodeName: parent?['displayName'] as String? ?? '',
      actName: currentAct['displayName'] as String? ?? '',
    );
  }
}
