import '../../../core/network/valorant_api_client.dart';
import '../domain/agent.dart';
import '../domain/content_tier.dart';
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
}
