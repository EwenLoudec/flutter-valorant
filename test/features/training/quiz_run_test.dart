import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybmw/features/training/domain/quiz_run.dart';

void main() {
  group('QuizRun', () {
    final run = QuizRun(
      kind: QuizKind.map,
      label: 'Ascent',
      mode: 'full',
      score: 480,
      maxScore: 700,
      playedAt: DateTime(2026, 9, 11, 21, 30),
    );

    test('survit à un aller-retour dans le stockage', () {
      final restored = QuizRun.fromJson(jsonDecode(jsonEncode(run.toJson())) as Map<String, dynamic>);

      expect(restored.kind, QuizKind.map);
      expect(restored.label, 'Ascent');
      expect(restored.mode, 'full');
      expect(restored.score, 480);
      expect(restored.maxScore, 700);
      expect(restored.playedAt, DateTime(2026, 9, 11, 21, 30));
    });

    test('relit une partie enregistrée avant le quiz agents', () {
      final restored = QuizRun.fromJson({
        'map': 'Bind',
        'score': 300,
        'max': 600,
        'full': false,
        'at': '2026-09-10T18:00:00.000',
      });

      expect(restored.kind, QuizKind.map);
      expect(restored.label, 'Bind');
      expect(restored.mode, 'focus');
      expect(restored.modeKey, 'Bind|focus', reason: 'la clé historique des cartes ne doit pas bouger');
    });

    test('sépare les records des modes et des exercices', () {
      final focused = QuizRun(
        kind: QuizKind.map,
        label: 'Ascent',
        mode: 'focus',
        score: 480,
        maxScore: 600,
        playedAt: run.playedAt,
      );
      final agents = QuizRun(
        kind: QuizKind.agent,
        label: 'Agents',
        mode: 'mixed',
        score: 700,
        maxScore: 1000,
        playedAt: run.playedAt,
      );

      expect(run.modeKey, 'Ascent|full');
      expect(focused.modeKey, 'Ascent|focus');
      expect(agents.modeKey, 'agent|Agents|mixed');
      expect({run.modeKey, focused.modeKey, agents.modeKey}, hasLength(3));
    });

    test('affiche le mode en clair', () {
      expect(run.modeLabel, 'Partie complète');
      expect(run.kind.label, 'Cartes');
      expect(
        QuizRun(
          kind: QuizKind.agent,
          label: 'Agents',
          mode: 'mixed',
          score: 0,
          maxScore: 1000,
          playedAt: run.playedAt,
        ).modeLabel,
        'Questions mêlées',
      );
    });

    test('calcule le ratio pour la couleur de la ligne', () {
      expect(run.ratio, closeTo(480 / 700, 0.001));
      expect(
        QuizRun(
          kind: QuizKind.map,
          label: 'Bind',
          mode: 'full',
          score: 0,
          maxScore: 0,
          playedAt: DateTime(2026),
        ).ratio,
        0,
      );
    });
  });
}
