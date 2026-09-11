import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../encyclopedia/domain/game_map.dart';
import '../domain/lineup.dart';
import '../domain/resolved_lineup.dart';

const _attackColor = Color(0xFFFF4655);
const _defenseColor = Color(0xFF4FD1C5);
const _bothColor = Color(0xFFF2B90C);

Color lineupSideColor(LineupSide side) => switch (side) {
  LineupSide.attack => _attackColor,
  LineupSide.defense => _defenseColor,
  LineupSide.both => _bothColor,
};

/// Draws the spots over the tactical minimap: an arc from the throwing
/// position to the target for a throw, a diamond for a placement, plus the
/// callout names to keep the plan readable.
class LineupMapPainter extends CustomPainter {
  const LineupMapPainter({
    required this.map,
    required this.lineups,
    required this.selectedId,
    required this.showCallouts,
    this.pendingFrom,
    this.pendingTo,
  });

  final GameMap map;
  final List<ResolvedLineup> lineups;
  final String? selectedId;
  final bool showCallouts;

  /// Points being placed in the editor, before the spot is saved.
  final Offset? pendingFrom;
  final Offset? pendingTo;

  @override
  void paint(Canvas canvas, Size size) {
    if (showCallouts) _paintCallouts(canvas, size);

    final ranks = _rankDuplicates();

    for (final resolved in lineups) {
      if (resolved.lineup.id == selectedId) continue;
      _paintLineup(canvas, size, resolved, rank: ranks[resolved.lineup.id] ?? 0, isSelected: false);
    }
    for (final resolved in lineups) {
      if (resolved.lineup.id != selectedId) continue;
      _paintLineup(canvas, size, resolved, rank: ranks[resolved.lineup.id] ?? 0, isSelected: true);
    }

    _paintPending(canvas, size);
  }

  /// Spots anchored on the same callouts would land exactly on top of each
  /// other; each gets a rank so they can be fanned out instead.
  Map<String, int> _rankDuplicates() {
    final seen = <String, int>{};
    final ranks = <String, int>{};

    for (final resolved in lineups) {
      final route = '${resolved.from}-${resolved.to}';
      final rank = seen[route] ?? 0;
      seen[route] = rank + 1;
      ranks[resolved.lineup.id] = rank;
    }
    return ranks;
  }

  void _paintCallouts(Canvas canvas, Size size) {
    for (final callout in map.callouts) {
      final position = _toLocal(map.normalizedPosition(callout), size);
      _paintText(
        canvas,
        callout.regionName.toUpperCase(),
        position,
        color: Colors.white.withValues(alpha: 0.45),
        fontSize: 7,
      );
    }
  }

  void _paintLineup(
    Canvas canvas,
    Size size,
    ResolvedLineup resolved, {
    required int rank,
    required bool isSelected,
  }) {
    final isDimmed = selectedId != null && !isSelected;
    final color = lineupSideColor(resolved.lineup.side).withValues(alpha: isDimmed ? 0.35 : 1);
    final from = _toLocal(resolved.from, size);
    final target = resolved.to;

    if (target == null) {
      _paintPlacement(canvas, from + _placementOffset(rank), color, isSelected);
      return;
    }

    final to = _toLocal(target, size);
    final control = _arcControlPoint(from, to, rank);

    canvas.drawPath(
      Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.6 : 1.4
        ..color = color
        ..strokeCap = StrokeCap.round,
    );

    _paintOrigin(canvas, from, color, isSelected);
    _paintTarget(canvas, to, control, color, isSelected);
  }

  /// Bends the line sideways, further and to the other side for each spot
  /// sharing the same route, so they read as a fan.
  Offset _arcControlPoint(Offset from, Offset to, int rank) {
    final delta = to - from;
    final distance = delta.distance;
    if (distance == 0) return from;

    final normal = Offset(-delta.dy, delta.dx) / distance;
    final bend = 0.18 * (1 + rank * 0.55) * (rank.isEven ? 1 : -1);
    return (from + to) / 2 + normal * distance * bend;
  }

