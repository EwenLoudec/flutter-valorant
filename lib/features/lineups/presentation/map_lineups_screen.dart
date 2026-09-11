import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/lineup.dart';
import '../domain/resolved_lineup.dart';
import '../providers/lineups_providers.dart';
import 'lineup_card.dart';
import 'lineup_detail_screen.dart';
import 'lineup_editor_screen.dart';
import 'lineup_filters.dart';
import 'lineup_map_view.dart';

/// All the spots of one map: the plan on top, the filtered list below.
class MapLineupsScreen extends ConsumerStatefulWidget {
  const MapLineupsScreen({super.key, required this.mapName});

  final String mapName;

  @override
  ConsumerState<MapLineupsScreen> createState() => _MapLineupsScreenState();
}

class _MapLineupsScreenState extends ConsumerState<MapLineupsScreen> {
  final _cardKeys = <String, GlobalKey>{};

  String? _selectedId;
  String? _agentName;
  LineupSide? _side;

  void _select(String lineupId, {bool scrollToCard = true}) {
    setState(() => _selectedId = lineupId);
    if (!scrollToCard) return;

    final context = _cardKeys[lineupId]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      alignment: 0.3,
    );
  }

  Future<void> _createLineup() async {
    final created = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => LineupEditorScreen(mapName: widget.mapName)),
    );
    if (created != null && mounted) _select(created);
  }

  bool _matchesFilters(Lineup lineup) {
    if (_agentName != null && lineup.agentName != _agentName) return false;
    if (_side != null && lineup.side != LineupSide.both && lineup.side != _side) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final map = ref.watch(gameMapByNameProvider(widget.mapName));
    final resolved = ref.watch(resolvedLineupsProvider(widget.mapName));
    final visible = resolved.where((entry) => _matchesFilters(entry.lineup)).toList();

    final agentNames = {for (final entry in resolved) entry.lineup.agentName}.toList()..sort();
    final selectedId = visible.any((entry) => entry.lineup.id == _selectedId) ? _selectedId : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mapName.toUpperCase()} · SPOTS'),
        actions: [
          IconButton(
            tooltip: 'Ajouter un spot',
            onPressed: map == null ? null : _createLineup,
            icon: const Icon(Icons.add_location_alt_outlined),
          ),
        ],
      ),
      body: map == null
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LineupMapView(
                          map: map,
                          lineups: visible,
                          selectedId: selectedId,
                          onSelect: _select,
                        ),
                        const SizedBox(height: 8),
                        const _MapLegend(),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: LineupSideFilter(
                      selected: _side,
                      onSelected: (side) => setState(() => _side = side),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: LineupAgentFilter(
                    agentNames: agentNames,
                    selected: _agentName,
                    onSelected: (agentName) => setState(() => _agentName = agentName),
                  ),
                ),
                if (visible.isEmpty)
                  SliverToBoxAdapter(child: _EmptyState(onCreate: _createLineup))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        for (final entry in visible) ...[
                          _buildCard(entry, isSelected: entry.lineup.id == selectedId),
                          const SizedBox(height: 8),
                        ],
                      ]),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildCard(ResolvedLineup entry, {required bool isSelected}) {
    final lineup = entry.lineup;
    final key = _cardKeys.putIfAbsent(lineup.id, GlobalKey.new);

    return KeyedSubtree(
      key: key,
      child: LineupCard(
        lineup: lineup,
        isSelected: isSelected,
        onLocate: () => _select(lineup.id, scrollToCard: false),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LineupDetailScreen(mapName: widget.mapName, lineupId: lineup.id),
          ),
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Touche un marqueur pour le retrouver dans la liste. Cercle plein = position de lancer, '
      'réticule = point visé, losange = emplacement à poser.',
      style: TextStyle(fontSize: 10.5, color: AppTheme.valorantMuted, height: 1.4),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        children: [
          const Icon(Icons.explore_off_outlined, size: 40, color: Colors.white24),
          const SizedBox(height: 12),
          const Text(
            'Aucun spot pour ce filtre.',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Change de filtre, ou ajoute ton propre spot en le plaçant sur le plan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.valorantMuted, height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreate,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.valorantRed,
              shape: const RoundedRectangleBorder(),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('CRÉER UN SPOT', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
