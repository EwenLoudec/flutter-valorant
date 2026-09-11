import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybmw/features/training/domain/quiz_run.dart';

void main() {
  group('QuizRun', () {
    final run = QuizRun(
      mapName: 'Ascent',
      score: 480,
      maxScore: 700,
      askedMapName: true,
      playedAt: DateTime(2026, 9, 11, 21, 30),
    );

    test('survit à un aller-retour dans le stockage', () {
      final restored = QuizRun.fromJson(jsonDecode(jsonEncode(run.toJson())) as Map<String, dynamic>);

      expect(restored.mapName, 'Ascent');
      expect(restored.score, 480);
      expect(restored.maxScore, 700);
      expect(restored.askedMapName, isTrue);
      expect(restored.playedAt, DateTime(2026, 9, 11, 21, 30));
    });

    test('sépare les records des deux modes', () {
      final focused = QuizRun(
        mapName: 'Ascent',
        score: 480,
        maxScore: 600,
        askedMapName: false,
        playedAt: run.playedAt,
      );

      expect(run.modeKey, 'Ascent|full');
      expect(focused.modeKey, 'Ascent|focus');
      expect(run.modeKey, isNot(focused.modeKey));
    });

    test('calcule le ratio pour la couleur de la ligne', () {
      expect(run.ratio, closeTo(480 / 700, 0.001));
      expect(
        QuizRun(
          mapName: 'Bind',
          score: 0,
          maxScore: 0,
          askedMapName: true,
          playedAt: DateTime(2026),
        ).ratio,
        0,
      );
    });
  });
}
