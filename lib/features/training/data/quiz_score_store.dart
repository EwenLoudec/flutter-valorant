import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/daily_challenge.dart';
import '../domain/quiz_run.dart';

/// Best scores and past games, kept on the device so progress survives the
/// app being closed.
class QuizScoreStore {
  static const _bestKey = 'training.map_quiz_best';
  static const _historyKey = 'training.map_quiz_history';
  static const _dailyDayKey = 'training.daily_last_day';
  static const _dailyLengthKey = 'training.daily_streak';
  static const _dailyScoreKey = 'training.daily_last_score';

  /// Older games are dropped: the list is there to show a trend, not an
  /// archive. The limit applies to each exercise, so playing one quiz never
  /// pushes another one's games out.
  static const historyLimit = 25;

  /// Keeps the [historyLimit] most recent games of each exercise, in order.
  static List<QuizRun> trimHistory(List<QuizRun> history) {
    final kept = <QuizKind, int>{};
    return [
      for (final run in history)
        if ((kept[run.kind] = (kept[run.kind] ?? 0) + 1) <= historyLimit) run,
    ];
  }

  Future<Map<String, int>> loadBestScores() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_bestKey);
    if (raw == null) return const {};

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return const {};

    return {
      for (final entry in decoded.entries)
        if (entry.value is int) entry.key: entry.value as int,
    };
  }

  Future<void> saveBestScores(Map<String, int> bestScores) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_bestKey, jsonEncode(bestScores));
  }

  Future<List<QuizRun>> loadHistory() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getStringList(_historyKey) ?? const <String>[];

    return [
      for (final raw in stored)
        if (jsonDecode(raw) case final Map<String, dynamic> json) QuizRun.fromJson(json),
    ];
  }

  Future<void> saveHistory(List<QuizRun> history) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_historyKey, [
      for (final run in trimHistory(history)) jsonEncode(run.toJson()),
    ]);
  }

  Future<DailyStreak> loadDailyStreak() async {
    final preferences = await SharedPreferences.getInstance();
    return DailyStreak(
      lastDay: preferences.getString(_dailyDayKey),
      length: preferences.getInt(_dailyLengthKey) ?? 0,
      lastScore: preferences.getInt(_dailyScoreKey),
    );
  }

  Future<void> saveDailyStreak(DailyStreak streak) async {
    final preferences = await SharedPreferences.getInstance();
    final lastDay = streak.lastDay;
    if (lastDay == null) {
      await preferences.remove(_dailyDayKey);
    } else {
      await preferences.setString(_dailyDayKey, lastDay);
    }
    await preferences.setInt(_dailyLengthKey, streak.length);
    final lastScore = streak.lastScore;
    if (lastScore != null) await preferences.setInt(_dailyScoreKey, lastScore);
  }
}
