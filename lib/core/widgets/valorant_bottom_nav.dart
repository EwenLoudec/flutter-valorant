import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ValorantNavItem {
  const ValorantNavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Bottom navigation bar styled after Valorant's UI: dark, angled active
/// indicator, red accent.
class ValorantBottomNav extends StatelessWidget {
  const ValorantBottomNav({super.key, required this.items, required this.currentIndex, required this.onTap});

  final List<ValorantNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppTheme.valorantDark,
        border: Border(top: BorderSide(color: AppTheme.outlineDark)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (final (index, item) in items.indexed)
                Expanded(
                  child: _NavButton(
                    item: item,
                    selected: index == currentIndex,
                    onTap: () => onTap(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.selected, required this.onTap});

  final ValorantNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.valorantRed : Colors.white38;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: 3,
            width: selected ? 26 : 0,
            margin: const EdgeInsets.only(bottom: 8),
            color: AppTheme.valorantRed,
          ),
          Icon(item.icon, size: 22, color: color),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: color),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}
