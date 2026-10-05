import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_list_view.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../core/widgets/entry_tile.dart';
import '../../../core/widgets/fade_in_network_image.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../../../core/widgets/staggered_fade_slide.dart';
import '../../../core/widgets/valorant_input.dart';
import '../../encyclopedia/domain/game_map.dart';
import '../../encyclopedia/providers/encyclopedia_providers.dart';
import '../../training/presentation/catalog_quiz_pages.dart';
import '../domain/lineup.dart';
import '../domain/lineup_transfer.dart';
import '../providers/lineups_providers.dart';
import 'lineup_card.dart';
import 'lineup_collections_screen.dart';
import 'lineup_detail_screen.dart';
import 'lineup_transfer_dialogs.dart';
import 'map_lineups_screen.dart';

enum _MenuAction { exportOwn, import }

/// Entry point of the feature: pick a map, get its spots — or search every
/// spot at once.
class LineupsPage extends ConsumerStatefulWidget {
  const LineupsPage({super.key});

  @override
  ConsumerState<LineupsPage> createState() => _LineupsPageState();
}

class _LineupsPageState extends ConsumerState<LineupsPage> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onMenu(_MenuAction action) {
    switch (action) {
      case _MenuAction.exportOwn:
        final own = [
          for (final lineup in ref.read(lineupsProvider).value ?? const <Lineup>[])
            if (!lineup.isBundled) lineup,
        ];
        copyLineupsToClipboard(context, own);
      case _MenuAction.import:
        importLineups(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final counts = ref.watch(lineupCountByMapProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LINEUPS'),
        actions: [
          PopupMenuButton<_MenuAction>(
            tooltip: 'Partager',
            icon: const Icon(Icons.ios_share),
            color: AppTheme.valorantSurface,
            onSelected: _onMenu,
            itemBuilder: (_) => const [
              PopupMenuItem(value: _MenuAction.exportOwn, child: Text('Exporter mes spots')),
              PopupMenuItem(value: _MenuAction.import, child: Text('Importer des spots')),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Text(
              'Les spots d\'utilitaire posés sur le plan tactique : où se placer, quoi viser. '
              'Choisis une carte, puis ajoute les tiens.',
              style: TextStyle(fontSize: 12, color: AppTheme.valorantMuted, height: 1.4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              controller: _searchController,
              decoration: valorantInputDecoration(hint: 'Chercher un spot : agent, callout, compétence…').copyWith(
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Effacer',
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _search = '';
                        }),
                      ),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          if (_search.trim().isEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: EntryTileRow(
                tiles: [
                  EntryTile(
                    icon: Icons.star_rounded,
                    title: 'MES SPOTS',
                    subtitle: 'Favoris et collections',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LineupCollectionsScreen()),
                    ),
                  ),
                  EntryTile(
                    icon: Icons.sports_esports_outlined,
                    title: 'QUIZ LINEUPS',
                    subtitle: 'Place les lancers sur le plan',
                    isHighlighted: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LineupQuizPage()),
                    ),
                  ),
                ],
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
          ] else
            Expanded(child: _SearchResults(search: _search)),
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

/// Every spot of every map matching the search, best match first.
class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.search});

  final String search;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = [
      for (final entry in ref.watch(allResolvedLineupsProvider).values)
        if (entry.lineup.matches(search)) entry,
    ]..sort((a, b) {
        final byMap = a.lineup.mapName.compareTo(b.lineup.mapName);
        return byMap != 0 ? byMap : a.lineup.title.compareTo(b.lineup.title);
      });

    if (results.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aucun spot ne correspond. Essaie un agent (« Sova »), un callout (« A Main ») ou une touche (« Q »).',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.valorantMuted, height: 1.4),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      itemCount: results.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            '${results.length} spot${results.length > 1 ? 's' : ''}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.valorantMuted),
          );
        }
        final lineup = results[index - 1].lineup;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lineup.mapName.toUpperCase(),
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppTheme.valorantMuted),
            ),
            const SizedBox(height: 3),
            LineupCard(
              lineup: lineup,
              isSelected: false,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => LineupDetailScreen(mapName: lineup.mapName, lineupId: lineup.id)),
              ),
            ),
          ],
        );
      },
    );
  }
}
