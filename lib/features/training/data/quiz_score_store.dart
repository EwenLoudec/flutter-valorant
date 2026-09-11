import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/quiz_run.dart';

/// Best scores and past games, kept on the device so progress survives the
/// app being closed.
class QuizScoreStore {
  static const _bestKey = 'training.map_quiz_best';
  static const _historyKey = 'training.map_quiz_history';

  /// Older games are dropped: the list is there to show a trend, not an
  /// archive.
  static const historyLimit = 25;

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
      for (final run in history.take(historyLimit)) jsonEncode(run.toJson()),
    ]);
  }
}
