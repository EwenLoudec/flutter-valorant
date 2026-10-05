import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/valorant_input.dart';
import '../../encyclopedia/domain/game_map.dart';
import '../../encyclopedia/providers/encyclopedia_providers.dart';
import '../domain/lineup_collections.dart';
import '../domain/resolved_lineup.dart';
import '../providers/lineups_providers.dart';
import 'lineup_card.dart';
import 'lineup_detail_screen.dart';

/// Every spot that can be drawn, across all maps, keyed by id.
final allResolvedLineupsProvider = Provider<Map<String, ResolvedLineup>>((ref) {
  final maps = ref.watch(mapsProvider).value ?? const <GameMap>[];
  return {
    for (final map in maps)
      for (final entry in ref.watch(resolvedLineupsProvider(map.displayName))) entry.lineup.id: entry,
  };
});

/// The starred spots, then each collection.
class LineupCollectionsScreen extends ConsumerWidget {
  const LineupCollectionsScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(context: context, builder: (_) => const CollectionNameDialog());
    if (name == null || name.trim().isEmpty) return;
    await ref.read(lineupCollectionsProvider.notifier).create(name);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.valorantSurface,
        title: const Text('Supprimer la collection ?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Text('« $name » sera supprimée. Les spots eux-mêmes sont conservés.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.valorantRed),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true) await ref.read(lineupCollectionsProvider.notifier).delete(name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(lineupCollectionsProvider).value ?? const LineupCollections();
    final lineups = ref.watch(allResolvedLineupsProvider);

    List<ResolvedLineup> spotsOf(Iterable<String> ids) => [for (final id in ids) ?lineups[id]];

    return Scaffold(
      appBar: AppBar(
        title: const Text('MES SPOTS'),
        actions: [
          IconButton(
            tooltip: 'Nouvelle collection',
            onPressed: () => _create(context, ref),
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _Group(
            title: 'Favoris',
            icon: Icons.star_rounded,
            spots: spotsOf(collections.favorites),
            emptyText: 'Touche l\'étoile d\'un spot pour le retrouver ici.',
          ),
          for (final entry in collections.collections.entries)
            _Group(
              title: entry.key,
              icon: Icons.folder_outlined,
              spots: spotsOf(entry.value),
              emptyText: 'Collection vide : ajoute des spots depuis leur fiche.',
              onDelete: () => _delete(context, ref, entry.key),
            ),
          if (collections.collections.isEmpty)
            OutlinedButton.icon(
              onPressed: () => _create(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: AppTheme.outlineDark),
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: const Icon(Icons.create_new_folder_outlined, size: 18),
              label: const Text('CRÉER UNE COLLECTION', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.icon, required this.spots, required this.emptyText, this.onDelete});

  final String title;
  final IconData icon;
  final List<ResolvedLineup> spots;
  final String emptyText;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: AppTheme.valorantRed),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${title.toUpperCase()} (${spots.length})',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                ),
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Supprimer la collection',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white38),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (spots.isEmpty)
            Text(emptyText, style: const TextStyle(fontSize: 12, color: AppTheme.valorantMuted))
          else
            for (final spot in spots) ...[
              LineupCard(
                lineup: spot.lineup,
                isSelected: false,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LineupDetailScreen(mapName: spot.lineup.mapName, lineupId: spot.lineup.id),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

/// Asks for a collection name. It owns its controller so the closing
/// animation never sees a disposed one.
class CollectionNameDialog extends StatefulWidget {
  const CollectionNameDialog({super.key});

  @override
  State<CollectionNameDialog> createState() => _CollectionNameDialogState();
}

class _CollectionNameDialogState extends State<CollectionNameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.valorantSurface,
      title: const Text('Nouvelle collection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: valorantInputDecoration(hint: 'Ex. Mes lineups Viper sur Ascent'),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          style: TextButton.styleFrom(foregroundColor: AppTheme.valorantRed),
          child: const Text('Créer'),
        ),
      ],
    );
  }
}

/// Bottom sheet ticking the collections a spot belongs to.
class LineupCollectionsSheet extends ConsumerWidget {
  const LineupCollectionsSheet({super.key, required this.lineupId});

  final String lineupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(lineupCollectionsProvider).value ?? const LineupCollections();
    final notifier = ref.read(lineupCollectionsProvider.notifier);
    final memberOf = collections.collectionsOf(lineupId).toSet();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'AJOUTER À UNE COLLECTION',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.6),
            ),
            const SizedBox(height: 8),
            if (collections.collections.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Aucune collection pour l\'instant.', style: TextStyle(color: AppTheme.valorantMuted)),
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final name in collections.collections.keys)
                    CheckboxListTile(
                      value: memberOf.contains(name),
                      onChanged: (_) => notifier.toggleIn(name, lineupId),
                      title: Text(name),
                      activeColor: AppTheme.valorantRed,
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final name = await showDialog<String>(context: context, builder: (_) => const CollectionNameDialog());
                if (name == null || name.trim().isEmpty) return;
                await notifier.toggleIn(name, lineupId);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: AppTheme.outlineDark),
                shape: const RoundedRectangleBorder(),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('NOUVELLE COLLECTION', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
