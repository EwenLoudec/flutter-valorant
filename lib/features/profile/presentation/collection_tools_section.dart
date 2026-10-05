import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/entry_tile.dart';
import '../../collection/presentation/bundles_screen.dart';
import '../../collection/presentation/contracts_screen.dart';
import '../../collection/presentation/cosmetics_screen.dart';
import '../../collection/presentation/skin_prices_screen.dart';
import '../../tools/presentation/crosshair_screen.dart';
import '../providers/profile_providers.dart';
import 'profile_section.dart';

/// The rest of the collection (cards, sprays, buddies, titles), the store
/// catalogue and the crosshair tool. Everything here works without a Riot ID.
class CollectionToolsSection extends ConsumerWidget {
  const CollectionToolsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owned = ref.watch(ownedCosmeticsProvider).value ?? const {};
    final ownedCount = owned.values.fold(0, (sum, uuids) => sum + uuids.length);

    void open(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    return ProfileSection(
      title: 'Collection et outils',
      child: Column(
        children: [
          EntryTileRow(
            tiles: [
              EntryTile(
                icon: Icons.style_outlined,
                title: 'COLLECTION',
                subtitle: ownedCount == 0 ? 'Cartes, graffitis, titres…' : '$ownedCount cosmétique${ownedCount > 1 ? 's' : ''} coché${ownedCount > 1 ? 's' : ''}',
                onTap: () => open(const CosmeticsScreen()),
              ),
              EntryTile(
                icon: Icons.gps_fixed,
                title: 'RÉTICULE',
                subtitle: 'Aperçu d\'un code, favoris',
                onTap: () => open(const CrosshairScreen()),
              ),
            ],
          ),
          const SizedBox(height: 8),
          EntryTileRow(
            tiles: [
              EntryTile(
                icon: Icons.shopping_bag_outlined,
                title: 'BUNDLES',
                subtitle: 'Toutes les collections de la boutique',
                onTap: () => open(const BundlesScreen()),
              ),
              EntryTile(
                icon: Icons.workspace_premium_outlined,
                title: 'CONTRATS',
                subtitle: 'Agents, passes et récompenses',
                onTap: () => open(const ContractsScreen()),
              ),
            ],
          ),
          const SizedBox(height: 8),
          EntryTileRow(
            tiles: [
              EntryTile(
                icon: Icons.sell_outlined,
                title: 'PRIX DES SKINS',
                subtitle: 'Tous les skins, par gamme et par arme',
                onTap: () => open(const SkinPricesScreen()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
