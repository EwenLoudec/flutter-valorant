import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/async_list_view.dart';
import '../../domain/agent.dart';
import '../../providers/encyclopedia_providers.dart';
import 'agent_detail_screen.dart';

class AgentsTab extends ConsumerWidget {
  const AgentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentsAsync = ref.watch(agentsProvider);

    return AsyncListView<Agent>(
      value: agentsAsync,
      emptyMessage: 'Aucun agent trouvé.',
      builder: (context, agents) {
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.78,
          ),
          itemCount: agents.length,
          itemBuilder: (context, index) {
            final agent = agents[index];
            return _AgentTile(agent: agent);
          },
        );
      },
    );
  }
}

class _AgentTile extends StatelessWidget {
  const _AgentTile({required this.agent});

  final Agent agent;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AgentDetailScreen(agent: agent)),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: agent.displayIcon != null
                  ? Image.network(agent.displayIcon!, fit: BoxFit.cover)
                  : const Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            agent.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          Text(
            agent.roleName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
