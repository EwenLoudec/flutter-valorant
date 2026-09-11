import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../../encyclopedia/domain/agent.dart';
import '../../encyclopedia/providers/encyclopedia_providers.dart';
import '../domain/agent_quiz.dart';
import '../domain/quiz_run.dart';
import '../providers/training_providers.dart';
import 'agent_quiz_screen.dart';
import 'quiz_history_view.dart';

/// Launcher of the agent exercise: what it asks, your record, and the past
/// games.
class AgentQuizPage extends ConsumerWidget {
  const AgentQuizPage({super.key});

  static const _maxScore = AgentQuizRound.defaultQuestionCount * AgentQuizRound.pointsPerQuestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agents = ref.watch(agentsProvider).value ?? const <Agent>[];
    final soundsAsync = ref.watch(abilitySoundsProvider);
    final sounds = soundsAsync.value ?? const <String, Map<String, String>>{};
    final progress = ref.watch(quizProgressProvider).value;
    final bestScore = progress?.bestForAgents;

    // Starting before the clips are in would silently drop the sound
    // questions from the whole run.
    final isReady = agents.length >= 4 && soundsAsync.hasValue;

    final history = [
      for (final run in progress?.history ?? const <QuizRun>[])
        if (run.kind == QuizKind.agent) run,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('ENTRAÎNEMENT AGENTS')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Dix questions tirées au hasard : reconnaître un agent à son portrait, nommer '
              'une compétence sur son icône, retrouver son propriétaire, l\'identifier depuis '
              'sa description officielle… et surtout la reconnaître à l\'oreille — on te passe '
              'le son du jeu, tu dis à qui il appartient, puis de quelle capacité il s\'agit.',
              style: TextStyle(fontSize: 12.5, color: AppTheme.valorantMuted, height: 1.45),
            ),
          ),
          const SizedBox(height: 14),
          ClipPath(
            clipper: const DiagonalCutClipper(cut: 10),
            child: Container(
              color: AppTheme.valorantSurface,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_outlined, size: 18, color: AppTheme.valorantMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bestScore == null ? 'Aucun record pour l\'instant' : 'Record : $bestScore / $_maxScore',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: bestScore == null ? AppTheme.valorantMuted : AppTheme.valorantRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: !isReady
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AgentQuizScreen(agents: agents, soundsByAgent: sounds),
                    ),
                  ),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.valorantRed,
              disabledBackgroundColor: AppTheme.valorantSurface,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white24,
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: Icon(isReady ? Icons.play_arrow_rounded : Icons.hourglass_empty, size: 22),
            label: Text(
              isReady ? 'LANCER UNE PARTIE' : 'CHARGEMENT DES SONS…',
              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.6, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          QuizHistoryView(history: history),
        ],
      ),
    );
  }
}
