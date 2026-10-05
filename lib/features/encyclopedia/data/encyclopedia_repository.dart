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

abstract class EncyclopediaRepository {
  Future<List<Agent>> getAgents();
  Future<List<Weapon>> getWeapons();
  Future<List<WeaponSkin>> getWeaponSkins(String weaponUuid);
  Future<Map<String, ContentTier>> getContentTiers();
  Future<List<GameMap>> getMaps();
  Future<List<RankTier>> getRankTiers();
  Future<CompetitiveSeason?> getCurrentSeason();
  Future<List<Cosmetic>> getCosmetics(CosmeticKind kind);
  Future<List<Bundle>> getBundles();
  Future<List<GameMode>> getGameModes();
  Future<List<Gear>> getGear();
  Future<List<Contract>> getContracts();
  Future<List<Currency>> getCurrencies();
  Future<Map<String, SkinLevelInfo>> getSkinLevels();

  /// Season uuid -> start date, to order the battle passes.
  Future<Map<String, DateTime>> getSeasonStarts();
}
