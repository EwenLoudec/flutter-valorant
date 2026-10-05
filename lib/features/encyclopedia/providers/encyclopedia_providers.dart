import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/ability_video_repository.dart';
import '../data/encyclopedia_repository.dart';
import '../data/valorant_api_encyclopedia_repository.dart';
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

final encyclopediaRepositoryProvider = Provider<EncyclopediaRepository>((ref) {
  return ValorantApiEncyclopediaRepository();
});

final agentsProvider = FutureProvider<List<Agent>>((ref) {
  return ref.watch(encyclopediaRepositoryProvider).getAgents();
});

/// null means "all roles".
final agentRoleFilterProvider = StateProvider<String?>((ref) => null);

final weaponsProvider = FutureProvider<List<Weapon>>((ref) {
  return ref.watch(encyclopediaRepositoryProvider).getWeapons();
});

final contentTiersProvider = FutureProvider<Map<String, ContentTier>>((ref) {
  return ref.watch(encyclopediaRepositoryProvider).getContentTiers();
});

/// Fetched lazily per weapon — only when its detail screen is opened, since
/// full skin data for every weapon at once is several MB.
final weaponSkinsProvider = FutureProvider.family<List<WeaponSkin>, String>((ref, weaponUuid) {
  return ref.watch(encyclopediaRepositoryProvider).getWeaponSkins(weaponUuid);
});

/// null means "all categories".
final weaponCategoryFilterProvider = StateProvider<String?>((ref) => null);

final abilityVideoRepositoryProvider = Provider<AbilityVideoRepository>((ref) {
  return AbilityVideoRepository();
});

/// Agent uuid -> ability name (French, upper case) -> mp4 preview clip url.
final abilityVideosProvider = FutureProvider<Map<String, Map<String, String>>>((ref) {
  return ref.watch(abilityVideoRepositoryProvider).getVideosByAgent();
});

final mapsProvider = FutureProvider<List<GameMap>>((ref) {
  return ref.watch(encyclopediaRepositoryProvider).getMaps();
});

final rankTiersProvider = FutureProvider<List<RankTier>>((ref) {
  return ref.watch(encyclopediaRepositoryProvider).getRankTiers();
});

final currentSeasonProvider = FutureProvider<CompetitiveSeason?>((ref) {
  return ref.watch(encyclopediaRepositoryProvider).getCurrentSeason();
});

/// Player cards, sprays, buddies or titles — each list is fetched only when
/// its tab is opened.
final cosmeticsProvider = FutureProvider.family<List<Cosmetic>, CosmeticKind>((ref, kind) {
  return ref.watch(encyclopediaRepositoryProvider).getCosmetics(kind);
});

final bundlesProvider = FutureProvider<List<Bundle>>((ref) {
  return ref.watch(encyclopediaRepositoryProvider).getBundles();
});

final gameModesProvider = FutureProvider<List<GameMode>>((ref) {
  return ref.watch(encyclopediaRepositoryProvider).getGameModes();
});

/// The shields of the buy menu, cheapest first.
final gearProvider = FutureProvider<List<Gear>>((ref) {
  return ref.watch(encyclopediaRepositoryProvider).getGear();
});

final contractsProvider = FutureProvider<List<Contract>>((ref) {
  return ref.watch(encyclopediaRepositoryProvider).getContracts();
});

final currenciesProvider = FutureProvider<List<Currency>>((ref) {
  return ref.watch(encyclopediaRepositoryProvider).getCurrencies();
});

/// Every weapon skin level, to name the skins contracts reward.
final skinLevelsProvider = FutureProvider<Map<String, SkinLevelInfo>>((ref) {
  return ref.watch(encyclopediaRepositoryProvider).getSkinLevels();
});

final seasonStartsProvider = FutureProvider<Map<String, DateTime>>((ref) {
  return ref.watch(encyclopediaRepositoryProvider).getSeasonStarts();
});
