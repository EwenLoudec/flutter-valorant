import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/widgets/motion.dart';
import 'rank_theme.dart';

/// The rank emblem in its own aura: light rays turning behind it, a breathing
/// halo, rings and sparks orbiting, all in the rank's colours. The higher the
/// rank, the livelier. Static when the platform asks for reduced motion.
class RankAura extends StatefulWidget {
  const RankAura({super.key, required this.theme, required this.child, this.size = 112});

  final RankTheme theme;

  /// The emblem itself, drawn over the aura at about two thirds of [size].
  final Widget child;
  final double size;

  @override
  State<RankAura> createState() => _RankAuraState();
}

class _RankAuraState extends State<RankAura> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 12));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (motionDisabled(context)) {
      _controller
        ..stop()
        ..value = 0.15;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emblem = widget.size * 0.66;

    return SizedBox.square(
      dimension: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _AuraPainter(animation: _controller, theme: widget.theme),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            child: SizedBox.square(dimension: emblem, child: widget.child),
            builder: (context, child) {
              final wave = math.sin(_controller.value * math.pi * 2 * 4);
              return Transform.translate(
                offset: Offset(0, -2.5 * wave),
                child: Transform.scale(scale: 1 + 0.025 * wave, child: child),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AuraPainter extends CustomPainter {
  _AuraPainter({required this.animation, required this.theme}) : super(repaint: animation);

  final Animation<double> animation;
  final RankTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = animation.value;
    final energy = theme.energy;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final breath = 0.5 + 0.5 * math.sin(t * math.pi * 2 * 3);

    // The halo, breathing.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            theme.main.withValues(alpha: (0.30 + 0.20 * breath) * (0.5 + energy / 2)),
            theme.deep.withValues(alpha: 0.18 * energy),
            Colors.transparent,
          ],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    // Light rays turning slowly behind the emblem.
    final rays = 6 + (energy * 8).round();
    final rayPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          theme.core.withValues(alpha: 0.38 * energy),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(t * math.pi * 2);
    for (var index = 0; index < rays; index++) {
      final angle = index * math.pi * 2 / rays;
      final spread = math.pi / rays * 0.35;
      final length = radius * (0.85 + 0.15 * math.sin(t * math.pi * 2 * 5 + index));
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(math.cos(angle - spread) * length, math.sin(angle - spread) * length)
          ..lineTo(math.cos(angle + spread) * length, math.sin(angle + spread) * length)
          ..close(),
        rayPaint,
      );
    }
    canvas.restore();

    // Two broken rings turning the opposite ways.
    for (final (ring, direction, alpha) in [(0.80, -1.0, 0.75), (0.93, 1.0, 0.4)]) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring < 0.9 ? 1.6 : 1
        ..strokeCap = StrokeCap.round
        ..color = theme.main.withValues(alpha: alpha * (0.5 + energy / 2));
      final rect = Rect.fromCircle(center: center, radius: radius * ring);
      final start = direction * t * math.pi * 2 * 1.5;
      for (var arc = 0; arc < 3; arc++) {
        canvas.drawArc(rect, start + arc * math.pi * 2 / 3, math.pi * 2 / 3 * 0.55, false, paint);
      }
    }

    // Sparks orbiting the emblem.
    final sparks = 2 + (energy * 5).round();
    for (var index = 0; index < sparks; index++) {
      final angle = t * math.pi * 2 * 2 + index * math.pi * 2 / sparks;
      final orbit = radius * (0.80 + 0.06 * math.sin(t * math.pi * 2 * 6 + index));
      final spark = center + Offset(math.cos(angle), math.sin(angle)) * orbit;
      canvas.drawCircle(
        spark,
        4.5,
        Paint()
          ..color = theme.main.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(spark, 1.6, Paint()..color = theme.core);
    }
  }

  @override
  bool shouldRepaint(covariant _AuraPainter oldDelegate) => oldDelegate.theme != theme;
}
