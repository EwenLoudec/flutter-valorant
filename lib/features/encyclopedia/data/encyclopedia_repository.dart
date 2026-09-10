import '../domain/agent.dart';
import '../domain/content_tier.dart';
import '../domain/weapon.dart';
import '../domain/weapon_skin.dart';

abstract class EncyclopediaRepository {
  Future<List<Agent>> getAgents();
  Future<List<Weapon>> getWeapons();
  Future<List<WeaponSkin>> getWeaponSkins(String weaponUuid);
  Future<Map<String, ContentTier>> getContentTiers();
}
