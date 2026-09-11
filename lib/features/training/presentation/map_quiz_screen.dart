import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../encyclopedia/domain/game_map.dart';
import '../domain/map_quiz.dart';
import '../domain/quiz_run.dart';
import '../providers/training_providers.dart';
import 'quiz_map_board.dart';
import 'quiz_result_view.dart';

/// The exercise: recognise the plan, then drop each callout where it belongs.
class MapQuizScreen extends ConsumerStatefulWidget {
  const MapQuizScreen({
    super.key,
    required this.map,
    required this.allMapNames,
    this.asksMapName = true,
  });

  final GameMap map;
  final List<String> allMapNames;

  /// False when the player chose the map: its name is no longer a question.
  final bool asksMapName;

  @override
  ConsumerState<MapQuizScreen> createState() => _MapQuizScreenState();
}

class _MapQuizScreenState extends ConsumerState<MapQuizScreen> {
  late MapQuizRound _round = _newRound();

  String? _mapGuess;
  int _questionIndex = 0;
  Offset? _pendingTap;
  CalloutAnswer? _revealed;
  final _answers = <CalloutAnswer>[];
  bool _isFinished = false;
  bool _isRecord = false;

  MapQuizRound _newRound() {
    return MapQuizRound.create(
      map: widget.map,
      otherMapNames: widget.allMapNames,
      asksMapName: widget.asksMapName,
    );
  }

  bool get _hasGuessedMap => !widget.asksMapName || _mapGuess != null;
  bool get _isMapGuessRight => widget.asksMapName && _mapGuess == widget.map.displayName;

  int get _score {
    final mapPoints = _isMapGuessRight ? MapQuizRound.pointsPerMap : 0;
    final locked = _answers.fold(mapPoints, (total, answer) => total + answer.points);
    // The answer being shown counts straight away, so the total moves with
    // the feedback rather than one step later.
    return locked + (_revealed?.points ?? 0);
  }

  void _restart() {
    setState(() {
      _round = _newRound();
      _mapGuess = null;
      _questionIndex = 0;
      _pendingTap = null;
      _revealed = null;
      _answers.clear();
      _isFinished = false;
      _isRecord = false;
    });
  }

  void _validate() {
    final tap = _pendingTap;
    if (tap == null) return;

    setState(() => _revealed = MapQuizRound.judge(_round.questions[_questionIndex], tap));
  }

  Future<void> _next() async {
    final answer = _revealed;
    if (answer == null) return;

    _answers.add(answer);

    if (_questionIndex + 1 >= _round.questions.length) {
      final isRecord = await ref.read(quizProgressProvider.notifier).record(
        QuizRun(
          kind: QuizKind.map,
          label: widget.map.displayName,
          mode: widget.asksMapName ? 'full' : 'focus',
          score: _score,
          maxScore: _round.maxScore,
          playedAt: DateTime.now(),
        ),
      );
      if (!mounted) return;

      setState(() {
        _isFinished = true;
        _isRecord = isRecord;
        _revealed = null;
        _pendingTap = null;
      });
      return;
    }

    setState(() {
      _questionIndex++;
      _pendingTap = null;
      _revealed = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_hasGuessedMap ? widget.map.displayName.toUpperCase() : 'QUELLE CARTE ?'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$_score PTS',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.valorantRed,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          QuizMapBoard(
            map: widget.map,
            onTapPosition: _hasGuessedMap && !_isFinished && _revealed == null
                ? (position) => setState(() => _pendingTap = position)
                : null,
            guess: _isFinished ? null : _pendingTap,
            target: _revealed == null ? null : _round.questions[_questionIndex].target,
            isCorrect: _revealed?.isPerfect ?? false,
          ),
          const SizedBox(height: 16),
          if (_isFinished)
            QuizResultView(
              round: _round,
              answers: _answers,
              score: _score,
              isMapGuessRight: _isMapGuessRight,
              isRecord: _isRecord,
              onReplay: _restart,
              onLeave: () => Navigator.of(context).pop(),
            )
          else if (!_hasGuessedMap)
            _MapGuessStep(round: _round, onPick: (name) => setState(() => _mapGuess = name))
          else
            _CalloutStep(
              round: _round,
              index: _questionIndex,
              hasTapped: _pendingTap != null,
              answer: _revealed,
              justFoundMap:
                  widget.asksMapName && _questionIndex == 0 && _answers.isEmpty && _revealed == null,
              isMapGuessRight: _isMapGuessRight,
              mapName: widget.map.displayName,
              onValidate: _validate,
              onNext: _next,
            ),
        ],
      ),
    );
  }
}

/// Step one: four names, one plan.
class _MapGuessStep extends StatelessWidget {
  const _MapGuessStep({required this.round, required this.onPick});

  final MapQuizRound round;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Prompt(
          step: '1 / 2',
          title: 'Reconnais la carte',
          detail: 'Le plan est affiché sans aucun nom. Choisis la bonne carte.',
        ),
        const SizedBox(height: 14),
        for (final name in round.mapChoices) ...[
          OutlinedButton(
            onPressed: () => onPick(name),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: AppTheme.outlineDark),
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              name.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Step two: place one callout at a time.
class _CalloutStep extends StatelessWidget {
  const _CalloutStep({
    required this.round,
    required this.index,
    required this.hasTapped,
    required this.answer,
    required this.justFoundMap,
    required this.isMapGuessRight,
    required this.mapName,
    required this.onValidate,
    required this.onNext,
  });

  final MapQuizRound round;
  final int index;
  final bool hasTapped;
  final CalloutAnswer? answer;
  final bool justFoundMap;
  final bool isMapGuessRight;
  final String mapName;
  final VoidCallback onValidate;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final question = round.questions[index];
    final answer = this.answer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (justFoundMap) ...[
          _Banner(
            isGood: isMapGuessRight,
            text: isMapGuessRight
                ? 'Bien vu, c\'est $mapName. +${MapQuizRound.pointsPerMap} points.'
                : 'Raté : c\'était $mapName. 0 point pour la carte.',
          ),
          const SizedBox(height: 14),
        ],
        _Prompt(
          step: round.asksMapName
              ? '2 / 2 · ${index + 1} sur ${round.questions.length}'
              : 'Callout ${index + 1} sur ${round.questions.length}',
          title: 'Place « ${question.label} »',
          detail: 'Touche le plan à l\'endroit exact, puis valide.',
        ),
        const SizedBox(height: 14),
        if (answer == null)
          FilledButton(
            onPressed: hasTapped ? onValidate : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.valorantRed,
              disabledBackgroundColor: AppTheme.valorantSurface,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white24,
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              hasTapped ? 'VALIDER' : 'TOUCHE LE PLAN',
              style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
          )
        else ...[
          _Banner(
            isGood: answer.points >= 70,
            text:
                '${answer.verdict} — ${(answer.distance * 100).toStringAsFixed(0)} % '
                'de la carte d\'écart. +${answer.points} points.',
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.valorantRed,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              index + 1 >= round.questions.length ? 'VOIR LE RÉSULTAT' : 'CALLOUT SUIVANT',
              style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
          ),
        ],
      ],
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.step, required this.title, required this.detail});

  final String step;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          step.toUpperCase(),
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppTheme.valorantRed),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
        const SizedBox(height: 4),
        Text(detail, style: const TextStyle(fontSize: 12, color: AppTheme.valorantMuted, height: 1.4)),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.isGood, required this.text});

  final bool isGood;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = isGood ? const Color(0xFF2FBF8F) : AppTheme.valorantRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(isGood ? Icons.check_circle_outline : Icons.error_outline, size: 17, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
