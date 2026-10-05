import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../encyclopedia/domain/agent.dart';
import '../../encyclopedia/domain/game_map.dart';
import '../../encyclopedia/providers/encyclopedia_providers.dart';
import '../data/lineup_collections_store.dart';
import '../data/lineup_media_store.dart';
import '../data/lineup_sources.dart';
import '../domain/lineup.dart';
import '../domain/lineup_collections.dart';
import '../domain/resolved_lineup.dart';

final bundledLineupsSourceProvider = Provider<BundledLineupsSource>((ref) => BundledLineupsSource());

final userLineupsStoreProvider = Provider<UserLineupsStore>((ref) => UserLineupsStore());

final lineupMediaStoreProvider = Provider<LineupMediaStore>((ref) => LineupMediaStore());

/// Every spot the app knows about: the bundled ones plus the player's own,
/// the latter first so a duplicated spot appears above its original.
class LineupsNotifier extends AsyncNotifier<List<Lineup>> {
  @override
  Future<List<Lineup>> build() async {
    final bundled = await ref.read(bundledLineupsSourceProvider).load();
    final own = await ref.read(userLineupsStoreProvider).load();
    return [...own, ...bundled];
  }

  Future<void> save(Lineup lineup) async {
    final lineups = [...?state.value];
    final index = lineups.indexWhere((entry) => entry.id == lineup.id);

    if (index == -1) {
      lineups.insert(0, lineup);
    } else {
      lineups[index] = lineup;
    }

    await _commit(lineups);
  }

  /// Adds imported spots on top of the list.
  Future<void> addAll(List<Lineup> imported) async {
    if (imported.isEmpty) return;
    final ids = {for (final lineup in imported) lineup.id};
    final lineups = [...imported, for (final lineup in [...?state.value]) if (!ids.contains(lineup.id)) lineup];
    await _commit(lineups);
  }

  Future<void> delete(String lineupId) async {
    final lineups = [...?state.value];
    final removed = lineups.where((entry) => entry.id == lineupId).firstOrNull;
    if (removed == null || removed.isBundled) return;

    lineups.removeWhere((entry) => entry.id == lineupId);
    await ref.read(lineupMediaStoreProvider).deleteAll(removed.media);
    await _commit(lineups);
  }

  Future<void> _commit(List<Lineup> lineups) async {
    state = AsyncData(lineups);
    await ref.read(userLineupsStoreProvider).save([
      for (final lineup in lineups)
        if (!lineup.isBundled) lineup,
    ]);
  }
}

final lineupsProvider = AsyncNotifierProvider<LineupsNotifier, List<Lineup>>(LineupsNotifier.new);

/// How many spots each map has, for the map picker.
final lineupCountByMapProvider = Provider<Map<String, int>>((ref) {
  final lineups = ref.watch(lineupsProvider).value ?? const <Lineup>[];

  final counts = <String, int>{};
  for (final lineup in lineups) {
    counts[lineup.mapName] = (counts[lineup.mapName] ?? 0) + 1;
  }
  return counts;
});

final gameMapByNameProvider = Provider.family<GameMap?, String>((ref, mapName) {
  final maps = ref.watch(mapsProvider).value ?? const <GameMap>[];
  for (final map in maps) {
    if (map.displayName == mapName) return map;
  }
  return null;
});

/// The spots of one map, with their anchors turned into minimap positions.
/// Spots pointing at a callout the map doesn't have are left out.
final resolvedLineupsProvider = Provider.family<List<ResolvedLineup>, String>((ref, mapName) {
  final map = ref.watch(gameMapByNameProvider(mapName));
  if (map == null) return const [];

  final lineups = ref.watch(lineupsProvider).value ?? const <Lineup>[];
  return [
    for (final lineup in lineups)
      if (lineup.mapName == mapName) ?ResolvedLineup.resolve(lineup, map),
  ];
});

/// The catalogue entry backing a spot's agent, for its artwork and its
/// ability icons.
final agentByNameProvider = Provider.family<Agent?, String>((ref, agentName) {
  final agents = ref.watch(agentsProvider).value ?? const <Agent>[];
  for (final agent in agents) {
    if (agent.displayName == agentName) return agent;
  }
  return null;
});

final lineupCollectionsStoreProvider = Provider<LineupCollectionsStore>((ref) => LineupCollectionsStore());

/// Starred spots and the player's named collections.
class LineupCollectionsNotifier extends AsyncNotifier<LineupCollections> {
  @override
  Future<LineupCollections> build() => ref.read(lineupCollectionsStoreProvider).load();

  Future<void> toggleFavorite(String lineupId) => _apply((value) => value.toggleFavorite(lineupId));

  Future<void> create(String name) => _apply((value) => value.create(name));

  Future<void> delete(String name) => _apply((value) => value.delete(name));

  Future<void> toggleIn(String name, String lineupId) => _apply((value) => value.toggleIn(name, lineupId));

  Future<void> _apply(LineupCollections Function(LineupCollections value) change) async {
    final updated = change(state.value ?? const LineupCollections());
    state = AsyncData(updated);
    await ref.read(lineupCollectionsStoreProvider).save(updated);
  }
}

final lineupCollectionsProvider = AsyncNotifierProvider<LineupCollectionsNotifier, LineupCollections>(
  LineupCollectionsNotifier.new,
);
