import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../../encyclopedia/domain/game_map.dart';
import '../../encyclopedia/presentation/maps/tactical_minimap.dart';

const _rightColor = Color(0xFF2FBF8F);

/// The tactical plan stripped of every label — the whole point of the game
/// is to know what goes where without being told.
class QuizMapBoard extends StatelessWidget {
  const QuizMapBoard({
    super.key,
    required this.map,
    this.onTapPosition,
    this.guess,
    this.target,
    this.isCorrect = false,
  });

  final GameMap map;

  /// Called with the fractional (0-1) position that was tapped.
  final ValueChanged<Offset>? onTapPosition;

  /// Where the player thinks the callout is.
  final Offset? guess;

  /// The real position, revealed once the answer is locked in.
  final Offset? target;

  final bool isCorrect;

  /// Where the A / B / C letters go — the only labels the game keeps, so the
  /// plan can be read without giving the callouts away.
  Map<String, Offset> get _sites {
    final anchors = <String, Offset>{};

    for (final letter in const ['A', 'B', 'C']) {
      final regionCallouts = map.callouts.where((callout) => callout.superRegionName == letter);
      if (regionCallouts.isEmpty) continue;

      final anchor = regionCallouts.firstWhere(
        (callout) => callout.regionName == 'Site',
        orElse: () => regionCallouts.first,
      );
      anchors[letter] = map.normalizedPosition(anchor);
    }
    return anchors;
  }

  @override
  Widget build(BuildContext context) {
    final displayIcon = map.displayIcon;
    if (displayIcon == null) return const SizedBox();

    return ClipPath(
      clipper: const DiagonalCutClipper(cut: 14),
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
                onTapUp: onTapPosition == null
                    ? null
                    : (details) => onTapPosition!(
                        Offset(
                          (details.localPosition.dx / size.width).clamp(0.0, 1.0),
                          (details.localPosition.dy / size.height).clamp(0.0, 1.0),
                        ),
                      ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(displayIcon, fit: BoxFit.cover),
                    CustomPaint(
                      painter: _BoardPainter(
                        sites: _sites,
                        guess: guess,
                        target: target,
                        isCorrect: isCorrect,
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

class _BoardPainter extends CustomPainter {
  const _BoardPainter({
    required this.sites,
    required this.guess,
    required this.target,
    required this.isCorrect,
  });

  final Map<String, Offset> sites;
  final Offset? guess;
  final Offset? target;
  final bool isCorrect;

  Offset _toLocal(Offset normalized, Size size) {
    return Offset(normalized.dx * size.width, normalized.dy * size.height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final guess = this.guess;
    final target = this.target;

    for (final site in sites.entries) {
      _paintSite(canvas, site.key, _toLocal(site.value, size));
    }

    if (guess != null && target != null) {
      _paintLink(canvas, _toLocal(guess, size), _toLocal(target, size));
    }
    if (target != null) _paintTarget(canvas, _toLocal(target, size));
    if (guess != null) {
      _paintGuess(canvas, _toLocal(guess, size), isRevealed: target != null);
    }
  }

  /// The site letter, in the same treatment as the encyclopedia's minimap.
  void _paintSite(Canvas canvas, String letter, Offset at) {
    final color = TacticalMinimap.colorForSuperRegion(letter);

    canvas.drawCircle(at, 15, Paint()..color = color.withValues(alpha: 0.22));
    canvas.drawCircle(
      at,
      15,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = color,
    );

    final painter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at - Offset(painter.width / 2, painter.height / 2));
  }

  void _paintGuess(Canvas canvas, Offset at, {required bool isRevealed}) {
    final color = isRevealed ? (isCorrect ? _rightColor : AppTheme.valorantRed) : Colors.white;

    canvas.drawCircle(at, 9, Paint()..color = color.withValues(alpha: 0.25));
    canvas.drawCircle(
      at,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = color,
    );
    canvas.drawCircle(at, 2.5, Paint()..color = color);
  }

  void _paintTarget(Canvas canvas, Offset at) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = _rightColor;

    canvas.drawCircle(at, 13, stroke);
    for (final angle in [0, math.pi / 2, math.pi, 3 * math.pi / 2]) {
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(at + direction * 7, at + direction * 20, stroke);
    }
    canvas.drawCircle(at, 3, Paint()..color = _rightColor);
  }

  /// Dashed line between the guess and the truth, so the gap is readable.
  void _paintLink(Canvas canvas, Offset from, Offset to) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Colors.white.withValues(alpha: 0.7);

    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(to.dx, to.dy);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + 5, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + 4;
      }
    }
  }

  @override
  bool shouldRepaint(_BoardPainter oldDelegate) {
    return oldDelegate.guess != guess ||
        oldDelegate.target != target ||
        oldDelegate.isCorrect != isCorrect ||
        oldDelegate.sites != sites;
  }
}

/// Draws the map name over a blurred plan — used on the launcher card.
class QuizBoardPreview extends StatelessWidget {
  const QuizBoardPreview({super.key, required this.imageUrl, required this.label});

  final String imageUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const DiagonalCutClipper(cut: 10),
      child: SizedBox(
        height: 96,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
            const DecoratedBox(decoration: BoxDecoration(color: Color(0xAA0F1923))),
            Center(
              child: Text(
                label.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
