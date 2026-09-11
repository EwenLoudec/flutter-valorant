/// One finished game, kept for the history list.
class QuizRun {
  const QuizRun({
    required this.mapName,
    required this.score,
    required this.maxScore,
    required this.askedMapName,
    required this.playedAt,
  });

  factory QuizRun.fromJson(Map<String, dynamic> json) {
    return QuizRun(
      mapName: json['map'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      maxScore: json['max'] as int? ?? 0,
      askedMapName: json['full'] as bool? ?? true,
      playedAt: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  final String mapName;
  final int score;
  final int maxScore;

  /// Whether the run included the "recognise the map" leg.
  final bool askedMapName;

  final DateTime playedAt;

  /// Key under which the best score of this kind of game is kept, so a full
  /// game and a map-focused one are not compared with each other.
  String get modeKey => '$mapName|${askedMapName ? 'full' : 'focus'}';

  double get ratio => maxScore == 0 ? 0 : score / maxScore;

  Map<String, dynamic> toJson() => {
    'map': mapName,
    'score': score,
    'max': maxScore,
    'full': askedMapName,
    'at': playedAt.toIso8601String(),
  };
}
