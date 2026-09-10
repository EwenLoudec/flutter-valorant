import 'package:flutter/material.dart';

class WeaponCategoryStyle {
  const WeaponCategoryStyle({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  static WeaponCategoryStyle of(String category) {
    switch (category) {
      case 'Sidearm':
        return const WeaponCategoryStyle(label: 'Pistolet', color: Color(0xFF9AA5B1), icon: Icons.adjust);
      case 'SMG':
        return const WeaponCategoryStyle(label: 'Mitraillette', color: Color(0xFF4FD1C5), icon: Icons.blur_on);
      case 'Shotgun':
        return const WeaponCategoryStyle(label: 'Fusil à pompe', color: Color(0xFFFF9F45), icon: Icons.grain);
      case 'Rifle':
        return const WeaponCategoryStyle(label: 'Fusil', color: Color(0xFFFF4655), icon: Icons.view_column);
      case 'Sniper':
        return const WeaponCategoryStyle(label: 'Sniper', color: Color(0xFFB667F1), icon: Icons.gps_fixed);
      case 'Heavy':
        return const WeaponCategoryStyle(label: 'Lourd', color: Color(0xFFF2B90C), icon: Icons.whatshot);
      default:
        return const WeaponCategoryStyle(label: 'Arme', color: Colors.white70, icon: Icons.help_outline);
    }
  }
}
