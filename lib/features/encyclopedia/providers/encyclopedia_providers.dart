import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/encyclopedia_repository.dart';
import '../data/valorant_api_encyclopedia_repository.dart';
import '../domain/agent.dart';

final encyclopediaRepositoryProvider = Provider<EncyclopediaRepository>((ref) {
  return ValorantApiEncyclopediaRepository();
});

final agentsProvider = FutureProvider<List<Agent>>((ref) {
  return ref.watch(encyclopediaRepositoryProvider).getAgents();
});
