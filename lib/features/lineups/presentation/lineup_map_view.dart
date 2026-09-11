import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../../encyclopedia/domain/game_map.dart';
import '../domain/resolved_lineup.dart';
import 'lineup_map_painter.dart';

/// The tactical minimap with the spots drawn on top. Tapping a marker selects
/// it; tapping anywhere else reports the position, which the editor uses to
/// place its points.
class LineupMapView extends StatelessWidget {
  const LineupMapView({
    super.key,
    required this.map,
    required this.lineups,
    this.selectedId,
    this.onSelect,
    this.onTapPosition,
    this.pendingFrom,
    this.pendingTo,
    this.showCallouts = true,
  });

  /// How close (in fractions of the map) a tap has to be to count as hitting
  /// a marker rather than the terrain.
  static const _hitRadius = 0.045;

  final GameMap map;
  final List<ResolvedLineup> lineups;
  final String? selectedId;
  final ValueChanged<String>? onSelect;
  final ValueChanged<Offset>? onTapPosition;
  final Offset? pendingFrom;
  final Offset? pendingTo;
  final bool showCallouts;

  void _handleTap(Offset localPosition, Size size) {
    final normalized = Offset(localPosition.dx / size.width, localPosition.dy / size.height);

    final hit = _lineupAt(normalized);
    if (hit != null && onSelect != null) {
      onSelect!(hit);
      return;
    }
    onTapPosition?.call(normalized);
  }

  String? _lineupAt(Offset normalized) {
    String? closestId;
    var closestDistance = _hitRadius;

    for (final resolved in lineups) {
      for (final point in [resolved.from, ?resolved.to]) {
        final distance = (point - normalized).distance;
        if (distance > closestDistance) continue;
        closestDistance = distance;
        closestId = resolved.lineup.id;
      }
    }
    return closestId;
  }

  @override
  Widget build(BuildContext context) {
    final displayIcon = map.displayIcon;
    if (displayIcon == null) return const SizedBox();

    return ClipPath(
      clipper: const DiagonalCutClipper(cut: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.valorantSurface,
          border: Border.all(color: AppTheme.outlineDark),
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) => _handleTap(details.localPosition, size),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(displayIcon, fit: BoxFit.cover),
                    CustomPaint(
                      painter: LineupMapPainter(
                        map: map,
                        lineups: lineups,
                        selectedId: selectedId,
                        showCallouts: showCallouts,
                        pendingFrom: pendingFrom,
                        pendingTo: pendingTo,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
