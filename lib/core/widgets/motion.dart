import 'package:flutter/material.dart';

/// Whether the platform asked for reduced motion. Every animation of the app
/// shows its end state straight away when it did.
bool motionDisabled(BuildContext context) => MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Counts from zero up to [value] once, then follows its changes.
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    required this.builder,
    this.duration = const Duration(milliseconds: 900),
  });

  final double value;
  final Widget Function(BuildContext context, double value) builder;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (motionDisabled(context)) return builder(context, value);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, current, _) => builder(context, current),
    );
  }
}

/// A rounded bar filled up to [fraction] (0 to 1), growing from the left the
/// first time it is shown.
class GrowBar extends StatelessWidget {
  const GrowBar({
    super.key,
    required this.fraction,
    required this.color,
    this.height = 6,
    this.backgroundColor = Colors.black38,
    this.glow = false,
  });

  final double fraction;
  final Color color;
  final double height;
  final Color backgroundColor;

  /// Adds a soft halo in [color] around the filled part.
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final target = fraction.isNaN ? 0.0 : fraction.clamp(0.0, 1.0);

    Widget bar(double value) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: backgroundColor)),
              FractionallySizedBox(
                widthFactor: value,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(height / 2),
                    gradient: LinearGradient(colors: [color.withValues(alpha: 0.75), color]),
                    boxShadow: glow ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8)] : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (motionDisabled(context)) return bar(target);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => bar(value),
    );
  }
}
