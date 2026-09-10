import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../../core/widgets/fade_in_network_image.dart';
import '../../domain/agent.dart';
import '../../domain/map_composition.dart';
import '../agents/agent_role_style.dart';

class MapCompositionCard extends StatelessWidget {
  const MapCompositionCard({super.key, required this.composition, required this.agentsByName});

  final MapComposition composition;
  final Map<String, Agent> agentsByName;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const DiagonalCutClipper(cut: 14),
      child: Container(
        color: AppTheme.valorantSurface,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.military_tech, size: 16, color: AppTheme.valorantRed),
                const SizedBox(width: 6),
                const Text(
                  'COMPOSITION MÉTA',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, letterSpacing: 0.5),
                ),
                const Spacer(),
                Text(
                  '${composition.winRatePercent}% WR',
                  style: const TextStyle(color: AppTheme.valorantRed, fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final agent in composition.agents)
                  _AgentChip(agent: agent, matchedAgent: agentsByName[agent.agentName]),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Composition communautaire (statistiques de parties classées), indicative — peut évoluer avec les patchs.',
              style: TextStyle(fontSize: 10.5, color: Colors.white38, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentChip extends StatelessWidget {
  const _AgentChip({required this.agent, required this.matchedAgent});

  final CompositionAgent agent;
  final Agent? matchedAgent;

  @override
  Widget build(BuildContext context) {
    final style = AgentRoleStyle.of(agent.role);
    final portrait = matchedAgent?.displayIcon;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: style.color.withValues(alpha: 0.14),
            border: Border.all(color: style.color, width: 1.5),
          ),
          child: portrait != null
              ? FadeInNetworkImage(url: portrait, fit: BoxFit.cover)
              : Icon(style.icon, color: style.color, size: 18),
        ),
        const SizedBox(height: 5),
        Text(
          agent.agentName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10.5),
        ),
      ],
    );
  }
}
