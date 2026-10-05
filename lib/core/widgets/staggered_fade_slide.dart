import 'package:flutter/material.dart';

import 'motion.dart';

/// Fades and lifts [child] in once, after a delay growing with [index], so a
/// list unfolds from the top. Shown in place straight away under reduced
/// motion.
class StaggeredFadeSlide extends StatefulWidget {
  const StaggeredFadeSlide({
    super.key,
    required this.index,
    required this.child,
    this.step = const Duration(milliseconds: 35),
    this.maxDelaySteps = 14,
  });

  final int index;
  final Widget child;
  final Duration step;
  final int maxDelaySteps;

  static const _length = Duration(milliseconds: 380);

  @override
  State<StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<StaggeredFadeSlide> with SingleTickerProviderStateMixin {
  // The delay is the start of one longer animation rather than a timer, so
  // nothing is left pending when the widget goes away early.
  late final Duration _delay = widget.step * widget.index.clamp(0, widget.maxDelaySteps);
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _delay + StaggeredFadeSlide._length,
  );
  late final double _start = _delay.inMicroseconds / _controller.duration!.inMicroseconds;
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Interval(_start, 1, curve: Curves.easeOut),
  );
  late final Animation<Offset> _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
    CurvedAnimation(
      parent: _controller,
      curve: Interval(_start, 1, curve: Curves.easeOutCubic),
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (motionDisabled(context)) {
      _controller.value = 1;
    } else if (_controller.isDismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
