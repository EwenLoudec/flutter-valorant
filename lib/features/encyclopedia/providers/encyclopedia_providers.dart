import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/ability_video_repository.dart';
import '../data/encyclopedia_repository.dart';
import '../data/valorant_api_encyclopedia_repository.dart';
import '../domain/agent.dart';

final encyclopediaRepositoryProvider = Provider<EncyclopediaRepository>((ref) {
  return ValorantApiEncyclopediaRepository();
});

final agentsProvider = FutureProvider<List<Agent>>((ref) {
  return ref.watch(encyclopediaRepositoryProvider).getAgents();
});

/// null means "all roles".
final agentRoleFilterProvider = StateProvider<String?>((ref) => null);

final abilityVideoRepositoryProvider = Provider<AbilityVideoRepository>((ref) {
  return AbilityVideoRepository();
});

/// Agent uuid -> ability name (French, upper case) -> mp4 preview clip url.
final abilityVideosProvider = FutureProvider<Map<String, Map<String, String>>>((ref) {
  return ref.watch(abilityVideoRepositoryProvider).getVideosByAgent();
});
