import 'dart:ui';

import '../../encyclopedia/domain/game_map.dart';
import 'lineup.dart';

/// A spot whose anchors have been turned into positions on the minimap,
/// ready to draw.
class ResolvedLineup {
  const ResolvedLineup({required this.lineup, required this.from, required this.to});

  /// Returns null when an anchor points at a callout the map doesn't have —
  /// a spot nobody can place on the map is better hidden than drawn wrong.
  static ResolvedLineup? resolve(Lineup lineup, GameMap map) {
    final from = _resolveAnchor(lineup.from, map);
    if (from == null) return null;

    final target = lineup.to;
    if (target == null) return ResolvedLineup(lineup: lineup, from: from, to: null);

    final to = _resolveAnchor(target, map);
    if (to == null) return null;

    return ResolvedLineup(lineup: lineup, from: from, to: to);
  }

  final Lineup lineup;

  /// Fractional (0-1) positions on the tactical minimap image.
  final Offset from;
  final Offset? to;

  static Offset? _resolveAnchor(LineupAnchor anchor, GameMap map) {
    if (anchor.hasCoordinates) return Offset(anchor.x!, anchor.y!);

    final name = anchor.calloutName;
    if (name == null) return null;

    final region = anchor.calloutRegion;
    for (final callout in map.callouts) {
      if (callout.regionName != name) continue;
      if (region != null && region.isNotEmpty && callout.superRegionName != region) continue;
      return map.normalizedPosition(callout);
    }
    return null;
  }
}
