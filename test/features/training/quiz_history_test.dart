import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_companion/features/training/data/quiz_score_store.dart';
import 'package:valorant_companion/features/training/domain/quiz_run.dart';

QuizRun _run(QuizKind kind, int index) => QuizRun(
  kind: kind,
  label: kind.label,
  mode: 'mixed',
  score: index,
  maxScore: 100,
  playedAt: DateTime(2026, 10, 5).subtract(Duration(minutes: index)),
);

void main() {
  test('each exercise keeps its own last games', () {
    final history = [
      for (var index = 0; index < 40; index++) _run(QuizKind.weapon, index),
      for (var index = 0; index < 10; index++) _run(QuizKind.map, index),
    ];

    final trimmed = QuizScoreStore.trimHistory(history);

    expect(trimmed.where((run) => run.kind == QuizKind.weapon), hasLength(QuizScoreStore.historyLimit));
    expect(trimmed.where((run) => run.kind == QuizKind.map), hasLength(10), reason: 'weapon games must not push map games out');
    expect(trimmed.first.score, 0, reason: 'most recent first, order kept');
    expect(trimmed.where((run) => run.kind == QuizKind.weapon).last.score, QuizScoreStore.historyLimit - 1);
  });
}
