import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fade_in_network_image.dart';
import '../../encyclopedia/domain/agent.dart';
import '../../encyclopedia/providers/encyclopedia_providers.dart';

typedef AbilityChoice = ({Agent agent, AgentAbility ability});

/// Two-step picker: every agent of the catalogue, then their abilities.
Future<AbilityChoice?> showAbilityPicker(BuildContext context, {String? initialAgentName}) {
  return showModalBottomSheet<AbilityChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.valorantSurface,
    shape: const RoundedRectangleBorder(),
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.85,
      child: _AbilityPicker(initialAgentName: initialAgentName),
    ),
  );
}

class _AbilityPicker extends ConsumerStatefulWidget {
  const _AbilityPicker({this.initialAgentName});

  final String? initialAgentName;

  @override
  ConsumerState<_AbilityPicker> createState() => _AbilityPickerState();
}

class _AbilityPickerState extends ConsumerState<_AbilityPicker> {
  Agent? _agent;

  @override
  Widget build(BuildContext context) {
    final agents = ref.watch(agentsProvider).value ?? const <Agent>[];
    final agent = _agent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            children: [
              if (agent != null)
                IconButton(
                  onPressed: () => setState(() => _agent = null),
                  icon: const Icon(Icons.arrow_back, size: 20),
                ),
              Expanded(
                child: Text(
                  agent == null ? 'CHOISIS UN AGENT' : 'COMPÉTENCE DE ${agent.displayName.toUpperCase()}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
        ),
        Expanded(
          child: agent == null ? _buildAgentGrid(agents) : _buildAbilityList(agent),
        ),
      ],
    );
  }

  Widget _buildAgentGrid(List<Agent> agents) {
    if (agents.isEmpty) return const Center(child: CircularProgressIndicator());

    return GridView.count(
      crossAxisCount: 4,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.78,
      children: [
        for (final agent in agents)
          GestureDetector(
            onTap: () => setState(() => _agent = agent),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      border: Border.all(
                        color: agent.displayName == widget.initialAgentName
                            ? AppTheme.valorantRed
                            : AppTheme.outlineDark,
                      ),
                    ),
                    child: agent.displayIcon == null
                        ? const Icon(Icons.person, color: Colors.white24)
                        : FadeInNetworkImage(url: agent.displayIcon!, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  agent.displayName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAbilityList(Agent agent) {
    final abilities = agent.abilities.where((ability) => ability.slot != 'Passive').toList();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: abilities.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final ability = abilities[index];

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: SizedBox(
            width: 34,
            height: 34,
            child: ability.displayIcon == null
                ? const Icon(Icons.bolt, color: Colors.white24)
                : FadeInNetworkImage(url: ability.displayIcon!, fit: BoxFit.contain),
          ),
          title: Text(
            ability.displayName,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            _keyLabel(ability.slot),
            style: const TextStyle(fontSize: 11, color: AppTheme.valorantMuted),
          ),
          onTap: () => Navigator.of(context).pop((agent: agent, ability: ability)),
        );
      },
    );
  }

  String _keyLabel(String slot) => switch (slot) {
    'Ability1' => 'Touche Q',
    'Ability2' => 'Touche E',
    'Grenade' => 'Touche C',
    'Ultimate' => 'Ultime (X)',
    _ => slot,
  };
}
