import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../../core/widgets/fade_in_network_image.dart';
import '../../../../core/widgets/inline_video_preview.dart';
import '../../../../core/widgets/staggered_fade_slide.dart';
import '../../domain/agent.dart';
import '../../providers/encyclopedia_providers.dart';
import 'agent_role_style.dart';

class AgentDetailScreen extends ConsumerWidget {
  const AgentDetailScreen({super.key, required this.agent});

  final Agent agent;

  Color _parseGradientColor(String hex) {
    if (hex.length < 6) return Colors.black;
    final value = int.tryParse(hex.substring(0, 6), radix: 16) ?? 0;
    return Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = AgentRoleStyle.of(agent.roleName);
    final portrait = agent.fullPortrait ?? agent.displayIcon;
    final gradientColors = agent.backgroundGradientColors.map(_parseGradientColor).toList();
    final videosByAgent = ref.watch(abilityVideosProvider).asData?.value;
    final agentVideos = videosByAgent?[agent.uuid] ?? const <String, String>{};

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 340,
            backgroundColor: AppTheme.valorantDark,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
              title: Text(agent.displayName.toUpperCase(), style: const TextStyle(letterSpacing: 0.5)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: gradientColors.isNotEmpty
                            ? [...gradientColors, AppTheme.valorantDark]
                            : [Colors.black87, AppTheme.valorantDark],
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.2,
                        colors: [role.color.withValues(alpha: 0.28), Colors.transparent],
                      ),
                    ),
                  ),
                  if (portrait != null)
                    Hero(
                      tag: 'agent-portrait-${agent.uuid}',
                      child: FadeInNetworkImage(
                        url: portrait,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
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
                          colors: [Colors.transparent, AppTheme.valorantDark],
                        ),
                      ),
                      child: const SizedBox(height: 90),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SlashDivider(color: role.color),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(role.icon, size: 16, color: role.color),
                    const SizedBox(width: 6),
                    Text(
                      agent.roleName.toUpperCase(),
                      style: TextStyle(
                        color: role.color,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(agent.description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(width: 4, height: 16, color: role.color),
                    const SizedBox(width: 8),
                    Text(
                      'CAPACITÉS',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final (index, ability) in agent.abilities.indexed)
                  StaggeredFadeSlide(
                    index: index,
                    step: const Duration(milliseconds: 70),
                    child: _AbilityTile(
                      ability: ability,
                      roleColor: role.color,
                      videoUrl: agentVideos[ability.displayName.toUpperCase()],
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlashDivider extends StatelessWidget {
  const _SlashDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value,
            child: Row(
              children: [
                Container(width: 22, height: 3, color: color),
                const SizedBox(width: 6),
                Container(height: 3, color: Colors.white24, width: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AbilityTile extends StatefulWidget {
  const _AbilityTile({required this.ability, required this.roleColor, required this.videoUrl});

  final AgentAbility ability;
  final Color roleColor;
  final String? videoUrl;

  @override
  State<_AbilityTile> createState() => _AbilityTileState();
}

class _AbilityTileState extends State<_AbilityTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ability = widget.ability;
    final roleColor = widget.roleColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipPath(
        clipper: const DiagonalCutClipper(cut: 10),
        child: Container(
          color: AppTheme.valorantSurface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ability.displayIcon != null)
                        Container(
                          width: 42,
                          height: 42,
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.14),
                            border: Border.all(color: roleColor.withValues(alpha: 0.5)),
                          ),
                          child: FadeInNetworkImage(url: ability.displayIcon!, fit: BoxFit.contain),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ability.displayName.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: roleColor,
                                letterSpacing: 0.3,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ability.description,
                              maxLines: _expanded ? null : 2,
                              overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        child: Icon(Icons.keyboard_arrow_down, color: roleColor),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: _expanded && widget.videoUrl != null
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: ClipPath(
                          clipper: const DiagonalCutClipper(cut: 8),
                          child: InlineVideoPreview(url: widget.videoUrl!),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
