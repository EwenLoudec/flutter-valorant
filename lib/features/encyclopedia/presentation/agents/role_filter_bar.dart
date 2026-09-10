import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/filter_chip_bar.dart';
import '../../providers/encyclopedia_providers.dart';
import 'agent_role_style.dart';

const List<String> kAgentRoles = ['Duelliste', 'Initiateur', 'Contrôleur', 'Sentinelle'];

class RoleFilterBar extends ConsumerWidget {
  const RoleFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRole = ref.watch(agentRoleFilterProvider);

    return FilterChipBar(
      selected: selectedRole,
      onSelected: (value) => ref.read(agentRoleFilterProvider.notifier).state = value,
      options: [
        const FilterChipOption(value: null, label: 'TOUS', icon: Icons.apps_rounded, color: Colors.white),
        for (final role in kAgentRoles)
          FilterChipOption(
            value: role,
            label: role.toUpperCase(),
            icon: AgentRoleStyle.of(role).icon,
            color: AgentRoleStyle.of(role).color,
          ),
      ],
    );
  }
}
