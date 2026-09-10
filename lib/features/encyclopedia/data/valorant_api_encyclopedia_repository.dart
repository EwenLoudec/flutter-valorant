import '../../../core/network/valorant_api_client.dart';
import '../domain/agent.dart';
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
}