  /// Spreads placements pinned to the same callout around a small circle.
  Offset _placementOffset(int rank) {
    if (rank == 0) return Offset.zero;

    final angle = rank * math.pi / 3;
    return Offset(math.cos(angle), math.sin(angle)) * 11;
  }

  void _paintOrigin(Canvas canvas, Offset at, Color color, bool isSelected) {
    if (isSelected) {
      canvas.drawCircle(
        at,
        11,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = color.withValues(alpha: 0.6),
      );
    }
    canvas.drawCircle(at, isSelected ? 6 : 4.5, Paint()..color = color);
    canvas.drawCircle(
      at,
      isSelected ? 6 : 4.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.black.withValues(alpha: 0.7),
    );
  }

  void _paintTarget(Canvas canvas, Offset at, Offset control, Color color, bool isSelected) {
    final radius = isSelected ? 7.0 : 5.0;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2 : 1.3
      ..color = color;

    canvas.drawCircle(at, radius, stroke);
    for (final angle in [0, math.pi / 2, math.pi, 3 * math.pi / 2]) {
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(at + direction * radius, at + direction * (radius + (isSelected ? 4 : 2.5)), stroke);
    }
    if (isSelected) canvas.drawCircle(at, 2, Paint()..color = color);
  }

  void _paintPlacement(Canvas canvas, Offset at, Color color, bool isSelected) {
    final radius = isSelected ? 8.0 : 6.0;
    final diamond = Path()
      ..moveTo(at.dx, at.dy - radius)
      ..lineTo(at.dx + radius, at.dy)
      ..lineTo(at.dx, at.dy + radius)
      ..lineTo(at.dx - radius, at.dy)
      ..close();

    canvas.drawPath(diamond, Paint()..color = color.withValues(alpha: isSelected ? 0.95 : 0.75));
    canvas.drawPath(
      diamond,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.black.withValues(alpha: 0.7),
    );
    if (isSelected) {
      canvas.drawCircle(
        at,
        radius + 5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = color.withValues(alpha: 0.6),
      );
    }
  }

  void _paintPending(Canvas canvas, Size size) {
    final from = pendingFrom;
    final to = pendingTo;
    if (from == null) return;

    final start = _toLocal(from, size);
    if (to != null) {
      final end = _toLocal(to, size);
      _paintDashedLine(canvas, start, end);
      _paintPendingMarker(canvas, end, '2');
    }
    _paintPendingMarker(canvas, start, '1');
  }

  void _paintPendingMarker(Canvas canvas, Offset at, String label) {
    canvas.drawCircle(at, 9, Paint()..color = Colors.white);
    canvas.drawCircle(
      at,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.black87,
    );
    _paintText(canvas, label, at, color: Colors.black, fontSize: 10, isBold: true, withShadow: false);
  }

  void _paintDashedLine(Canvas canvas, Offset from, Offset to) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white;

    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(to.dx, to.dy);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + 6, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + 5;
      }
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset at, {
    required Color color,
    required double fontSize,
    bool isBold = false,
    bool withShadow = true,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
          shadows: withShadow ? const [Shadow(color: Colors.black, blurRadius: 3)] : null,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    painter.paint(canvas, at - Offset(painter.width / 2, painter.height / 2));
  }

  Offset _toLocal(Offset normalized, Size size) {
    return Offset(normalized.dx * size.width, normalized.dy * size.height);
  }

  @override
  bool shouldRepaint(LineupMapPainter oldDelegate) {
    return oldDelegate.lineups != lineups ||
        oldDelegate.selectedId != selectedId ||
        oldDelegate.showCallouts != showCallouts ||
        oldDelegate.pendingFrom != pendingFrom ||
        oldDelegate.pendingTo != pendingTo;
  }
}
