import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../../encyclopedia/domain/game_map.dart';

/// Close-up of the tactical map around one end of a spot, with the callouts
/// around it and the trajectory leaving the frame — Riot's minimap is the
/// only picture of the terrain the app may ship, so it is made as readable
/// as possible: it says *where*, where an in-game capture says *what it
/// looks like*.
class LineupZoomView extends StatelessWidget {
  const LineupZoomView({
    super.key,
    required this.map,
    required this.focus,
    required this.other,
    required this.color,
    required this.label,
    required this.isTarget,
    this.zoom = 2.3,
    this.height = 165,
  });

  final GameMap map;

  /// The point the crop is centred on, in fractions of the minimap.
  final Offset focus;

  /// The other end of the spot, drawn as the direction the throw comes from
  /// or goes to. Null for a placement.
  final Offset? other;

  final Color color;
  final String label;
  final bool isTarget;
  final double zoom;
  final double height;

  @override
  Widget build(BuildContext context) {
    final displayIcon = map.displayIcon;
    if (displayIcon == null) return const SizedBox();

    return ClipPath(
      clipper: const DiagonalCutClipper(cut: 10),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.valorantSurface,
          border: Border.all(color: AppTheme.outlineDark),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The minimap is square: blown up to `width * zoom` and slid so
            // the focus point sits dead centre.
            final side = constraints.maxWidth * zoom;
            final origin = Offset(
              constraints.maxWidth / 2 - focus.dx * side,
              constraints.maxHeight / 2 - focus.dy * side,
            );

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: origin.dx,
                  top: origin.dy,
                  width: side,
                  height: side,
                  child: Image.network(displayIcon, fit: BoxFit.cover),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ZoomPainter(
                      map: map,
                      origin: origin,
                      side: side,
                      focus: focus,
                      other: other,
                      color: color,
                      isTarget: isTarget,
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    color: Colors.black.withValues(alpha: 0.7),
                    child: Text(
                      label.toUpperCase(),
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Draws, in the zoomed frame: the callout names for orientation, the
/// trajectory, and the marker for this end of the spot.
class _ZoomPainter extends CustomPainter {
  const _ZoomPainter({
    required this.map,
    required this.origin,
    required this.side,
    required this.focus,
    required this.other,
    required this.color,
    required this.isTarget,
  });

  final GameMap map;
  final Offset origin;
  final double side;
  final Offset focus;
  final Offset? other;
  final Color color;
  final bool isTarget;

  Offset _toLocal(Offset normalized) => origin + Offset(normalized.dx * side, normalized.dy * side);

  @override
  void paint(Canvas canvas, Size size) {
    _paintCallouts(canvas, size);

    final center = _toLocal(focus);
    final other = this.other;
    if (other != null) _paintTrajectory(canvas, center, _toLocal(other));

    _paintMarker(canvas, center);
  }

  void _paintCallouts(Canvas canvas, Size size) {
    for (final callout in map.callouts) {
      final position = _toLocal(map.normalizedPosition(callout));
      if (!size.contains(position)) continue;
      // The marker sits at the centre: no label under it.
      if ((position - size.center(Offset.zero)).distance < 26) continue;

      _paintText(canvas, callout.regionName.toUpperCase(), position, Colors.white.withValues(alpha: 0.75));
    }
  }

  void _paintTrajectory(Canvas canvas, Offset center, Offset other) {
    final delta = other - center;
    if (delta.distance == 0) return;

    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(other.dx, other.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = color.withValues(alpha: 0.75),
    );

    // An arrowhead a short way along, so the direction reads even when the
    // other end is far outside the frame.
    final direction = delta / delta.distance;
    final at = center + direction * 46;
    final angle = math.atan2(direction.dy, direction.dx);
    final head = Path()
      ..moveTo(at.dx, at.dy)
      ..lineTo(at.dx - 9 * math.cos(angle - 0.4), at.dy - 9 * math.sin(angle - 0.4))
      ..lineTo(at.dx - 9 * math.cos(angle + 0.4), at.dy - 9 * math.sin(angle + 0.4))
      ..close();
    canvas.drawPath(head, Paint()..color = color);
  }

  void _paintMarker(Canvas canvas, Offset center) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color;

    if (isTarget) {
      canvas.drawCircle(center, 12, stroke);
      for (final angle in [0, math.pi / 2, math.pi, 3 * math.pi / 2]) {
        final direction = Offset(math.cos(angle), math.sin(angle));
        canvas.drawLine(center + direction * 7, center + direction * 20, stroke);
      }
      canvas.drawCircle(center, 2.5, Paint()..color = color);
      return;
    }

    canvas.drawCircle(center, 7, Paint()..color = color);
    canvas.drawCircle(
      center,
      7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.black.withValues(alpha: 0.75),
    );
    canvas.drawCircle(center, 15, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = color.withValues(alpha: 0.55));
  }

  void _paintText(Canvas canvas, String text, Offset at, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    painter.paint(canvas, at - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(_ZoomPainter oldDelegate) {
    return oldDelegate.origin != origin ||
        oldDelegate.side != side ||
        oldDelegate.focus != focus ||
        oldDelegate.other != other ||
        oldDelegate.color != color ||
        oldDelegate.isTarget != isTarget;
  }
}
