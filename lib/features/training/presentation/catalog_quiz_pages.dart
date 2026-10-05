import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../../encyclopedia/domain/agent.dart';
import '../../encyclopedia/domain/rank_tier.dart';
import '../../encyclopedia/domain/weapon.dart';
import '../../encyclopedia/domain/game_map.dart';
import '../../encyclopedia/providers/encyclopedia_providers.dart';
import '../../lineups/domain/resolved_lineup.dart';
import '../../lineups/providers/lineups_providers.dart';
import '../domain/catalog_quiz.dart';
import '../domain/daily_challenge.dart';
import '../domain/lineup_quiz.dart';
import '../domain/map_quiz.dart';
import '../domain/agent_quiz.dart';
import '../domain/quiz_run.dart';
import '../providers/training_providers.dart';
import 'agent_quiz_screen.dart';
import 'lineup_quiz_screen.dart';
import 'quiz_history_view.dart';

const _maxScore = CatalogQuiz.questionCount * AgentQuizRound.pointsPerQuestion;

/// Weapons by their silhouette or one of their skins.
class WeaponQuizPage extends ConsumerWidget {
  const WeaponQuizPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weapons = ref.watch(weaponsProvider).value ?? const <Weapon>[];

    return _QuizLauncher(
      title: 'ENTRAÎNEMENT ARMES',
      description: 'Dix questions : reconnaître une arme à sa seule silhouette, ou retrouver à quelle '
          'arme appartient un skin.',
      kind: QuizKind.weapon,
      label: 'Armes',
      mode: 'mixed',
      isReady: weapons.length >= 4,
      onStart: (context) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AgentQuizScreen(
            title: 'ENTRAÎNEMENT ARMES',
            kind: QuizKind.weapon,
            label: 'Armes',
            roundBuilder: () => CatalogQuiz.weapons(weapons: weapons),
          ),
        ),
      ),
    );
  }
}

/// Ranks by their emblem.
class RankQuizPage extends ConsumerWidget {
  const RankQuizPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiers = ref.watch(rankTiersProvider).value ?? const <RankTier>[];

    return _QuizLauncher(
      title: 'ENTRAÎNEMENT RANGS',
      description: 'Dix emblèmes tirés au hasard, du Fer au Radiant : à toi de nommer le rang et sa division.',
      kind: QuizKind.rank,
      label: 'Rangs',
      mode: 'mixed',
      isReady: tiers.length >= 4,
      onStart: (context) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AgentQuizScreen(
            title: 'ENTRAÎNEMENT RANGS',
            kind: QuizKind.rank,
            label: 'Rangs',
            roundBuilder: () => CatalogQuiz.ranks(tiers: tiers),
          ),
        ),
      ),
    );
  }
}

/// The same ten questions for everyone today, once a day, with a streak.
class DailyChallengePage extends ConsumerWidget {
  const DailyChallengePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agents = ref.watch(agentsProvider).value ?? const <Agent>[];
    final weapons = ref.watch(weaponsProvider).value ?? const <Weapon>[];
    final tiers = ref.watch(rankTiersProvider).value ?? const <RankTier>[];
    final soundsAsync = ref.watch(abilitySoundsProvider);
    final streak = ref.watch(dailyStreakProvider).value ?? const DailyStreak();
    final today = DateTime.now();
    final isDone = streak.isDoneOn(today);
    final streakLength = streak.lengthOn(today);
    final lastScore = streak.lastScore;

