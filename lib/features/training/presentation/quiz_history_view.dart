import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../domain/quiz_run.dart';

const _goodColor = Color(0xFF2FBF8F);

/// The last games played, most recent first — enough to see progress
/// without turning into an archive.
class QuizHistoryView extends StatelessWidget {
  const QuizHistoryView({super.key, required this.history});

  final List<QuizRun> history;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 3, height: 14, color: AppTheme.valorantRed),
            const SizedBox(width: 8),
            const Text(
              'HISTORIQUE',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (history.isEmpty)
          ClipPath(
            clipper: const DiagonalCutClipper(cut: 10),
            child: Container(
              width: double.infinity,
              color: AppTheme.valorantSurface,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: const Text(
                'Aucune partie pour l\'instant. Lance-en une, le résultat s\'affichera ici.',
                style: TextStyle(fontSize: 12, color: AppTheme.valorantMuted, height: 1.4),
              ),
            ),
          )
        else
          for (final run in history) ...[
            _HistoryRow(run: run),
            const SizedBox(height: 6),
          ],
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.run});

  final QuizRun run;

  Color get _color => switch (run.ratio) {
    >= 0.8 => _goodColor,
    >= 0.5 => const Color(0xFFF2B90C),
    _ => AppTheme.valorantRed,
  };

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const DiagonalCutClipper(cut: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.valorantSurface,
          border: Border(left: BorderSide(color: _color, width: 3)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    run.label.toUpperCase(),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${run.kind.label} · ${run.modeLabel} · ${_formatDate(run.playedAt)}',
                    style: const TextStyle(fontSize: 10.5, color: AppTheme.valorantMuted),
                  ),
                ],
              ),
            ),
            Text(
              '${run.score} / ${run.maxScore}',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: _color),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month à ${hour}h$minute';
}
