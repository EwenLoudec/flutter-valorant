import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fade_in_network_image.dart';
import '../../encyclopedia/domain/agent.dart';
import '../domain/lineup.dart';
import '../providers/lineups_providers.dart';
import 'lineup_map_painter.dart';

AgentAbility? findAbility(Agent? agent, String slot) {
  if (agent == null) return null;
  for (final ability in agent.abilities) {
    if (ability.slot == slot) return ability;
  }
  return null;
}

/// The agent's portrait with their ability pinned in the corner — the
/// signature of a spot, used in the list and on the detail screen.
class LineupAbilityBadge extends ConsumerWidget {
  const LineupAbilityBadge({super.key, required this.lineup, this.size = 44});

  final Lineup lineup;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agent = ref.watch(agentByNameProvider(lineup.agentName));
    final abilityIcon = findAbility(agent, lineup.abilitySlot)?.displayIcon;
    final color = lineupSideColor(lineup.side);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.black26,
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: agent?.displayIcon == null
                ? const Icon(Icons.person, color: Colors.white24)
                : FadeInNetworkImage(url: agent!.displayIcon!, fit: BoxFit.contain),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: size * 0.46,
              height: size * 0.46,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppTheme.valorantDark,
                border: Border.all(color: color),
              ),
              child: abilityIcon == null
                  ? Center(
                      child: Text(
                        lineup.abilityKey,
                        style: TextStyle(fontSize: size * 0.2, fontWeight: FontWeight.w900, color: color),
                      ),
                    )
                  : FadeInNetworkImage(url: abilityIcon, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}

/// What the ability actually does, straight from Riot's own catalogue — so
/// a spot reads even for an agent you never play.
class LineupAbilityCard extends ConsumerWidget {
  const LineupAbilityCard({super.key, required this.lineup});

  final Lineup lineup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agent = ref.watch(agentByNameProvider(lineup.agentName));
    final ability = findAbility(agent, lineup.abilitySlot);
    if (ability == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: AppTheme.outlineDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: ability.displayIcon == null
                ? const Icon(Icons.bolt, size: 18, color: Colors.white24)
                : FadeInNetworkImage(url: ability.displayIcon!, fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      ability.displayName.toUpperCase(),
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 0.4),
                    ),
                    if (lineup.abilityKey.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      LineupTag(text: 'Touche ${lineup.abilityKey}', color: AppTheme.valorantMuted),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  ability.description,
                  style: const TextStyle(fontSize: 11.5, height: 1.45, color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small uppercase tag, the app's usual way of labelling anything.
class LineupTag extends StatelessWidget {
  const LineupTag({super.key, required this.text, required this.color, this.icon, this.filled = false});

  final String text;
  final Color color;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.18) : Colors.transparent,
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            text.toUpperCase(),
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.4, color: color),
          ),
        ],
      ),
    );
  }
}

/// Status tags shared by the list and the detail screen. The last one says
/// how much of the guide is written down, which is what tells a usable spot
/// from a placeholder.
List<Widget> lineupTags(Lineup lineup) {
  final isComplete = lineup.completedSteps == Lineup.totalSteps;

  return [
    LineupTag(text: lineup.side.label, color: lineupSideColor(lineup.side), filled: true),
    LineupTag(text: lineup.difficulty.label, color: Colors.white54),
    if (lineup.isVerified && isComplete)
      const LineupTag(text: 'Vérifié', color: Color(0xFF2FBF8F), icon: Icons.check_circle_outline)
    else
      LineupTag(
        text: 'Fiche ${lineup.completedSteps}/${Lineup.totalSteps}',
        color: const Color(0xFFF2B90C),
        icon: Icons.edit_note,
      ),
    if (!lineup.isBundled) const LineupTag(text: 'Perso', color: AppTheme.valorantRed),
  ];
}
