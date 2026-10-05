import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../core/widgets/fade_in_network_image.dart';
import '../../../core/widgets/valorant_input.dart';
import '../../encyclopedia/data/map_meta_data.dart';
import '../../encyclopedia/domain/agent.dart';
import '../../encyclopedia/domain/game_map.dart';
import '../../encyclopedia/presentation/agents/agent_role_style.dart';
import '../../encyclopedia/providers/encyclopedia_providers.dart';
import '../domain/composition.dart';

const _goodColor = Color(0xFF2FBF8F);

/// Pick five agents for a map and see whether the roles are covered, and how
/// the line-up compares with the map's meta composition.
class CompositionBuilderScreen extends ConsumerStatefulWidget {
  const CompositionBuilderScreen({super.key, this.initialMapName});

  final String? initialMapName;

  @override
  ConsumerState<CompositionBuilderScreen> createState() => _CompositionBuilderScreenState();
}

class _CompositionBuilderScreenState extends ConsumerState<CompositionBuilderScreen> {
  late String? _mapName = widget.initialMapName;
  final _pickedUuids = <String>[];

  void _toggle(Agent agent) {
    setState(() {
      if (_pickedUuids.remove(agent.uuid)) return;
      if (_pickedUuids.length < CompositionAnalysis.teamSize) _pickedUuids.add(agent.uuid);
    });
  }

