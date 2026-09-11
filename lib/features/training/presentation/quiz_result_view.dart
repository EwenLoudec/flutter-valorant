import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../domain/map_quiz.dart';

const _goodColor = Color(0xFF2FBF8F);

/// End of a run: the total, then what each callout was worth.
class QuizResultView extends StatelessWidget {
  const QuizResultView({
    super.key,
    required this.round,
    required this.answers,
    required this.score,
    required this.isMapGuessRight,
    required this.isRecord,
    required this.onReplay,
    required this.onLeave,
  });

  final MapQuizRound round;
  final List<CalloutAnswer> answers;
  final int score;
  final bool isMapGuessRight;
  final bool isRecord;
  final VoidCallback onReplay;
  final VoidCallback onLeave;

  String get _comment {
    final ratio = score / round.maxScore;
    if (ratio >= 0.9) return 'Tu connais cette carte par cœur.';
    if (ratio >= 0.7) return 'Solide — encore deux ou trois callouts à caler.';
    if (ratio >= 0.4) return 'Les grandes zones sont là, les détails moins.';
    return 'À retravailler : ouvre la fiche de la carte et refais un tour.';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipPath(
          clipper: const DiagonalCutClipper(cut: 12),
          child: Container(
            color: AppTheme.valorantSurface,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isRecord) ...[
                  Row(
                    children: [
                      const Icon(Icons.emoji_events_outlined, size: 16, color: _goodColor),
                      const SizedBox(width: 6),
                      Text(
                        'NOUVEAU RECORD SUR ${round.map.displayName.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: _goodColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$score',
                      style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, height: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 4),
                      child: Text(
                        '/ ${round.maxScore} pts',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.valorantMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(_comment, style: const TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.4)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (round.asksMapName)
          _ResultRow(
            label: 'Nom de la carte',
            points: isMapGuessRight ? MapQuizRound.pointsPerMap : 0,
            detail: isMapGuessRight ? 'Reconnue' : 'Manquée',
          ),
        for (final (index, answer) in answers.indexed)
          _ResultRow(
            label: round.questions[index].label,
            points: answer.points,
            detail: '${answer.verdict} · ${(answer.distance * 100).toStringAsFixed(0)} %',
          ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: onReplay,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.valorantRed,
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text(
            'REJOUER CETTE CARTE',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: onLeave,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: const BorderSide(color: AppTheme.outlineDark),
            shape: const RoundedRectangleBorder(),
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
          child: const Text('CHANGER DE CARTE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.points, required this.detail});

  final String label;
  final int points;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final color = switch (points) {
      >= 70 => _goodColor,
      > 0 => const Color(0xFFF2B90C),
      _ => AppTheme.valorantRed,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(width: 3, height: 26, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                Text(detail, style: const TextStyle(fontSize: 10.5, color: AppTheme.valorantMuted)),
              ],
            ),
          ),
          Text(
            '+$points',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }
}
