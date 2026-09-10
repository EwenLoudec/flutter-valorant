import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/diagonal_cut_clipper.dart';
import '../../domain/game_map.dart';

const List<String> _kSiteLetters = ['A', 'B', 'C'];

/// Top-down tactical minimap with every callout name labelled directly on
/// the terrain, big site letters (A/B/C), and an optional ping animation to
/// locate one callout — a static reference view, not a zoomable one.
class TacticalMinimap extends StatelessWidget {
  const TacticalMinimap({super.key, required this.map, this.highlighted, this.highlightToken});

  final GameMap map;

  /// The callout to ping-highlight, if any.
  final MapCallout? highlighted;

  /// Changes on every tap so re-selecting the same callout replays the ping.
  final Object? highlightToken;

  static Color colorForSuperRegion(String superRegion) {
    switch (superRegion) {
      case 'A':
        return const Color(0xFFFF4655);
      case 'B':
        return const Color(0xFF4FD1C5);
      case 'C':
        return const Color(0xFFF2B90C);
      case 'Mid':
        return const Color(0xFFB667F1);
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (map.displayIcon == null) return const SizedBox();

    final siteAnchors = <String, MapCallout>{};
    for (final letter in _kSiteLetters) {
      final regionCallouts = map.callouts.where((c) => c.superRegionName == letter);
      if (regionCallouts.isEmpty) continue;
      MapCallout anchor = regionCallouts.first;
      for (final callout in regionCallouts) {
        if (callout.regionName == 'Site') {
          anchor = callout;
          break;
        }
      }
      siteAnchors[letter] = anchor;
    }

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
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(map.displayIcon!, fit: BoxFit.cover),
                  for (final entry in siteAnchors.entries)
                    _buildSiteLetter(entry.key, map.normalizedPosition(entry.value), size),
                  for (final callout in map.callouts)
                    _buildLabel(callout, map.normalizedPosition(callout), size, callout == highlighted),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Keeps labels off the very edge — the terrain art itself has a blank
  // margin baked into the square image, and a label centered too close to
  // the true edge can overlap that margin or overflow the clipped panel.
  static const _edgeInset = 0.08;

  Widget _buildSiteLetter(String letter, Offset normalized, Size size) {
    final color = colorForSuperRegion(letter);
    final dx = normalized.dx.clamp(_edgeInset, 1 - _edgeInset) * size.width;
    final dy = normalized.dy.clamp(_edgeInset, 1 - _edgeInset) * size.height;

    return Positioned(
      left: dx,
      top: dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.22),
            border: Border.all(color: color, width: 1.4),
          ),
          child: Text(
            letter,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(MapCallout callout, Offset normalized, Size size, bool isHighlighted) {
    final color = colorForSuperRegion(callout.superRegionName);
    final dx = normalized.dx.clamp(_edgeInset, 1 - _edgeInset) * size.width;
    final dy = normalized.dy.clamp(_edgeInset, 1 - _edgeInset) * size.height;

    return Positioned(
      left: dx,
      top: dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: _CalloutLabel(
          key: isHighlighted ? ValueKey(highlightToken) : null,
          name: callout.regionName,
          color: color,
          ping: isHighlighted,
        ),
      ),
    );
  }
}

class _CalloutLabel extends StatefulWidget {
  const _CalloutLabel({super.key, required this.name, required this.color, required this.ping});

  final String name;
  final Color color;
  final bool ping;

  @override
  State<_CalloutLabel> createState() => _CalloutLabelState();
}

class _CalloutLabelState extends State<_CalloutLabel> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.ping) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (widget.ping && t < 1)
              Container(
                width: 44 * t,
                height: 44 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.color.withValues(alpha: (1 - t).clamp(0.0, 1.0)), width: 2),
                ),
              ),
            Transform.scale(
              scale: widget.ping ? 1 + 0.6 * math.sin(t * math.pi) : 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                decoration: BoxDecoration(
                  color: widget.ping
                      ? Color.lerp(widget.color.withValues(alpha: 0.9), Colors.black.withValues(alpha: 0.75), t)
                      : Colors.black.withValues(alpha: 0.75),
                  border: Border.all(color: widget.color, width: widget.ping ? 1.4 : 0.8),
                ),
                child: Text(
                  widget.name,
                  style: TextStyle(color: widget.color, fontSize: 8.5, fontWeight: FontWeight.w800, height: 1),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
