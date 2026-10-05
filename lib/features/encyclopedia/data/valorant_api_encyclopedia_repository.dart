import '../../../core/network/valorant_api_client.dart';
import '../domain/agent.dart';
import '../domain/competitive_season.dart';
import '../domain/content_tier.dart';
import '../domain/contract.dart';
import '../domain/cosmetic.dart';
import '../domain/game_map.dart';
import '../domain/rank_tier.dart';
import '../domain/store_content.dart';
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
    final weapons = (await getAllWeapons()).where((weapon) => weapon.category != 'Melee').toList();
    weapons.sort((a, b) => a.cost.compareTo(b.cost));
    return weapons;
  }

  @override
  Future<List<Weapon>> getAllWeapons() async {
    final data = await _client.getList('/weapons');
    return [for (final json in data) Weapon.fromJson(json as Map<String, dynamic>)];
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
      actUuid: currentAct['uuid'] as String?,
    );
  }

  @override
  Future<List<Cosmetic>> getCosmetics(CosmeticKind kind) async {
    final data = await _client.getList('/${kind.endpoint}');
    final cosmetics = [
      for (final json in data)
        if (json is Map<String, dynamic>) ?Cosmetic.fromJson(json, kind),
    ];
    cosmetics.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return cosmetics;
  }

  @override
  Future<List<Bundle>> getBundles() async {
    final data = await _client.getList('/bundles');
    final bundles = [
      for (final json in data)
        if (json is Map<String, dynamic> && json['uuid'] is String) Bundle.fromJson(json),
    ].where((bundle) => bundle.displayName.isNotEmpty).toList();
    bundles.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return bundles;
  }

  @override
  Future<List<GameMode>> getGameModes() async {
    final data = await _client.getList('/gamemodes');
    final modes = [
      for (final json in data)
        if (json is Map<String, dynamic> && json['uuid'] is String) GameMode.fromJson(json),
    ].where((mode) => mode.isPlayable).toList();
    modes.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return modes;
  }

  @override
  Future<List<Gear>> getGear() async {
    final data = await _client.getList('/gear');
    final gear = [
      for (final json in data)
        if (json is Map<String, dynamic> && json['uuid'] is String) Gear.fromJson(json),
    ];
    gear.sort((a, b) => a.cost.compareTo(b.cost));
    return gear;
  }

  @override
  Future<List<Contract>> getContracts() async {
    final data = await _client.getList('/contracts');
    return [
      for (final json in data)
        if (json is Map<String, dynamic> && json['uuid'] is String) ?Contract.fromJson(json),
    ];
  }

  @override
  Future<List<Currency>> getCurrencies() async {
    final data = await _client.getList('/currencies');
    return [
      for (final json in data)
        if (json is Map<String, dynamic> && json['uuid'] is String) Currency.fromJson(json),
    ];
  }

  @override
  Future<Map<String, SkinLevelInfo>> getSkinLevels() async {
    final data = await _client.getList('/weapons/skinlevels');
    return {
      for (final json in data)
        if (json is Map<String, dynamic> && json['uuid'] is String) json['uuid'] as String: SkinLevelInfo.fromJson(json),
    };
  }

  @override
  Future<Map<String, DateTime>> getSeasonStarts() async {
    final data = await _client.getList('/seasons');
    return {
      for (final json in data)
        if (json is Map<String, dynamic> && json['uuid'] is String)
          json['uuid'] as String: ?DateTime.tryParse(json['startTime'] as String? ?? ''),
    };
  }
}
