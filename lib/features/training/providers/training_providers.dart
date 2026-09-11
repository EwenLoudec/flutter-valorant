import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quiz_score_store.dart';
import '../domain/quiz_run.dart';

final quizScoreStoreProvider = Provider<QuizScoreStore>((ref) => QuizScoreStore());

/// Everything the training tab remembers: the best score of each mode, and
/// the last games played.
class QuizProgress {
  const QuizProgress({this.bestScores = const {}, this.history = const []});

  /// `<carte>|full` or `<carte>|focus` -> best score.
  final Map<String, int> bestScores;

  /// Most recent game first.
  final List<QuizRun> history;

  int? bestFor(String mapName, {required bool askedMapName}) {
    return bestScores['$mapName|${askedMapName ? 'full' : 'focus'}'];
  }
}

class QuizProgressNotifier extends AsyncNotifier<QuizProgress> {
  @override
  Future<QuizProgress> build() async {
    final store = ref.read(quizScoreStoreProvider);
    return QuizProgress(bestScores: await store.loadBestScores(), history: await store.loadHistory());
  }

  /// Files a finished game. Returns true when it beat the previous best of
  /// that same mode.
  Future<bool> record(QuizRun run) async {
    final current = state.value ?? const QuizProgress();

    final bestScores = {...current.bestScores};
    final previous = bestScores[run.modeKey] ?? 0;
    final isRecord = run.score > previous;
    if (isRecord) bestScores[run.modeKey] = run.score;

    final history = [run, ...current.history].take(QuizScoreStore.historyLimit).toList();
    state = AsyncData(QuizProgress(bestScores: bestScores, history: history));

    final store = ref.read(quizScoreStoreProvider);
    if (isRecord) await store.saveBestScores(bestScores);
    await store.saveHistory(history);

    return isRecord;
  }
}

final quizProgressProvider = AsyncNotifierProvider<QuizProgressNotifier, QuizProgress>(
  QuizProgressNotifier.new,
);