  void _applyMeta(List<Agent> agents) {
    final meta = kMapMetaData[_mapName]?.metaComposition;
    if (meta == null) return;
    final byName = {for (final agent in agents) agent.displayName.toLowerCase(): agent};
    setState(() {
      _pickedUuids
        ..clear()
        ..addAll([
          for (final entry in meta.agents)
            if (byName[entry.agentName.toLowerCase()] case final agent?) agent.uuid,
        ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final agents = ref.watch(agentsProvider).value ?? const <Agent>[];
    final maps = ref.watch(mapsProvider).value ?? const <GameMap>[];
    final byUuid = {for (final agent in agents) agent.uuid: agent};
    final picked = [for (final uuid in _pickedUuids) ?byUuid[uuid]];
    final meta = kMapMetaData[_mapName]?.metaComposition;
    final analysis = CompositionAnalysis.of(picked, meta: meta);
    final mapNames = [for (final map in maps) map.displayName];

    return Scaffold(
      appBar: AppBar(
        title: const Text('COMPOSITION'),
        actions: [
          if (_pickedUuids.isNotEmpty)
            IconButton(
              tooltip: 'Vider',
              onPressed: () => setState(_pickedUuids.clear),
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: agents.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                DropdownButtonFormField<String?>(
                  // Rebuilt once the maps arrive, so a map passed in is shown.
                  key: ValueKey(mapNames.length),
                  initialValue: mapNames.contains(_mapName) ? _mapName : null,
                  isExpanded: true,
                  decoration: valorantInputDecoration(hint: 'Choisir une carte'),
                  dropdownColor: AppTheme.valorantSurface,
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Toutes cartes')),
                    for (final name in mapNames) DropdownMenuItem<String?>(value: name, child: Text(name)),
                  ],
                  onChanged: (value) => setState(() => _mapName = value),
                ),
                const SizedBox(height: 14),
                _PickedRow(picked: picked, onRemove: _toggle),
                const SizedBox(height: 12),
                _AnalysisCard(analysis: analysis),
                if (meta != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _applyMeta(agents),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: AppTheme.outlineDark),
                      shape: const RoundedRectangleBorder(),
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: Text(
                      'PARTIR DE LA COMPO MÉTA (${meta.winRatePercent} % WR)',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                for (final role in AgentRoles.all) ...[
                  _RoleHeader(role: role),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final agent in agents)
                        if (agent.roleName == role)
                          _AgentChip(
                            agent: agent,
                            isPicked: _pickedUuids.contains(agent.uuid),
                            isDisabled: !_pickedUuids.contains(agent.uuid) &&
                                _pickedUuids.length >= CompositionAnalysis.teamSize,
                            onTap: () => _toggle(agent),
                          ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
    );
  }
}

class _PickedRow extends StatelessWidget {
  const _PickedRow({required this.picked, required this.onRemove});

  final List<Agent> picked;
  final ValueChanged<Agent> onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var slot = 0; slot < CompositionAnalysis.teamSize; slot++) ...[
          if (slot > 0) const SizedBox(width: 6),
          Expanded(
            child: AspectRatio(
              aspectRatio: 0.8,
              child: slot < picked.length
                  ? _Slot(agent: picked[slot], onTap: () => onRemove(picked[slot]))
                  : const _Slot(),
            ),
          ),
        ],
      ],
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({this.agent, this.onTap});

  final Agent? agent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final agent = this.agent;
    final icon = agent?.displayIcon;
    final color = agent == null ? AppTheme.outlineDark : AgentRoleStyle.of(agent.roleName).color;

    return GestureDetector(
      onTap: onTap,
      child: ClipPath(
        clipper: const DiagonalCutClipper(cut: 6),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.valorantSurface,
            border: Border(bottom: BorderSide(color: color, width: 3)),
          ),
          padding: const EdgeInsets.all(4),
          child: agent == null
              ? const Icon(Icons.add, color: Colors.white24)
              : Column(
                  children: [
                    Expanded(
                      child: icon == null
                          ? const Icon(Icons.person, color: Colors.white24)
                          : FadeInNetworkImage(url: icon, fit: BoxFit.contain),
                    ),
                    Text(
                      agent.displayName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({required this.analysis});

  final CompositionAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final color = analysis.isBalanced ? _goodColor : AppTheme.valorantRed;

    return ClipPath(
      clipper: const DiagonalCutClipper(cut: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.valorantSurface,
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                for (final role in AgentRoles.all)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AgentRoleStyle.of(role).icon, size: 14, color: AgentRoleStyle.of(role).color),
                      const SizedBox(width: 4),
                      Text(
                        '$role ${analysis.roleCounts[role] ?? 0}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (analysis.isBalanced)
              const _IssueLine(
                icon: Icons.check_circle_outline,
                color: _goodColor,
                text: 'Composition équilibrée : chaque rôle clé est couvert.',
              ),
            for (final issue in analysis.issues)
              _IssueLine(
                icon: issue.level == CompositionIssueLevel.warning ? Icons.warning_amber_rounded : Icons.info_outline,
                color: issue.level == CompositionIssueLevel.warning ? const Color(0xFFF2B90C) : Colors.white54,
                text: issue.message,
              ),
            if (analysis.metaSize > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${analysis.metaMatches} / ${analysis.metaSize} agents en commun avec la compo méta de la carte.',
                style: const TextStyle(fontSize: 11.5, color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IssueLine extends StatelessWidget {
  const _IssueLine({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 7),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, height: 1.4))),
        ],
      ),
    );
  }
}

class _RoleHeader extends StatelessWidget {
  const _RoleHeader({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final style = AgentRoleStyle.of(role);
    return Row(
      children: [
        Icon(style.icon, size: 15, color: style.color),
        const SizedBox(width: 6),
        Text(
          role.toUpperCase(),
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: style.color, letterSpacing: 0.6),
        ),
      ],
    );
  }
}

class _AgentChip extends StatelessWidget {
  const _AgentChip({required this.agent, required this.isPicked, required this.isDisabled, required this.onTap});

  final Agent agent;
  final bool isPicked;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = agent.displayIcon;
    final color = AgentRoleStyle.of(agent.roleName).color;

    return Opacity(
      opacity: isDisabled ? 0.35 : 1,
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: Container(
          width: 64,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isPicked ? color.withValues(alpha: 0.18) : AppTheme.valorantSurface,
            border: Border.all(color: isPicked ? color : AppTheme.outlineDark, width: isPicked ? 2 : 1),
          ),
          child: Column(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: icon == null
                    ? const Icon(Icons.person, color: Colors.white24)
                    : FadeInNetworkImage(url: icon, fit: BoxFit.contain),
              ),
              const SizedBox(height: 3),
              Text(
                agent.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
