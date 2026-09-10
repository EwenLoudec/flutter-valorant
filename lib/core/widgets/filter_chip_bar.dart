import 'package:flutter/material.dart';

class FilterChipOption {
  const FilterChipOption({required this.value, required this.label, required this.icon, required this.color});

  /// null represents the "show everything" option.
  final String? value;
  final String label;
  final IconData icon;
  final Color color;
}

/// Horizontal row of icon chips used to filter a list by category — the
/// same treatment Valorant uses for its role/weapon-category filters.
class FilterChipBar extends StatelessWidget {
  const FilterChipBar({super.key, required this.options, required this.selected, required this.onSelected});

  final List<FilterChipOption> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          for (final option in options)
            _FilterChip(
              option: option,
              isSelected: selected == option.value,
              onTap: () => onSelected(option.value),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.option, required this.isSelected, required this.onTap});

  final FilterChipOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = option.color;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
                border: Border.all(color: isSelected ? color : Colors.white24, width: isSelected ? 2 : 1),
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 14, spreadRadius: -2)]
                    : null,
              ),
              child: Icon(option.icon, size: 20, color: isSelected ? color : Colors.white54),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: isSelected ? color : Colors.white38,
              ),
              child: Text(option.label),
            ),
          ],
        ),
      ),
    );
  }
}
