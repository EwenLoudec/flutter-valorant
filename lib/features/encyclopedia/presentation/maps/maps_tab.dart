import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/async_list_view.dart';
import '../../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../../core/widgets/fade_in_network_image.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../../core/widgets/staggered_fade_slide.dart';
import '../../data/map_meta_data.dart';
import '../../domain/game_map.dart';
import '../../providers/encyclopedia_providers.dart';
import '../../../training/presentation/map_quiz_page.dart';
import 'map_detail_screen.dart';

class MapsTab extends ConsumerWidget {
  const MapsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapsAsync = ref.watch(mapsProvider);

    return AsyncListView<GameMap>(
      value: mapsAsync,
      emptyMessage: 'Aucune carte trouvée.',
      builder: (context, allMaps) {
        final maps = [...allMaps]
          ..sort((a, b) {
            final aInPool = kMapMetaData[a.displayName]?.inCompetitivePool ?? false;
            final bInPool = kMapMetaData[b.displayName]?.inCompetitivePool ?? false;
            if (aInPool != bInPool) return aInPool ? -1 : 1;
            return a.displayName.compareTo(b.displayName);
          });

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          // The first row is the training entry, the rest are the maps.
          itemCount: maps.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) return const _TrainingCard();
            return StaggeredFadeSlide(
              index: index,
              child: _MapCard(map: maps[index - 1]),
            );
          },
        );
      },
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({required this.map});

  final GameMap map;

  @override
  Widget build(BuildContext context) {
    final meta = kMapMetaData[map.displayName];
    final inPool = meta?.inCompetitivePool ?? false;

    return PressableScale(
      onTap: () => Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 380),
          pageBuilder: (_, animation, _) => FadeTransition(
            opacity: animation,
            child: MapDetailScreen(map: map),
          ),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: (inPool ? AppTheme.valorantRed : Colors.white24).withValues(alpha: 0.25),
              blurRadius: 16,
              spreadRadius: -6,
            ),
          ],
        ),
        child: ClipPath(
          clipper: const DiagonalCutClipper(cut: 16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                map.splash != null
                    ? FadeInNetworkImage(url: map.splash!, fit: BoxFit.cover)
                    : const ColoredBox(color: AppTheme.valorantSurface),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      border: Border.all(color: inPool ? AppTheme.valorantRed : Colors.white38),
                    ),
                    child: Text(
                      inPool ? 'COMPÉTITIF ACTIF' : 'HORS ROTATION',
                      style: TextStyle(
                        color: inPool ? AppTheme.valorantRed : Colors.white54,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: 10,
                  right: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        map.displayName.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: 0.4),
                      ),
                      if (map.tacticalDescription != null)
                        Text(
                          map.tacticalDescription!,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Entry point of the callout training game, on top of the map list.
class _TrainingCard extends StatelessWidget {
  const _TrainingCard();

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MapQuizPage())),
      child: ClipPath(
        clipper: const DiagonalCutClipper(cut: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.valorantRed.withValues(alpha: 0.12),
            border: Border.all(color: AppTheme.valorantRed.withValues(alpha: 0.6)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
          child: Row(
            children: [
              const Icon(Icons.sports_esports_outlined, size: 22, color: AppTheme.valorantRed),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ENTRAÎNEMENT CALLOUTS',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Devine la carte, puis place les callouts au bon endroit.',
                      style: TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.35),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.valorantRed),
            ],
          ),
        ),
      ),
    );
  }
}
