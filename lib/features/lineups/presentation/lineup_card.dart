import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../domain/lineup.dart';
import 'lineup_map_painter.dart';
import 'lineup_visuals.dart';

/// One spot in the list: who throws what, from where to where.
class LineupCard extends StatelessWidget {
  const LineupCard({
    super.key,
    required this.lineup,
    required this.isSelected,
    required this.onTap,
    this.onLocate,
  });

  final Lineup lineup;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLocate;

  @override
  Widget build(BuildContext context) {
    final color = lineupSideColor(lineup.side);
    final target = lineup.to;

    return ClipPath(
      clipper: const DiagonalCutClipper(cut: 10),
      child: Material(
        color: isSelected ? const Color(0xFF243039) : AppTheme.valorantSurface,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: color, width: isSelected ? 4 : 2)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LineupAbilityBadge(lineup: lineup),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lineup.title.toUpperCase(),
                        maxLines: 2,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              target == null
                                  ? '${lineup.agentName} · ${lineup.from.label}'
                                  : '${lineup.from.label} → ${target.label}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: AppTheme.valorantMuted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Wrap(spacing: 5, runSpacing: 5, children: lineupTags(lineup)),
                    ],
                  ),
                ),
                if (onLocate != null)
                  IconButton(
                    tooltip: 'Situer sur la carte',
                    onPressed: onLocate,
                    icon: Icon(
                      Icons.my_location,
                      size: 18,
                      color: isSelected ? color : Colors.white24,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
