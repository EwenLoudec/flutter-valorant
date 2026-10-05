import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ability_sound_source.dart';
import '../data/quiz_score_store.dart';
import '../domain/daily_challenge.dart';
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

  int? bestForMap(String mapName, {required bool askedMapName}) {
    return bestScores['$mapName|${askedMapName ? 'full' : 'focus'}'];
  }

  /// The agent exercise has a single mode.
  int? get bestForAgents => bestScores['${QuizKind.agent.code}|Agents|mixed'];

  /// Best score of any non-map exercise, keyed like [QuizRun.modeKey].
  int? bestFor(QuizKind kind, String label, String mode) => bestScores['${kind.code}|$label|$mode'];
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

    final history = QuizScoreStore.trimHistory([run, ...current.history]);
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

final abilitySoundSourceProvider = Provider<AbilitySoundSource>((ref) => AbilitySoundSource());

/// The ability clips with real sound, for the listening questions.
final abilitySoundsProvider = FutureProvider<Map<String, Map<String, String>>>((ref) {
  return ref.watch(abilitySoundSourceProvider).getSoundsByAgent();
});

/// The days-in-a-row count of the daily challenge.
class DailyStreakNotifier extends AsyncNotifier<DailyStreak> {
  @override
  Future<DailyStreak> build() => ref.read(quizScoreStoreProvider).loadDailyStreak();

  /// Files the day's challenge. Returns the streak afterwards.
  Future<DailyStreak> complete(DateTime date, int score) async {
    final current = state.value ?? const DailyStreak();
    final updated = current.complete(date, score);
    if (identical(updated, current)) return current;

    state = AsyncData(updated);
    await ref.read(quizScoreStoreProvider).saveDailyStreak(updated);
    return updated;
  }
}

final dailyStreakProvider = AsyncNotifierProvider<DailyStreakNotifier, DailyStreak>(DailyStreakNotifier.new);
