import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/async_list_view.dart';
import '../../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../../core/widgets/fade_in_network_image.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../../core/widgets/staggered_fade_slide.dart';
import '../../domain/agent.dart';
import '../../providers/encyclopedia_providers.dart';
import 'agent_detail_screen.dart';
import 'agent_role_style.dart';
import 'role_filter_bar.dart';

class AgentsTab extends ConsumerWidget {
  const AgentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentsAsync = ref.watch(agentsProvider);
    final selectedRole = ref.watch(agentRoleFilterProvider);

    return Column(
      children: [
        const RoleFilterBar(),
        Expanded(
          child: AsyncListView<Agent>(
            value: agentsAsync,
            emptyMessage: 'Aucun agent trouvé.',
            builder: (context, allAgents) {
              final agents = selectedRole == null
                  ? allAgents
                  : allAgents.where((agent) => agent.roleName == selectedRole).toList();

              if (agents.isEmpty) {
                return const Center(child: Text('Aucun agent pour ce rôle.'));
              }

              return GridView.builder(
                // Re-keying on the filter restarts the staggered entrance animation.
                key: ValueKey(selectedRole),
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.72,
                ),
                itemCount: agents.length,
                itemBuilder: (context, index) {
                  return StaggeredFadeSlide(
                    index: index,
                    child: _AgentTile(agent: agents[index]),
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

class _AgentTile extends StatelessWidget {
  const _AgentTile({required this.agent});

  final Agent agent;

  @override
  Widget build(BuildContext context) {
    final role = AgentRoleStyle.of(agent.roleName);
    final portrait = agent.fullPortrait ?? agent.displayIcon;

    return PressableScale(
      onTap: () => Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 380),
          pageBuilder: (_, animation, _) => FadeTransition(
            opacity: animation,
            child: AgentDetailScreen(agent: agent),
          ),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: role.color.withValues(alpha: 0.35), blurRadius: 18, spreadRadius: -6)],
        ),
        child: ClipPath(
          clipper: const DiagonalCutClipper(cut: 12),
          child: Container(
            decoration: const BoxDecoration(color: AppTheme.valorantSurface),
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.1,
                      colors: [role.color.withValues(alpha: 0.22), Colors.transparent],
                    ),
                  ),
                ),
                if (portrait != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Hero(
                      tag: 'agent-portrait-${agent.uuid}',
                      child: FadeInNetworkImage(
                        url: portrait,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                      border: Border.all(color: role.color, width: 1),
                    ),
                    child: Icon(role.icon, size: 12, color: role.color),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 18, 6, 8),
                      child: Text(
                        agent.displayName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, letterSpacing: 0.4),
                      ),
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
