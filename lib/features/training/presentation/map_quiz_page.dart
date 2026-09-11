import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_list_view.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../../encyclopedia/domain/game_map.dart';
import '../../encyclopedia/providers/encyclopedia_providers.dart';
import '../domain/map_quiz.dart';
import '../providers/training_providers.dart';
import 'map_quiz_screen.dart';
import 'quiz_history_view.dart';

/// Starts a game — random by default, since knowing the map beforehand
/// empties the first leg of its interest.
class MapQuizPage extends ConsumerWidget {
  const MapQuizPage({super.key});

  void _play(BuildContext context, GameMap map, List<GameMap> maps, {required bool asksMapName}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapQuizScreen(
          map: map,
          allMapNames: [for (final entry in maps) entry.displayName],
          asksMapName: asksMapName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(quizProgressProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('ENTRAÎNEMENT CALLOUTS')),
      body: AsyncListView<GameMap>(
        value: ref.watch(mapsProvider),
        emptyMessage: 'Aucune carte trouvée.',
        builder: (context, maps) {
          final playable = [
            for (final map in maps)
              if (map.displayIcon != null) map,
          ];

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              const _SectionTitle('Partie complète'),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Une carte tirée au sort, que tu dois reconnaître, puis six callouts à '
                  'placer — tirés au hasard et répartis entre les sites. 700 points en jeu.',
                  style: TextStyle(fontSize: 12.5, color: AppTheme.valorantMuted, height: 1.45),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: playable.isEmpty
                    ? null
                    : () => _play(
                        context,
                        playable[Random().nextInt(playable.length)],
                        playable,
                        asksMapName: true,
                      ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.valorantRed,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.casino_outlined, size: 20),
                label: const Text(
                  'LANCER UNE PARTIE',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.6, fontSize: 14),
                ),
              ),
              const SizedBox(height: 22),
              const _SectionTitle('Entraînement ciblé'),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Tu choisis la carte : la manche « devine la carte » saute, on passe '
                  'directement aux six callouts. 600 points en jeu.',
                  style: TextStyle(fontSize: 12.5, color: AppTheme.valorantMuted, height: 1.45),
                ),
              ),
              const SizedBox(height: 12),
              for (final map in playable) ...[
                _MapRow(
                  map: map,
                  bestScore: progress?.bestFor(map.displayName, askedMapName: false),
                  onTap: () => _play(context, map, playable, asksMapName: false),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 14),
              QuizHistoryView(history: progress?.history ?? const []),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: AppTheme.valorantRed),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.8),
        ),
      ],
    );
  }
}

class _MapRow extends StatelessWidget {
  const _MapRow({required this.map, required this.bestScore, required this.onTap});

  final GameMap map;
  final int? bestScore;
  final VoidCallback onTap;

  /// What a focused run is worth: the callouts only.
  int get _maxScore => MapQuizRound.defaultQuestionCount * MapQuizRound.pointsPerCallout;

  @override
  Widget build(BuildContext context) {
    final bestScore = this.bestScore;
    final hasPlayed = bestScore != null;

    return PressableScale(
      onTap: onTap,
      child: ClipPath(
        clipper: const DiagonalCutClipper(cut: 10),
        child: Container(
          color: AppTheme.valorantSurface,
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      map.displayName.toUpperCase(),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.4),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasPlayed ? 'Record : $bestScore / $_maxScore' : 'Jamais tenté',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: hasPlayed ? AppTheme.valorantRed : AppTheme.valorantMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.valorantMuted),
            ],
          ),
        ),
      ),
    );
  }
}
