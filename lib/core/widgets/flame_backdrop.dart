import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The three colours of a [FlameBackdrop], from the hottest to the deepest.
class FlamePalette {
  const FlamePalette({required this.core, required this.flame, required this.ember});

  static const fire = FlamePalette(core: Color(0xFFFFD27A), flame: Color(0xFFFF7A2F), ember: Color(0xFFFF4655));

  final Color core;
  final Color flame;
  final Color ember;

  @override
  bool operator ==(Object other) =>
      other is FlamePalette && other.core == core && other.flame == flame && other.ember == ember;

  @override
  int get hashCode => Object.hash(core, flame, ember);
}

/// A fire glow rising from the bottom edge, with embers drifting up. Meant to
/// sit behind a hero header. Static when the platform asks for reduced
/// motion.
class FlameBackdrop extends StatefulWidget {
  const FlameBackdrop({super.key, this.intensity = 1, this.palette = FlamePalette.fire});

  /// 0 to 1: how bright the glow and how many embers.
  final double intensity;

  /// The fire's colours, so a rank can burn in its own.
  final FlamePalette palette;

  @override
  State<FlameBackdrop> createState() => _FlameBackdropState();
}

class _FlameBackdropState extends State<FlameBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 7));

  static final List<_Ember> _embers = _Ember.generate(34);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller
        ..stop()
        ..value = 0.35;
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
    return RepaintBoundary(
      child: CustomPaint(
        painter: _FlamePainter(
          animation: _controller,
          embers: _embers,
          intensity: widget.intensity,
          palette: widget.palette,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _Ember {
  const _Ember({required this.x, required this.speed, required this.size, required this.phase, required this.drift});

  /// Always the same embers, so the fire does not jump between rebuilds.
  static List<_Ember> generate(int count) {
    final random = math.Random(7);
    return [
      for (var index = 0; index < count; index++)
        _Ember(
          x: random.nextDouble(),
          speed: 0.55 + random.nextDouble() * 0.9,
          size: 1.2 + random.nextDouble() * 2.6,
          phase: random.nextDouble(),
          drift: 0.01 + random.nextDouble() * 0.035,
        ),
    ];
  }

  final double x;
  final double speed;
  final double size;
  final double phase;
  final double drift;
}

class _FlamePainter extends CustomPainter {
  _FlamePainter({required this.animation, required this.embers, required this.intensity, required this.palette})
    : super(repaint: animation);

  final Animation<double> animation;
  final List<_Ember> embers;
  final double intensity;
  final FlamePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final core = palette.core;
    final flame = palette.flame;
    final ember = palette.ember;
    final t = animation.value;
    final flicker = 0.85 + 0.15 * math.sin(t * math.pi * 2 * 3);
    final rect = Offset.zero & size;

    // The heat rising from the bottom edge.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            ember.withValues(alpha: 0.42 * intensity),
            flame.withValues(alpha: 0.12 * intensity),
            Colors.transparent,
          ],
          stops: const [0, 0.45, 1],
        ).createShader(rect),
    );

    // Two flickering hearths, so the glow is not a flat band.
    for (final (center, radius) in [(0.22, 0.75), (0.78, 0.65)]) {
      canvas.drawCircle(
        Offset(size.width * center, size.height * 1.05),
        size.height * radius * flicker,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  flame.withValues(alpha: 0.38 * intensity * flicker),
                  ember.withValues(alpha: 0.10 * intensity),
                  Colors.transparent,
                ],
              ).createShader(
                Rect.fromCircle(center: Offset(size.width * center, size.height * 1.05), radius: size.height * radius),
              ),
      );
    }

    final count = (embers.length * intensity.clamp(0.0, 1.0)).round();
    for (final particle in embers.take(count)) {
      final progress = (t * particle.speed + particle.phase) % 1;
      final y = size.height * (1 - progress);
      final x = size.width * (particle.x + math.sin((progress + particle.phase) * math.pi * 4) * particle.drift);
      final fade = (1 - progress) * math.min(1, progress * 6);
      final color = Color.lerp(core, ember, progress)!.withValues(alpha: 0.9 * fade);
      final center = Offset(x, y);

      canvas.drawCircle(
        center,
        particle.size * 2.6,
        Paint()
          ..color = color.withValues(alpha: 0.22 * fade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(center, particle.size * (1 - progress * 0.5), Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _FlamePainter oldDelegate) =>
      oldDelegate.intensity != intensity || oldDelegate.palette != palette || !identical(oldDelegate.embers, embers);
}
