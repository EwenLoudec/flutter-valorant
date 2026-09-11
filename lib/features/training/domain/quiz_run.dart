/// Which exercise a run belongs to.
enum QuizKind {
  map('map', 'Cartes'),
  agent('agent', 'Agents');

  const QuizKind(this.code, this.label);

  static QuizKind fromCode(String? code) {
    return QuizKind.values.firstWhere((kind) => kind.code == code, orElse: () => QuizKind.map);
  }

  final String code;
  final String label;
}

/// One finished game, kept for the history list.
class QuizRun {
  const QuizRun({
    required this.kind,
    required this.label,
    required this.mode,
    required this.score,
    required this.maxScore,
    required this.playedAt,
  });

  /// Map runs saved before the agent quiz existed carry `full` / `focus` as a
  /// boolean and no kind at all.
  factory QuizRun.fromJson(Map<String, dynamic> json) {
    return QuizRun(
      kind: QuizKind.fromCode(json['kind'] as String?),
      label: json['map'] as String? ?? '',
      mode: json['mode'] as String? ?? ((json['full'] as bool? ?? true) ? 'full' : 'focus'),
      score: json['score'] as int? ?? 0,
      maxScore: json['max'] as int? ?? 0,
      playedAt: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  final QuizKind kind;

  /// The map name, or the agent exercise's own label.
  final String label;

  /// Tells two ways of playing the same thing apart: `full` and `focus` for
  /// the maps, `mixed` for the agents.
  final String mode;

  final int score;
  final int maxScore;
  final DateTime playedAt;

  /// Key under which the best score of this exact exercise is kept. Map runs
  /// keep their historical key so old records are not orphaned.
  String get modeKey => kind == QuizKind.map ? '$label|$mode' : '${kind.code}|$label|$mode';

  double get ratio => maxScore == 0 ? 0 : score / maxScore;

  String get modeLabel => switch (mode) {
    'full' => 'Partie complète',
    'focus' => 'Ciblé',
    _ => 'Questions mêlées',
  };

  Map<String, dynamic> toJson() => {
    'kind': kind.code,
    'map': label,
    'mode': mode,
    'score': score,
    'max': maxScore,
    'at': playedAt.toIso8601String(),
  };
}
