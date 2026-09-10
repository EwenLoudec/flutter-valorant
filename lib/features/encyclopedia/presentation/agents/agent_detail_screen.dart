import 'package:flutter/material.dart';

import '../../domain/agent.dart';

class AgentDetailScreen extends StatelessWidget {
  const AgentDetailScreen({super.key, required this.agent});

  final Agent agent;

  Color _parseGradientColor(String hex) {
    if (hex.length < 6) return Colors.black;
    final value = int.tryParse(hex.substring(0, 6), radix: 16) ?? 0;
    return Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = agent.backgroundGradientColors.map(_parseGradientColor).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(agent.displayName),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: gradientColors.isNotEmpty
                        ? gradientColors
                        : [Colors.black, Colors.black87],
                  ),
                ),
                child: agent.fullPortrait != null
                    ? Image.network(agent.fullPortrait!, fit: BoxFit.contain, alignment: Alignment.topCenter)
                    : null,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Chip(label: Text(agent.roleName)),
                const SizedBox(height: 12),
                Text(agent.description, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 20),
                Text('Capacités', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...agent.abilities.map((ability) => _AbilityTile(ability: ability)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AbilityTile extends StatelessWidget {
  const _AbilityTile({required this.ability});

  final AgentAbility ability;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ability.displayIcon != null)
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.network(ability.displayIcon!),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ability.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(ability.description, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
