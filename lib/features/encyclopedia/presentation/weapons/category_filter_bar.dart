import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/filter_chip_bar.dart';
import '../../providers/encyclopedia_providers.dart';
import 'weapon_category_style.dart';

const List<String> kWeaponCategories = ['Sidearm', 'SMG', 'Shotgun', 'Rifle', 'Sniper', 'Heavy'];

class CategoryFilterBar extends ConsumerWidget {
  const CategoryFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(weaponCategoryFilterProvider);

    return FilterChipBar(
      selected: selectedCategory,
      onSelected: (value) => ref.read(weaponCategoryFilterProvider.notifier).state = value,
      options: [
        const FilterChipOption(value: null, label: 'TOUTES', icon: Icons.apps_rounded, color: Colors.white),
        for (final category in kWeaponCategories)
          FilterChipOption(
            value: category,
            label: WeaponCategoryStyle.of(category).label.toUpperCase(),
            icon: WeaponCategoryStyle.of(category).icon,
            color: WeaponCategoryStyle.of(category).color,
          ),
      ],
    );
  }
}
