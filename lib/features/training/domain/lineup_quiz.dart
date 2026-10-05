import 'dart:math';
import 'dart:ui';

import '../../encyclopedia/domain/game_map.dart';
import '../../lineups/domain/resolved_lineup.dart';
import 'map_quiz.dart';

/// One throw to place: where does this utility land?
class LineupQuestion {
  const LineupQuestion({required this.map, required this.lineup});

  final GameMap map;
  final ResolvedLineup lineup;

  Offset get target => lineup.to!;

  String get prompt {
    final spot = lineup.lineup;
    final ability = spot.abilityName.isEmpty ? 'l\'utilitaire' : spot.abilityName;
    return 'Où atterrit $ability de ${spot.agentName}, lancé depuis ${spot.from.label} ?';
  }

  /// Scored like the callout game: dead on is worth everything, then the
  /// value fades with the distance.
  CalloutAnswer judge(Offset tap) {
    return MapQuizRound.judge(CalloutQuestion(label: lineup.lineup.title, superRegion: '', target: target), tap);
  }
}

/// A handful of throws drawn across the maps.
class LineupQuizRound {
  const LineupQuizRound({required this.questions});

  static const defaultQuestionCount = 5;

  /// Only throws qualify: a placement has no landing point to find. At most
  /// two questions per map, so a run travels.
  factory LineupQuizRound.create({
    required Map<GameMap, List<ResolvedLineup>> lineupsByMap,
    int questionCount = defaultQuestionCount,
    Random? random,
  }) {
    final shuffler = random ?? Random();
    final pool = <LineupQuestion>[
      for (final entry in lineupsByMap.entries)
        for (final lineup in entry.value)
          if (lineup.to != null) LineupQuestion(map: entry.key, lineup: lineup),
    ]..shuffle(shuffler);

    final perMap = <String, int>{};
    final seenTargets = <String>{};
    final picked = <LineupQuestion>[];
    for (final question in pool) {
      if (picked.length == questionCount) break;
      final mapName = question.map.displayName;
      if ((perMap[mapName] ?? 0) >= 2) continue;
      // Two spots aimed at the same callout would be the same question.
      final targetKey = '$mapName|${question.target.dx.toStringAsFixed(3)}|${question.target.dy.toStringAsFixed(3)}';
      if (!seenTargets.add(targetKey)) continue;

      perMap[mapName] = (perMap[mapName] ?? 0) + 1;
      picked.add(question);
    }
    return LineupQuizRound(questions: picked);
  }

  final List<LineupQuestion> questions;

  int get maxScore => questions.length * MapQuizRound.pointsPerCallout;
}