    return _QuizLauncher(
      title: 'DÉFI DU JOUR',
      description: 'Dix questions mêlant agents, sons, armes et rangs — le même tirage pour tout le monde '
          'aujourd\'hui. Une seule partie par jour : enchaîne les jours pour faire grimper ta série.',
      kind: QuizKind.daily,
      label: 'Défi du jour',
      mode: 'daily',
      // A failed sound list only drops the listening questions.
      isReady: !isDone && agents.length >= 4 && !soundsAsync.isLoading,
      readyLabel: isDone ? 'DÉFI DÉJÀ JOUÉ AUJOURD\'HUI' : null,
      header: _StreakCard(
        length: streakLength,
        todayScore: isDone ? lastScore : null,
      ),
      onStart: (context) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AgentQuizScreen(
            title: 'DÉFI DU JOUR',
            kind: QuizKind.daily,
            label: 'Défi du jour',
            mode: 'daily',
            canReplay: false,
            roundBuilder: () => CatalogQuiz.daily(
              date: today,
              agents: agents,
              weapons: weapons,
              tiers: tiers,
              soundsByAgent: soundsAsync.value ?? const {},
            ),
            onFinished: (score) async {
              await ref.read(dailyStreakProvider.notifier).complete(today, score);
            },
          ),
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.length, required this.todayScore});

  final int length;
  final int? todayScore;

  @override
  Widget build(BuildContext context) {
    final todayScore = this.todayScore;

    return ClipPath(
      clipper: const DiagonalCutClipper(cut: 10),
      child: Container(
        color: AppTheme.valorantSurface,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department,
              size: 26,
              color: length > 0 ? const Color(0xFFFF9F45) : Colors.white24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    length == 0 ? 'Pas de série en cours' : 'Série : $length jour${length > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                  if (todayScore != null)
                    Text(
                      'Défi du jour terminé : $todayScore / $_maxScore. Prochain tirage demain.',
                      style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The page every catalogue quiz opens on: what it asks, the record, the
/// start button and the past games.
class _QuizLauncher extends ConsumerWidget {
  const _QuizLauncher({
    required this.title,
    required this.description,
    required this.kind,
    required this.label,
    required this.mode,
    required this.isReady,
    required this.onStart,
    this.readyLabel,
    this.header,
    this.maxScore = _maxScore,
  });

  final String title;
  final String description;
  final QuizKind kind;
  final String label;
  final String mode;
  final bool isReady;
  final void Function(BuildContext context) onStart;

  /// Shown on the disabled button instead of the loading wording.
  final String? readyLabel;
  final Widget? header;
  final int maxScore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(quizProgressProvider).value;
    final bestScore = progress?.bestFor(kind, label, mode);
    final history = [
      for (final run in progress?.history ?? const <QuizRun>[])
        if (run.kind == kind) run,
    ];
    final header = this.header;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(description, style: const TextStyle(fontSize: 12.5, color: AppTheme.valorantMuted, height: 1.45)),
          ),
          const SizedBox(height: 14),
          if (header != null) ...[header, const SizedBox(height: 10)],
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
                      bestScore == null ? 'Aucun record pour l\'instant' : 'Record : $bestScore / $maxScore',
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
            onPressed: isReady ? () => onStart(context) : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.valorantRed,
              disabledBackgroundColor: AppTheme.valorantSurface,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white24,
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: Icon(
              isReady
                  ? Icons.play_arrow_rounded
                  : readyLabel == null
                  ? Icons.hourglass_empty
                  : Icons.check,
              size: 22,
            ),
            label: Text(
              isReady ? 'LANCER UNE PARTIE' : readyLabel ?? 'CHARGEMENT…',
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

/// Throws to place on the plan: where does the utility land?
class LineupQuizPage extends ConsumerWidget {
  const LineupQuizPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maps = ref.watch(mapsProvider).value ?? const <GameMap>[];
    final lineupsReady = ref.watch(lineupsProvider).hasValue;
    final lineupsByMap = <GameMap, List<ResolvedLineup>>{
      for (final map in maps) map: ref.watch(resolvedLineupsProvider(map.displayName)),
    };
    final throwCount = lineupsByMap.values.fold(0, (sum, list) => sum + list.where((entry) => entry.to != null).length);

    return _QuizLauncher(
      title: 'QUIZ LINEUPS',
      description: '${LineupQuizRound.defaultQuestionCount} lancers tirés parmi les spots de l\'app et les tiens : '
          'on te donne l\'agent, la compétence et la position de départ, touche le plan là où elle atterrit. '
          'Les noms des callouts sont masqués.',
      kind: QuizKind.lineup,
      label: 'Lineups',
      mode: 'placement',
      maxScore: LineupQuizRound.defaultQuestionCount * MapQuizRound.pointsPerCallout,
      isReady: lineupsReady && throwCount > 0,
      onStart: (context) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LineupQuizScreen(buildRound: () => LineupQuizRound.create(lineupsByMap: lineupsByMap)),
        ),
      ),
    );
  }
}
