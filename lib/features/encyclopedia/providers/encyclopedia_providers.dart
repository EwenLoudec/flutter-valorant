import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/ability_video_repository.dart';
import '../data/encyclopedia_repository.dart';
import '../data/valorant_api_encyclopedia_repository.dart';
import '../domain/agent.dart';
import '../domain/content_tier.dart';
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
