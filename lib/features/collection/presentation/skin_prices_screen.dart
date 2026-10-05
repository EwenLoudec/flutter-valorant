import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../core/widgets/fade_in_network_image.dart';
import '../../../core/widgets/valorant_input.dart';
import '../../encyclopedia/domain/content_tier.dart';
import '../../encyclopedia/providers/encyclopedia_providers.dart';
import '../../profile/presentation/featured_store_section.dart' show valorantPointsIcon;
import '../domain/skin_prices.dart';
import '../providers/collection_providers.dart';

enum _Sort {
  name('Nom'),
  cheapest('Prix croissant'),
  priciest('Prix décroissant');

  const _Sort(this.label);

  final String label;
}

/// Every paid skin with its price, to search, filter by edition and weapon,
/// and sort.
class SkinPricesScreen extends ConsumerStatefulWidget {
  const SkinPricesScreen({super.key});

  @override
  ConsumerState<SkinPricesScreen> createState() => _SkinPricesScreenState();
}

class _SkinPricesScreenState extends ConsumerState<SkinPricesScreen> {
  String _search = '';
  SkinEdition? _edition;
  String? _weapon;
  _Sort _sort = _Sort.name;

  List<SkinPrice> _visible(List<SkinPrice> all) {
    final skins = [
      for (final skin in all)
        if (skin.matches(_search) &&
            (_edition == null || skin.edition == _edition) &&
            (_weapon == null || skin.weaponName == _weapon))
          skin,
    ];
    switch (_sort) {
      case _Sort.name:
        break;
      case _Sort.cheapest:
        skins.sort((a, b) => a.price.compareTo(b.price));
      case _Sort.priciest:
        skins.sort((a, b) => b.price.compareTo(a.price));
    }
    return skins;
  }

  @override
  Widget build(BuildContext context) {
    final tiers = ref.watch(contentTiersProvider).value ?? const <String, ContentTier>{};

    return Scaffold(
      appBar: AppBar(title: const Text('PRIX DES SKINS')),
      body: ref
          .watch(skinPriceListProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Catalogue indisponible : $error', textAlign: TextAlign.center),
              ),
            ),
            data: (list) {
              final weapons = {for (final skin in list.skins) skin.weaponName}.toList()..sort();
              final skins = _visible(list.skins);

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    sliver: SliverList.list(
                      children: [
                        const _PriceNotice(),
                        const SizedBox(height: 10),
                        TextField(
                          decoration: valorantInputDecoration(hint: 'Rechercher un skin ou une arme'),
                          onChanged: (value) => setState(() => _search = value),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _EditionChip(
                              label: 'Toutes',
                              isSelected: _edition == null,
                              onTap: () => setState(() => _edition = null),
                            ),
                            for (final edition in SkinEdition.values)
                              _EditionChip(
                                label: edition.label,
                                icon: tiers[edition.tierUuid]?.displayIcon,
                                color: tiers[edition.tierUuid]?.color,
                                isSelected: _edition == edition,
                                onTap: () => setState(() => _edition = _edition == edition ? null : edition),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String?>(
                                initialValue: _weapon,
                                isExpanded: true,
                                dropdownColor: AppTheme.valorantSurface,
                                decoration: valorantInputDecoration(),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('Toutes les armes')),
                                  for (final weapon in weapons) DropdownMenuItem(value: weapon, child: Text(weapon)),
                                ],
                                onChanged: (weapon) => setState(() => _weapon = weapon),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<_Sort>(
                                initialValue: _sort,
                                isExpanded: true,
                                dropdownColor: AppTheme.valorantSurface,
                                decoration: valorantInputDecoration(),
                                items: [
                                  for (final sort in _Sort.values)
                                    DropdownMenuItem(value: sort, child: Text(sort.label)),
                                ],
                                onChanged: (sort) => setState(() => _sort = sort ?? _Sort.name),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${skins.length} skin${skins.length > 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.valorantMuted),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  if (skins.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('Aucun skin ne correspond.')),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      sliver: SliverList.separated(
                        itemCount: skins.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final skin = skins[index];
                          return _SkinRow(skin: skin, tier: tiers[skin.edition.tierUuid]);
                        },
                      ),
                    ),
                ],
              );
            },
          ),
    );
  }
}

class _PriceNotice extends StatelessWidget {
  const _PriceNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: AppTheme.valorantSurface,
        border: Border(left: BorderSide(color: Color(0xFFFFC25A), width: 3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: Color(0xFFFFC25A)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Riot ne publie plus les prix : ce sont ceux de chaque gamme (Select 875, Deluxe 1 275, '
              'Premium 1 775, Ultra 2 475 VP, le double pour un couteau). Les Exclusive coûtent 2 175 VP '
              'ou plus. Les skins en boutique aujourd\'hui affichent leur prix exact.',
              style: TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditionChip extends StatelessWidget {
  const _EditionChip({required this.label, required this.isSelected, required this.onTap, this.icon, this.color});

  final String label;
  final String? icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? AppTheme.valorantRed;
    final icon = this.icon;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.22) : AppTheme.valorantSurface,
          border: Border.all(color: isSelected ? color : AppTheme.outlineDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              SizedBox.square(
                dimension: 16,
                child: FadeInNetworkImage(url: icon, fit: BoxFit.contain),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkinRow extends StatelessWidget {
  const _SkinRow({required this.skin, required this.tier});

  final SkinPrice skin;
  final ContentTier? tier;

  @override
  Widget build(BuildContext context) {
    final color = tier?.color ?? Colors.white54;
    final tierIcon = tier?.displayIcon;

    return ClipPath(
      clipper: const DiagonalCutClipper(cut: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.valorantSurface,
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              height: 40,
              child: FadeInNetworkImage(url: skin.icon, fit: BoxFit.contain),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skin.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (tierIcon != null) ...[
                        SizedBox.square(
                          dimension: 12,
                          child: FadeInNetworkImage(url: tierIcon, fit: BoxFit.contain),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          '${skin.edition.label} · ${skin.weaponName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (skin.isFloor)
                      const Text('dès ', style: TextStyle(fontSize: 10.5, color: AppTheme.valorantMuted)),
                    const SizedBox.square(
                      dimension: 13,
                      child: FadeInNetworkImage(url: valorantPointsIcon, fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 4),
                    Text('${skin.price}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900)),
                  ],
                ),
                if (skin.isExact)
                  const Text(
                    'EN BOUTIQUE',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: Color(0xFFFFC25A),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
