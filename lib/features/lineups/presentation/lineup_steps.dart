import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/lineup.dart';
import '../domain/lineup_media.dart';
import 'lineup_media_view.dart';

/// One numbered step of a spot's guide: what to do, and the picture that
/// shows it. An empty step says so instead of being hidden, so it is obvious
/// what the spot still needs.
class LineupStep extends StatelessWidget {
  const LineupStep({
    super.key,
    required this.index,
    required this.title,
    required this.body,
    required this.emptyHint,
    required this.media,
    this.trailing,
    this.fallback,
  });

  final int index;
  final String title;
  final String body;
  final String emptyHint;
  final LineupMedia? media;
  final Widget? trailing;

  /// Shown when no picture has been attached yet — the zoomed plan, so the
  /// step is never a blank.
  final Widget? fallback;

  bool get _isFilled => body.isNotEmpty;

  /// An empty step with nothing to show would be a heading over a grey line:
  /// it is dropped, and the progress card lists what is missing instead.
  bool get _hasSomethingToShow => _isFilled || media != null || fallback != null;

  @override
  Widget build(BuildContext context) {
    if (!_hasSomethingToShow) return const SizedBox.shrink();

    final media = this.media;
    final color = _isFilled ? AppTheme.valorantRed : Colors.white24;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  border: Border.all(color: color),
                ),
                child: Text(
                  '$index',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isFilled ? body : emptyHint,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: _isFilled ? Colors.white70 : Colors.white30,
                        fontStyle: _isFilled ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                    if (trailing != null) ...[const SizedBox(height: 8), trailing!],
                  ],
                ),
              ),
            ],
          ),
          if (media != null) ...[
            const SizedBox(height: 10),
            LineupMediaView(media: media),
          ] else if (fallback != null) ...[
            const SizedBox(height: 10),
            fallback!,
          ],
        ],
      ),
    );
  }
}

/// The steps still to write down, named so the progress card says what to do
/// without each empty step taking a block of screen.
List<String> _missingLabels(Lineup lineup) {
  return [
    if (lineup.position.isEmpty) 'position',
    if (lineup.aim.isEmpty && lineup.isThrow) 'visée',
    if (!lineup.throwStyle.isSpecified) 'type de lancer',
    if (lineup.media.isEmpty && lineup.demoUrl == null) 'photo ou vidéo',
  ];
}

/// The "2 étapes sur 4" progress line shown at the top of a spot.
class LineupCompleteness extends StatelessWidget {
  const LineupCompleteness({super.key, required this.lineup, this.onComplete});

  final Lineup lineup;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final completed = lineup.completedSteps;
    final isComplete = completed == Lineup.totalSteps;
    final color = isComplete ? const Color(0xFF2FBF8F) : const Color(0xFFF2B90C);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isComplete ? Icons.check_circle_outline : Icons.edit_note, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isComplete
                      ? 'Fiche complète — position, visée, lancer et média.'
                      : 'Fiche $completed/${Lineup.totalSteps} — à compléter : ${_missingLabels(lineup).join(', ')}.',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var step = 0; step < Lineup.totalSteps; step++) ...[
                Expanded(
                  child: Container(
                    height: 4,
                    color: step < completed ? color : Colors.white12,
                  ),
                ),
                if (step < Lineup.totalSteps - 1) const SizedBox(width: 4),
              ],
            ],
          ),
          if (!isComplete && onComplete != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onComplete,
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text(
                  'COMPLÉTER',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
