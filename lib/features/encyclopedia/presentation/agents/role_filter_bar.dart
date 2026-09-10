import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/encyclopedia_providers.dart';
import 'agent_role_style.dart';

const List<String> kAgentRoles = ['Duelliste', 'Initiateur', 'Contrôleur', 'Sentinelle'];

class RoleFilterBar extends ConsumerWidget {
  const RoleFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRole = ref.watch(agentRoleFilterProvider);

    return SizedBox(
      height: 76,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _RoleFilterChip(
            label: 'TOUS',
            icon: Icons.apps_rounded,
            color: Colors.white,
            selected: selectedRole == null,
            onTap: () => ref.read(agentRoleFilterProvider.notifier).state = null,
          ),
          for (final role in kAgentRoles)
            _RoleFilterChip(
              label: role.toUpperCase(),
              icon: AgentRoleStyle.of(role).icon,
              color: AgentRoleStyle.of(role).color,
              selected: selectedRole == role,
              onTap: () => ref.read(agentRoleFilterProvider.notifier).state = role,
            ),
        ],
      ),
    );
  }
}

class _RoleFilterChip extends StatelessWidget {
  const _RoleFilterChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                color: selected ? color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
                border: Border.all(color: selected ? color : Colors.white24, width: selected ? 2 : 1),
                boxShadow: selected
                    ? [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 14, spreadRadius: -2)]
                    : null,
              ),
              child: Icon(icon, size: 20, color: selected ? color : Colors.white54),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: selected ? color : Colors.white38,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
