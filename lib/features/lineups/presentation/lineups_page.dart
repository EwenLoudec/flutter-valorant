import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_list_view.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../core/widgets/fade_in_network_image.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../../../core/widgets/staggered_fade_slide.dart';
import '../../encyclopedia/domain/game_map.dart';
import '../../encyclopedia/providers/encyclopedia_providers.dart';
import '../providers/lineups_providers.dart';
import 'map_lineups_screen.dart';

/// Entry point of the feature: pick a map, get its spots.
class LineupsPage extends ConsumerWidget {
  const LineupsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(lineupCountByMapProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('LINEUPS')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              'Les spots d\'utilitaire posés sur le plan tactique : où se placer, quoi viser. '
              'Choisis une carte, puis ajoute les tiens.',
              style: TextStyle(fontSize: 12, color: AppTheme.valorantMuted, height: 1.4),
            ),
          ),
          Expanded(
            child: AsyncListView<GameMap>(
              value: ref.watch(mapsProvider),
              emptyMessage: 'Aucune carte trouvée.',
              builder: (context, maps) {
                final sorted = [...maps]
                  ..sort((a, b) {
                    final byCount = (counts[b.displayName] ?? 0).compareTo(counts[a.displayName] ?? 0);
                    return byCount != 0 ? byCount : a.displayName.compareTo(b.displayName);
                  });

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: sorted.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => StaggeredFadeSlide(
                    index: index,
                    child: _MapRow(map: sorted[index], count: counts[sorted[index].displayName] ?? 0),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MapRow extends StatelessWidget {
  const _MapRow({required this.map, required this.count});

  final GameMap map;
  final int count;

  @override
  Widget build(BuildContext context) {
    final splash = map.splash;

    return PressableScale(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MapLineupsScreen(mapName: map.displayName)),
      ),
      child: ClipPath(
        clipper: const DiagonalCutClipper(cut: 10),
        child: Container(
          height: 84,
          color: AppTheme.valorantSurface,
          child: Row(
            children: [
              SizedBox(
                width: 120,
                height: 84,
                child: splash == null
                    ? const ColoredBox(color: Colors.black26)
                    : FadeInNetworkImage(url: splash, alignment: Alignment.center),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      map.displayName.toUpperCase(),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      count == 0 ? 'Aucun spot — ajoute le premier' : '$count spot${count > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: count == 0 ? AppTheme.valorantMuted : AppTheme.valorantRed,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.chevron_right, color: AppTheme.valorantMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
