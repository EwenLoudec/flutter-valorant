import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/async_list_view.dart';
import '../../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../../core/widgets/fade_in_network_image.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../../core/widgets/staggered_fade_slide.dart';
import '../../domain/weapon.dart';
import '../../providers/encyclopedia_providers.dart';
import 'category_filter_bar.dart';
import 'weapon_category_style.dart';
import 'weapon_detail_screen.dart';

class WeaponsTab extends ConsumerWidget {
  const WeaponsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weaponsAsync = ref.watch(weaponsProvider);
    final selectedCategory = ref.watch(weaponCategoryFilterProvider);

    return Column(
      children: [
        const CategoryFilterBar(),
        Expanded(
          child: AsyncListView<Weapon>(
            value: weaponsAsync,
            emptyMessage: 'Aucune arme trouvée.',
            builder: (context, allWeapons) {
              final weapons = selectedCategory == null
                  ? allWeapons
                  : allWeapons.where((w) => w.category == selectedCategory).toList();

              if (weapons.isEmpty) {
                return const Center(child: Text('Aucune arme pour cette catégorie.'));
              }

              return ListView.separated(
                key: ValueKey(selectedCategory),
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: weapons.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return StaggeredFadeSlide(
                    index: index,
                    child: _WeaponCard(weapon: weapons[index]),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WeaponCard extends StatelessWidget {
  const _WeaponCard({required this.weapon});

  final Weapon weapon;

  @override
  Widget build(BuildContext context) {
    final style = WeaponCategoryStyle.of(weapon.category);

    return PressableScale(
      onTap: () => Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 380),
          pageBuilder: (_, animation, _) => FadeTransition(
            opacity: animation,
            child: WeaponDetailScreen(weapon: weapon),
          ),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: style.color.withValues(alpha: 0.25), blurRadius: 16, spreadRadius: -6)],
        ),
        child: ClipPath(
          clipper: const DiagonalCutClipper(cut: 14),
          child: Container(
            height: 108,
            decoration: const BoxDecoration(color: AppTheme.valorantSurface),
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [style.color.withValues(alpha: 0.16), Colors.transparent],
                    ),
                  ),
                ),
                Positioned(
                  left: 100,
                  right: 12,
                  top: 8,
                  bottom: 8,
                  child: weapon.displayIcon != null
                      ? FadeInNetworkImage(url: weapon.displayIcon!, fit: BoxFit.contain, alignment: Alignment.center)
                      : const SizedBox(),
                ),
                Positioned(
                  left: 14,
                  top: 12,
                  child: Row(
                    children: [
                      Icon(style.icon, size: 13, color: style.color),
                      const SizedBox(width: 5),
                      Text(
                        style.label.toUpperCase(),
                        style: TextStyle(
                          color: style.color,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: 12,
                  child: Text(
                    weapon.displayName.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.3),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      border: Border.all(color: style.color.withValues(alpha: 0.6)),
                    ),
                    child: Text(
                      '${weapon.cost} ¤',
                      style: TextStyle(color: style.color, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
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
