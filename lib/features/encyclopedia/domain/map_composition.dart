class CompositionAgent {
  const CompositionAgent(this.agentName, this.role);

  final String agentName;
  final String role;
}

class MapComposition {
  const MapComposition({required this.winRatePercent, required this.agents});

  final double winRatePercent;
  final List<CompositionAgent> agents;
}
