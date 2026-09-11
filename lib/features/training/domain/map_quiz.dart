import 'dart:math';
import 'dart:ui';

import '../../encyclopedia/domain/game_map.dart';

/// A callout to place on the plan, and where it really is.
class CalloutQuestion {
  const CalloutQuestion({required this.label, required this.superRegion, required this.target});

  final String label;
  final String superRegion;

  /// Fractional (0-1) position on the minimap image.
  final Offset target;
}

/// What the player tapped for one question, and what it was worth.
class CalloutAnswer {
  const CalloutAnswer({required this.tap, required this.distance, required this.points});

  final Offset tap;

  /// Distance between the tap and the truth, in fractions of the map.
  final double distance;
  final int points;

  bool get isPerfect => points == MapQuizRound.pointsPerCallout;

  String get verdict => switch (points) {
    MapQuizRound.pointsPerCallout => 'Parfait',
    >= 70 => 'Tout proche',
    >= 40 => 'Dans la zone',
    > 0 => 'Loin',
    _ => 'Raté',
  };
}

/// One game: optionally recognise the map, then place a handful of callouts
/// drawn afresh every time.
class MapQuizRound {
  const MapQuizRound({
    required this.map,
    required this.mapChoices,
    required this.questions,
    required this.asksMapName,
  });

  static const pointsPerMap = 100;
  static const pointsPerCallout = 100;

  /// Below this distance the answer is spot on; above the second one it is
  /// worth nothing. In between the score fades linearly.
  static const _perfectDistance = 0.045;
  static const _missDistance = 0.22;

  /// Spawns are excluded: they are giveaways and read badly as a question.
  static const _playableRegions = {'A', 'B', 'C', 'Mid'};

  static const defaultQuestionCount = 6;

  factory MapQuizRound.create({
    required GameMap map,
    required List<String> otherMapNames,
    bool asksMapName = true,
    int questionCount = defaultQuestionCount,
    Random? random,
  }) {
    final shuffler = random ?? Random();

    final byLabel = <String, CalloutQuestion>{};
    for (final callout in map.callouts) {
      if (!_playableRegions.contains(callout.superRegionName)) continue;

      final label = '${callout.superRegionName} ${callout.regionName}';
      byLabel.putIfAbsent(
        label,
        () => CalloutQuestion(
          label: label,
          superRegion: callout.superRegionName,
          target: map.normalizedPosition(callout),
        ),
      );
    }

    final others = [...otherMapNames.where((name) => name != map.displayName)]..shuffle(shuffler);
    final choices = [map.displayName, ...others.take(3)]..shuffle(shuffler);

    return MapQuizRound(
      map: map,
      mapChoices: choices,
      questions: _spreadOverSites(byLabel.values.toList(), questionCount, shuffler),
      asksMapName: asksMapName,
    );
  }

  /// Draws the questions round-robin across A / B / C / Mid, so a game never
  /// ends up entirely in one corner of the plan.
  static List<CalloutQuestion> _spreadOverSites(List<CalloutQuestion> pool, int count, Random shuffler) {
    final bySite = <String, List<CalloutQuestion>>{};
    for (final question in pool) {
      bySite.putIfAbsent(question.superRegion, () => []).add(question);
    }

    final sites = bySite.keys.toList()..shuffle(shuffler);
    for (final questions in bySite.values) {
      questions.shuffle(shuffler);
    }

    final picked = <CalloutQuestion>[];
    while (picked.length < count && bySite.values.any((questions) => questions.isNotEmpty)) {
      for (final site in sites) {
        final questions = bySite[site]!;
        if (questions.isEmpty) continue;

        picked.add(questions.removeLast());
        if (picked.length == count) break;
      }
    }

    return picked..shuffle(shuffler);
  }

  final GameMap map;
  final List<String> mapChoices;
  final List<CalloutQuestion> questions;

  /// False when the player picked the map themselves — asking its name then
  /// would be a free point.
  final bool asksMapName;

  int get maxScore => (asksMapName ? pointsPerMap : 0) + questions.length * pointsPerCallout;

  /// Turns a tap into a score: dead on is worth everything, and the value
  /// fades with the distance rather than being right or wrong.
  static CalloutAnswer judge(CalloutQuestion question, Offset tap) {
    final distance = (tap - question.target).distance;

    final points = switch (distance) {
      <= _perfectDistance => pointsPerCallout,
      >= _missDistance => 0,
      _ =>
        ((1 - (distance - _perfectDistance) / (_missDistance - _perfectDistance)) * pointsPerCallout).round(),
    };

    return CalloutAnswer(tap: tap, distance: distance, points: points);
  }
}
