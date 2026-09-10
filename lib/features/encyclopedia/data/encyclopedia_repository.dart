import '../domain/agent.dart';

abstract class EncyclopediaRepository {
  Future<List<Agent>> getAgents();
}
