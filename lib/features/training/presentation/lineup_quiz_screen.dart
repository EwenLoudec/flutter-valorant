import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../domain/lineup_quiz.dart';
import '../domain/map_quiz.dart';
import '../domain/quiz_run.dart';
import '../providers/training_providers.dart';
import 'quiz_map_board.dart';

const _goodColor = Color(0xFF2FBF8F);

/// Tap where each throw lands, then see how far off it was.
class LineupQuizScreen extends ConsumerStatefulWidget {
  const LineupQuizScreen({super.key, required this.buildRound});

  final LineupQuizRound Function() buildRound;

  @override
  ConsumerState<LineupQuizScreen> createState() => _LineupQuizScreenState();
}

class _LineupQuizScreenState extends ConsumerState<LineupQuizScreen> {
  late LineupQuizRound _round = widget.buildRound();
  int _index = 0;
  Offset? _tap;
  CalloutAnswer? _answer;
  final _answers = <CalloutAnswer>[];
  bool _isFinished = false;
  bool _isRecord = false;

  int get _score => _answers.fold(0, (sum, answer) => sum + answer.points);

  void _validate() {
    final tap = _tap;
    if (tap == null || _answer != null) return;
    final answer = _round.questions[_index].judge(tap);
    setState(() {
      _answer = answer;
      _answers.add(answer);
    });
  }

  Future<void> _next() async {
    if (_index + 1 < _round.questions.length) {
      setState(() {
        _index++;
        _tap = null;
        _answer = null;
      });
      return;
    }

    final isRecord = await ref.read(quizProgressProvider.notifier).record(
      QuizRun(
        kind: QuizKind.lineup,
        label: 'Lineups',
        mode: 'placement',
        score: _score,
        maxScore: _round.maxScore,
        playedAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _isFinished = true;
      _isRecord = isRecord;
    });
  }

  void _restart() {
    setState(() {
      _round = widget.buildRound();
      _index = 0;
      _tap = null;
      _answer = null;
      _answers.clear();
      _isFinished = false;
      _isRecord = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_round.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('QUIZ LINEUPS')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Aucun lancer à placer pour l\'instant : il faut des spots avec un point d\'arrivée.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      );
    }

    final question = _round.questions[_index];
    final answer = _answer;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isFinished ? 'RÉSULTAT' : 'LANCER ${_index + 1} / ${_round.questions.length}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$_score PTS',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.valorantRed),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: _isFinished
            ? [_buildResult()]
            : [
                Text(
                  question.map.displayName.toUpperCase(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.valorantMuted),
                ),
                const SizedBox(height: 4),
                Text(question.prompt, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, height: 1.35)),
                const SizedBox(height: 12),
                QuizMapBoard(
                  map: question.map,
                  onTapPosition: answer == null ? (position) => setState(() => _tap = position) : null,
                  guess: _tap,
                  target: answer == null ? null : question.target,
                  isCorrect: answer?.isPerfect ?? false,
                ),
                const SizedBox(height: 12),
                if (answer == null)
                  FilledButton(
                    onPressed: _tap == null ? null : _validate,
                    style: _buttonStyle,
                    child: Text(
                      _tap == null ? 'TOUCHE LE PLAN' : 'VALIDER',
                      style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                  )
                else ...[
                  _Verdict(answer: answer, title: question.lineup.lineup.title),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: _next,
                    style: _buttonStyle,
                    child: Text(
                      _index + 1 < _round.questions.length ? 'LANCER SUIVANT' : 'VOIR LE RÉSULTAT',
                      style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ],
      ),
    );
  }

  static final _buttonStyle = FilledButton.styleFrom(
    backgroundColor: AppTheme.valorantRed,
    foregroundColor: Colors.white,
    disabledBackgroundColor: AppTheme.valorantSurface,
    disabledForegroundColor: Colors.white38,
    shape: const RoundedRectangleBorder(),
    padding: const EdgeInsets.symmetric(vertical: 14),
  );

  Widget _buildResult() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipPath(
          clipper: const DiagonalCutClipper(cut: 12),
          child: Container(
            color: AppTheme.valorantSurface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isRecord)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'NOUVEAU RECORD',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: _goodColor),
                    ),
                  ),
                Text(
                  '$_score / ${_round.maxScore} pts',
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                for (final (index, answer) in _answers.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${index + 1}. ${_round.questions[index].lineup.lineup.title} — ${answer.verdict} (+${answer.points})',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _restart,
          style: _buttonStyle,
          child: const Text('REJOUER', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: const BorderSide(color: AppTheme.outlineDark),
            shape: const RoundedRectangleBorder(),
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
          child: const Text('RETOUR', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
        ),
      ],
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({required this.answer, required this.title});

  final CalloutAnswer answer;
  final String title;

  @override
  Widget build(BuildContext context) {
    final color = answer.points >= 70
        ? _goodColor
        : answer.points > 0
        ? const Color(0xFFF2B90C)
        : AppTheme.valorantRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        '${answer.verdict} : +${answer.points} points. C\'était « $title ».',
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.4),
      ),
    );
  }
}
