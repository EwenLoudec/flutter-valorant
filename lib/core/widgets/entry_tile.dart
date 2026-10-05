import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'diagonal_cut_clipper.dart';
import 'pressable_scale.dart';

/// A compact, tappable entry towards a tool or a sub-page, in the angled
/// style of the training cards.
class EntryTile extends StatelessWidget {
  const EntryTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isHighlighted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Red-tinted like the main training cards, instead of the neutral surface.
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final color = isHighlighted ? AppTheme.valorantRed : Colors.white70;

    return PressableScale(
      onTap: onTap,
      child: ClipPath(
        clipper: const DiagonalCutClipper(cut: 8),
        child: Container(
          decoration: BoxDecoration(
            color: isHighlighted ? AppTheme.valorantRed.withValues(alpha: 0.12) : AppTheme.valorantSurface,
            border: Border.all(
              color: isHighlighted ? AppTheme.valorantRed.withValues(alpha: 0.6) : AppTheme.outlineDark,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
          child: Row(
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 0.4),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, color: AppTheme.valorantMuted, height: 1.3),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two [EntryTile]s side by side, or one stretched across.
class EntryTileRow extends StatelessWidget {
  const EntryTileRow({super.key, required this.tiles});

  final List<EntryTile> tiles;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, tile) in tiles.indexed) ...[
            if (index > 0) const SizedBox(width: 8),
            Expanded(child: tile),
          ],
        ],
      ),
    );
  }
}
