import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/fade_in_network_image.dart';
import '../../data/map_meta_data.dart';
import '../../domain/agent.dart';
import '../../domain/game_map.dart';
import '../../providers/encyclopedia_providers.dart';
import 'map_composition_card.dart';
import 'tactical_minimap.dart';

class MapDetailScreen extends ConsumerStatefulWidget {
  const MapDetailScreen({super.key, required this.map});

  final GameMap map;

  @override
  ConsumerState<MapDetailScreen> createState() => _MapDetailScreenState();
}

class _MapDetailScreenState extends ConsumerState<MapDetailScreen> {
  final _minimapKey = GlobalKey();
  MapCallout? _highlighted;
  int _highlightToken = 0;

  void _locate(MapCallout callout) {
    setState(() {
      _highlighted = callout;
      _highlightToken++;
    });
    final context = _minimapKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        alignment: 0.1,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final map = widget.map;
    final meta = kMapMetaData[map.displayName];
    final inPool = meta?.inCompetitivePool ?? false;
    final agents = ref.watch(agentsProvider).asData?.value ?? const <Agent>[];
    final agentsByName = {for (final agent in agents) agent.displayName: agent};

    final grouped = <String, List<MapCallout>>{};
    for (final callout in map.callouts) {
      grouped.putIfAbsent(callout.superRegionName, () => []).add(callout);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            backgroundColor: AppTheme.valorantDark,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(map.displayName.toUpperCase(), style: const TextStyle(letterSpacing: 0.5)),
              background: map.splash != null ? FadeInNetworkImage(url: map.splash!, fit: BoxFit.cover) : null,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: (inPool ? AppTheme.valorantRed : Colors.white24).withValues(alpha: 0.15),
                        border: Border.all(color: inPool ? AppTheme.valorantRed : Colors.white38),
                      ),
                      child: Text(
                        inPool ? 'COMPÉTITIF ACTIF' : 'HORS ROTATION',
                        style: TextStyle(
                          color: inPool ? AppTheme.valorantRed : Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    if (map.tacticalDescription != null) ...[
                      const SizedBox(width: 8),
                      Chip(label: Text(map.tacticalDescription!)),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(width: 4, height: 16, color: AppTheme.valorantRed),
                    const SizedBox(width: 8),
                    Text(
                      'MINIMAP TACTIQUE',
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.6),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                KeyedSubtree(
                  key: _minimapKey,
                  child: TacticalMinimap(map: map, highlighted: _highlighted, highlightToken: _highlightToken),
                ),
                if (grouped.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(width: 4, height: 16, color: AppTheme.valorantRed),
                      const SizedBox(width: 8),
                      Text(
                        'CALLOUTS',
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.6),
                      ),
                      const Spacer(),
                      const Icon(Icons.touch_app, size: 14, color: Colors.white38),
                      const SizedBox(width: 4),
                      const Text('Repérer', style: TextStyle(fontSize: 11, color: Colors.white38)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...grouped.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.valorantRed,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final callout in {for (final c in entry.value) c.regionName: c}.values)
                                _CalloutChip(
                                  callout: callout,
                                  selected: _highlighted == callout,
                                  onTap: () => _locate(callout),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (meta != null) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(width: 4, height: 16, color: AppTheme.valorantRed),
                      const SizedBox(width: 8),
                      Text(
                        'MEILLEURE COMPOSITION',
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  MapCompositionCard(composition: meta.metaComposition, agentsByName: agentsByName),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalloutChip extends StatelessWidget {
  const _CalloutChip({required this.callout, required this.selected, required this.onTap});

  final MapCallout callout;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = TacticalMinimap.colorForSuperRegion(callout.superRegionName);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: selected ? color : Colors.white24),
        ),
        child: Text(
          callout.regionName,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? color : Colors.white,
          ),
        ),
      ),
    );
  }
}
