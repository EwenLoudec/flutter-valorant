import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../core/widgets/fade_in_network_image.dart';
import '../../encyclopedia/domain/agent.dart';
import '../domain/agent_quiz.dart';
import '../domain/quiz_run.dart';
import '../providers/training_providers.dart';
import 'ability_sound_player.dart';

const _goodColor = Color(0xFF2FBF8F);

/// Ten mixed questions on the agents: portraits, ability icons, official
/// descriptions and ability sounds.
class AgentQuizScreen extends ConsumerStatefulWidget {
  const AgentQuizScreen({super.key, required this.agents, required this.soundsByAgent});

  final List<Agent> agents;
  final Map<String, Map<String, String>> soundsByAgent;

  @override
  ConsumerState<AgentQuizScreen> createState() => _AgentQuizScreenState();
}

class _AgentQuizScreenState extends ConsumerState<AgentQuizScreen> {
  late AgentQuizRound _round = _newRound();

  int _index = 0;
  String? _picked;
  int _score = 0;
  bool _isFinished = false;
  bool _isRecord = false;
  final _correct = <bool>[];

  AgentQuizRound _newRound() {
    return AgentQuizRound.create(agents: widget.agents, soundsByAgent: widget.soundsByAgent);
  }

  void _restart() {
    setState(() {
      _round = _newRound();
      _index = 0;
      _picked = null;
      _score = 0;
      _isFinished = false;
      _isRecord = false;
      _correct.clear();
    });
  }

  void _pick(String choice) {
    if (_picked != null) return;

    final isRight = choice == _round.questions[_index].answer;
    setState(() {
      _picked = choice;
      _correct.add(isRight);
      if (isRight) _score += AgentQuizRound.pointsPerQuestion;
    });
  }

  Future<void> _next() async {
    if (_index + 1 < _round.questions.length) {
      setState(() {
        _index++;
        _picked = null;
      });
      return;
    }

    final isRecord = await ref.read(quizProgressProvider.notifier).record(
      QuizRun(
        kind: QuizKind.agent,
        label: 'Agents',
        mode: 'mixed',
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

  @override
  Widget build(BuildContext context) {
    if (_round.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('ENTRAÎNEMENT AGENTS')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final question = _round.questions[_index];
    final picked = _picked;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isFinished ? 'RÉSULTAT' : 'QUESTION ${_index + 1} / ${_round.questions.length}'),
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
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: _isFinished
            ? [
                _Result(
                  score: _score,
                  maxScore: _round.maxScore,
                  correct: _correct,
                  isRecord: _isRecord,
                  onReplay: _restart,
                  onLeave: () => Navigator.of(context).pop(),
                ),
              ]
            : [
                _QuestionCard(question: question),
                const SizedBox(height: 18),
                for (final choice in question.choices) ...[
                  _ChoiceButton(
                    label: choice,
                    state: _stateFor(choice, question.answer),
                    onTap: () => _pick(choice),
                  ),
                  const SizedBox(height: 8),
                ],
                if (picked != null) ...[
                  const SizedBox(height: 8),
                  _Reveal(question: question, isRight: picked == question.answer),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.valorantRed,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _index + 1 < _round.questions.length ? 'QUESTION SUIVANTE' : 'VOIR LE RÉSULTAT',
                      style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ],
      ),
    );
  }

  _ChoiceState _stateFor(String choice, String answer) {
    final picked = _picked;
    if (picked == null) return _ChoiceState.idle;
    if (choice == answer) return _ChoiceState.right;
    return choice == picked ? _ChoiceState.wrong : _ChoiceState.muted;
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});

  final AgentQuestion question;

  @override
  Widget build(BuildContext context) {
    final imageUrl = question.imageUrl;
    final soundUrl = question.soundUrl;
    final text = question.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          question.prompt,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 0.3),
        ),
        const SizedBox(height: 14),
        if (imageUrl != null)
          ClipPath(
            clipper: const DiagonalCutClipper(cut: 12),
            child: Container(
              height: question.kind == AgentQuestionKind.portrait ? 260 : 150,
              color: AppTheme.valorantSurface,
              padding: EdgeInsets.all(question.kind == AgentQuestionKind.portrait ? 0 : 18),
              child: FadeInNetworkImage(url: imageUrl, fit: BoxFit.contain),
            ),
          ),
        if (soundUrl != null) AbilitySoundPlayer(key: ValueKey(soundUrl), url: soundUrl),
        if (text != null)
          ClipPath(
            clipper: const DiagonalCutClipper(cut: 10),
            child: Container(
              color: AppTheme.valorantSurface,
              padding: const EdgeInsets.all(14),
              child: Text(
                text,
                style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.white70),
              ),
            ),
          ),
      ],
    );
  }
}

