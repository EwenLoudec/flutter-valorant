import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fade_in_network_image.dart';
import '../domain/lineup.dart';
import '../providers/lineups_providers.dart';
import 'lineup_map_painter.dart';

/// Attack / defense switch. null shows both halves.
class LineupSideFilter extends StatelessWidget {
  const LineupSideFilter({super.key, required this.selected, required this.onSelected});

  final LineupSide? selected;
  final ValueChanged<LineupSide?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SideButton(label: 'Tous', color: Colors.white70, isSelected: selected == null, onTap: () => onSelected(null)),
        const SizedBox(width: 8),
        for (final side in [LineupSide.attack, LineupSide.defense]) ...[
          _SideButton(
            label: side.label,
            color: lineupSideColor(side),
            isSelected: selected == side,
            onTap: () => onSelected(side),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({required this.label, required this.color, required this.isSelected, required this.onTap});

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: isSelected ? color : Colors.white24),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: isSelected ? color : Colors.white54,
          ),
        ),
      ),
    );
  }
}

/// Horizontal row of the agents that actually have a spot on this map.
class LineupAgentFilter extends ConsumerWidget {
  const LineupAgentFilter({super.key, required this.agentNames, required this.selected, required this.onSelected});

  final List<String> agentNames;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 66,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _AgentAvatar(
            label: 'Tous',
            iconUrl: null,
            isSelected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final agentName in agentNames)
            _AgentAvatar(
              label: agentName,
              iconUrl: ref.watch(agentByNameProvider(agentName))?.displayIcon,
              isSelected: selected == agentName,
              onTap: () => onSelected(agentName),
            ),
        ],
      ),
    );
  }
}

class _AgentAvatar extends StatelessWidget {
  const _AgentAvatar({required this.label, required this.iconUrl, required this.isSelected, required this.onTap});

  final String label;
  final String? iconUrl;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppTheme.valorantRed : Colors.white24;
    final iconUrl = this.iconUrl;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 42,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.valorantRed.withValues(alpha: 0.18) : Colors.white10,
                border: Border.all(color: color, width: isSelected ? 2 : 1),
              ),
              child: iconUrl == null
                  ? Icon(Icons.groups_rounded, size: 18, color: isSelected ? AppTheme.valorantRed : Colors.white54)
                  : ClipOval(child: FadeInNetworkImage(url: iconUrl, fit: BoxFit.contain)),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 52,
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? AppTheme.valorantRed : Colors.white38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
