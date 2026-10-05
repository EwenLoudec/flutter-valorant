import 'dart:math';

/// The day's challenge: the same draw for everyone on a given date, since the
/// questions come from a generator seeded with that date.
abstract final class DailyChallenge {
  static const questionCount = 10;

  /// `2026-10-05` -> 20261005.
  static int seedFor(DateTime date) => date.year * 10000 + date.month * 100 + date.day;

  static Random randomFor(DateTime date) => Random(seedFor(date));

  /// A date as `yyyy-mm-dd`, the key the streak is kept under.
  static String dayKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

/// How many days in a row the challenge was completed.
class DailyStreak {
  const DailyStreak({this.lastDay, this.length = 0, this.lastScore});

  /// [DailyChallenge.dayKey] of the last completed challenge.
  final String? lastDay;
  final int length;

  /// The score of that last challenge, to show it once done.
  final int? lastScore;

  bool isDoneOn(DateTime date) => lastDay == DailyChallenge.dayKey(date);

  /// The streak as it stands on [date]: it is lost once a whole day was
  /// skipped.
  int lengthOn(DateTime date) {
    if (lastDay == null) return 0;
    final today = DailyChallenge.dayKey(date);
    final yesterday = DailyChallenge.dayKey(DateTime(date.year, date.month, date.day - 1));
    return lastDay == today || lastDay == yesterday ? length : 0;
  }

  /// The streak after completing the challenge of [date] with [score]. A
  /// second run the same day changes nothing.
  DailyStreak complete(DateTime date, int score) {
    final today = DailyChallenge.dayKey(date);
    if (lastDay == today) return this;

    final yesterday = DailyChallenge.dayKey(DateTime(date.year, date.month, date.day - 1));
    return DailyStreak(lastDay: today, length: lastDay == yesterday ? length + 1 : 1, lastScore: score);
  }
}
