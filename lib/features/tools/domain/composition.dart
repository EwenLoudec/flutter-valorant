import '../../encyclopedia/domain/agent.dart';
import '../../encyclopedia/domain/map_composition.dart';

/// The four roles, as valorant-api.com names them in French.
abstract final class AgentRoles {
  static const duelist = 'Duelliste';
  static const initiator = 'Initiateur';
  static const controller = 'Contrôleur';
  static const sentinel = 'Sentinelle';

  static const all = [duelist, initiator, controller, sentinel];
}

enum CompositionIssueLevel { warning, info }

class CompositionIssue {
  const CompositionIssue(this.level, this.message);

  final CompositionIssueLevel level;
  final String message;
}

/// What a five-agent line-up covers, what it lacks, and how close it is to
/// the meta composition of the map.
class CompositionAnalysis {
  const CompositionAnalysis({
    required this.agents,
    required this.roleCounts,
    required this.issues,
    required this.metaMatches,
    required this.metaSize,
  });

  static const teamSize = 5;

  factory CompositionAnalysis.of(List<Agent> agents, {MapComposition? meta}) {
    final counts = {for (final role in AgentRoles.all) role: 0};
    for (final agent in agents) {
      if (counts.containsKey(agent.roleName)) counts[agent.roleName] = counts[agent.roleName]! + 1;
    }

    final issues = <CompositionIssue>[];
    if (agents.length < teamSize) {
      issues.add(
        CompositionIssue(
          CompositionIssueLevel.info,
          'Encore ${teamSize - agents.length} agent${teamSize - agents.length > 1 ? 's' : ''} à choisir.',
        ),
      );
    }
    if (agents.isNotEmpty) {
      if (counts[AgentRoles.controller] == 0) {
        issues.add(
          const CompositionIssue(
            CompositionIssueLevel.warning,
            'Aucun contrôleur : personne pour couper les lignes de vue avec des fumées.',
          ),
        );
      }
      if (counts[AgentRoles.initiator] == 0) {
        issues.add(
          const CompositionIssue(
            CompositionIssueLevel.warning,
            'Aucun initiateur : pas d\'info ni de flash pour ouvrir les sites.',
          ),
        );
      }
      if (counts[AgentRoles.sentinel] == 0) {
        issues.add(
          const CompositionIssue(
            CompositionIssueLevel.warning,
            'Aucune sentinelle : les flancs et la retake en défense sont exposés.',
          ),
        );
      }
      if (counts[AgentRoles.duelist] == 0 && agents.length == teamSize) {
        issues.add(
          const CompositionIssue(
            CompositionIssueLevel.info,
            'Aucun duelliste : prévois qui prend l\'entrée sur site.',
          ),
        );
      }
      if ((counts[AgentRoles.duelist] ?? 0) > 2) {
        issues.add(
          const CompositionIssue(
            CompositionIssueLevel.warning,
            'Plus de deux duellistes : beaucoup d\'entrée, peu d\'utilitaire pour la soutenir.',
          ),
        );
      }
      if ((counts[AgentRoles.controller] ?? 0) > 2) {
        issues.add(
          const CompositionIssue(CompositionIssueLevel.info, 'Trois contrôleurs ou plus : peu de puissance de feu.'),
        );
      }
    }

    final metaNames = {for (final agent in meta?.agents ?? const <CompositionAgent>[]) agent.agentName.toLowerCase()};
    final matches = agents.where((agent) => metaNames.contains(agent.displayName.toLowerCase())).length;

    return CompositionAnalysis(
      agents: agents,
      roleCounts: counts,
      issues: issues,
      metaMatches: matches,
      metaSize: metaNames.length,
    );
  }

  final List<Agent> agents;
  final Map<String, int> roleCounts;
  final List<CompositionIssue> issues;

  /// How many picked agents are part of the map's meta composition.
  final int metaMatches;
  final int metaSize;

  bool get isComplete => agents.length == teamSize;

  /// Complete, and without any warning.
  bool get isBalanced => isComplete && !issues.any((issue) => issue.level == CompositionIssueLevel.warning);
}
