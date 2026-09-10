import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/fade_in_network_image.dart';
import '../../domain/weapon.dart';
import '../../providers/encyclopedia_providers.dart';
import 'weapon_category_style.dart';
import 'weapon_skins_carousel.dart';

class WeaponDetailScreen extends ConsumerWidget {
  const WeaponDetailScreen({super.key, required this.weapon});

  final Weapon weapon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = WeaponCategoryStyle.of(weapon.category);
    final contentTiers = ref.watch(contentTiersProvider).asData?.value ?? const {};
    final skinsAsync = ref.watch(weaponSkinsProvider(weapon.uuid));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            backgroundColor: AppTheme.valorantDark,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
              title: Text(weapon.displayName.toUpperCase(), style: const TextStyle(letterSpacing: 0.5)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.1,
                        colors: [style.color.withValues(alpha: 0.22), AppTheme.valorantDark],
                      ),
                    ),
                  ),
                  if (weapon.displayIcon != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
                      child: FadeInNetworkImage(url: weapon.displayIcon!, fit: BoxFit.contain),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Icon(style.icon, size: 16, color: style.color),
                    const SizedBox(width: 6),
                    Text(
                      style.label.toUpperCase(),
                      style: TextStyle(color: style.color, fontWeight: FontWeight.w800, letterSpacing: 1, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatChip(label: 'Prix', value: '${weapon.cost} ¤', color: style.color),
                    if (weapon.fireRate != null)
                      _StatChip(label: 'Cadence de tir', value: '${weapon.fireRate}/s', color: style.color),
                    if (weapon.magazineSize != null)
                      _StatChip(label: 'Chargeur', value: '${weapon.magazineSize} balles', color: style.color),
                  ],
                ),
                if (weapon.damageRanges.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(width: 4, height: 16, color: style.color),
                      const SizedBox(width: 8),
                      Text(
                        'DÉGÂTS PAR DISTANCE',
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _DamageTable(ranges: weapon.damageRanges),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(width: 4, height: 16, color: style.color),
                    const SizedBox(width: 8),
                    Text(
                      skinsAsync.asData != null ? 'SKINS (${skinsAsync.asData!.value.length})' : 'SKINS',
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.6),
                    ),
                    const Spacer(),
                    Icon(Icons.swipe, size: 16, color: Colors.white38),
                    const SizedBox(width: 4),
                    const Text('Glissez', style: TextStyle(fontSize: 11, color: Colors.white38)),
                  ],
                ),
                const SizedBox(height: 10),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: skinsAsync.when(
              data: (skins) => skins.isEmpty
                  ? const SizedBox()
                  : WeaponSkinsCarousel(skins: skins, contentTiers: contentTiers, accentColor: style.color),
              loading: () => const SizedBox(
                height: 340,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SizedBox(
                height: 120,
                child: Center(child: Text('Impossible de charger les skins : $error')),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.valorantSurface,
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DamageTable extends StatelessWidget {
  const _DamageTable({required this.ranges});

  final List<DamageRange> ranges;

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: const Color(0xFF2B343C)),
      columnWidths: const {0: FlexColumnWidth(1.4)},
      children: [
        const TableRow(
          decoration: BoxDecoration(color: AppTheme.valorantSurface),
          children: [
            _Cell('Distance', header: true),
            _Cell('Tête', header: true),
            _Cell('Corps', header: true),
            _Cell('Jambes', header: true),
          ],
        ),
        for (final range in ranges)
          TableRow(
            children: [
              _Cell(
                '${range.rangeStartMeters.toInt()}-${range.rangeEndMeters == 0 ? '∞' : range.rangeEndMeters.toInt()}m',
              ),
              _Cell(range.headDamage.toStringAsFixed(0)),
              _Cell(range.bodyDamage.toStringAsFixed(0)),
              _Cell(range.legDamage.toStringAsFixed(0)),
            ],
          ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.header = false});

  final String text;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(text, style: TextStyle(fontWeight: header ? FontWeight.bold : FontWeight.normal)),
    );
  }
}