enum _ChoiceState { idle, right, wrong, muted }

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({required this.label, required this.state, required this.onTap});

  final String label;
  final _ChoiceState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (color, background) = switch (state) {
      _ChoiceState.idle => (Colors.white, Colors.transparent),
      _ChoiceState.right => (_goodColor, _goodColor.withValues(alpha: 0.14)),
      _ChoiceState.wrong => (AppTheme.valorantRed, AppTheme.valorantRed.withValues(alpha: 0.14)),
      _ChoiceState.muted => (Colors.white24, Colors.transparent),
    };

    return GestureDetector(
      onTap: state == _ChoiceState.idle ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: state == _ChoiceState.idle ? AppTheme.outlineDark : color),
        ),
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.4, color: color, fontSize: 12.5),
        ),
      ),
    );
  }
}

class _Reveal extends StatelessWidget {
  const _Reveal({required this.question, required this.isRight});

  final AgentQuestion question;
  final bool isRight;

  @override
  Widget build(BuildContext context) {
    final color = isRight ? _goodColor : AppTheme.valorantRed;
    // On the owner question the subject is just the agent name: repeating
    // it between brackets would say nothing more.
    final reveal = question.revealSubject;
    final subject = reveal == question.answer ? null : reveal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(isRight ? Icons.check_circle_outline : Icons.error_outline, size: 17, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isRight
                  ? 'Exact${subject == null ? '' : ' — $subject'}. +${AgentQuizRound.pointsPerQuestion} points.'
                  : 'Non : ${question.answer}${subject == null ? '' : ' ($subject)'}.',
              style: const TextStyle(fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.score,
    required this.maxScore,
    required this.correct,
    required this.isRecord,
    required this.onReplay,
    required this.onLeave,
  });

  final int score;
  final int maxScore;
  final List<bool> correct;
  final bool isRecord;
  final VoidCallback onReplay;
  final VoidCallback onLeave;

  String get _comment {
    final ratio = maxScore == 0 ? 0.0 : score / maxScore;
    if (ratio >= 0.9) return 'Tu connais le roster sur le bout des doigts.';
    if (ratio >= 0.7) return 'Bonne base — reste les compétences qui se ressemblent.';
    if (ratio >= 0.4) return 'Les agents oui, les compétences moins.';
    return 'À retravailler : passe un tour dans les fiches agents.';
  }

  @override
  Widget build(BuildContext context) {
    final rightCount = correct.where((isRight) => isRight).length;

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
                  const Row(
                    children: [
                      Icon(Icons.emoji_events_outlined, size: 16, color: _goodColor),
                      SizedBox(width: 6),
                      Text(
                        'NOUVEAU RECORD',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: _goodColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$score', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, height: 1)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 4),
                      child: Text(
                        '/ $maxScore pts',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.valorantMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$rightCount bonne(s) réponse(s) sur ${correct.length}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(_comment, style: const TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.4)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final isRight in correct) ...[
                      Icon(
                        isRight ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: isRight ? _goodColor : AppTheme.valorantRed,
                      ),
                      const SizedBox(width: 4),
                    ],
                  ],
                ),
              ],
            ),
          ),
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
          child: const Text('REJOUER', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
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
          child: const Text('RETOUR', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
        ),
      ],
    );
  }
}
