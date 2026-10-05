import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../core/widgets/fade_in_network_image.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../../encyclopedia/domain/agent.dart';
import '../../encyclopedia/domain/contract.dart';
import '../../encyclopedia/providers/encyclopedia_providers.dart';
import '../domain/reward_catalog.dart';
import '../providers/collection_providers.dart';

/// Agent gear, event passes and battle passes, sorted by kind.
class ContractsScreen extends ConsumerWidget {
  const ContractsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractsAsync = ref.watch(contractsProvider);
    final agents = ref.watch(agentsProvider).value ?? const <Agent>[];
    final seasonStarts = ref.watch(seasonStartsProvider).value ?? const <String, DateTime>{};
    final agentsById = {for (final agent in agents) agent.uuid: agent};

    return DefaultTabController(
      length: ContractKind.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('CONTRATS'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final kind in ContractKind.values) Tab(text: kind.label.toUpperCase())],
          ),
        ),
        body: contractsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Impossible de charger les contrats : $error', textAlign: TextAlign.center),
            ),
          ),
          data: (contracts) => TabBarView(
            children: [
              for (final kind in ContractKind.values)
                _ContractList(
                  contracts: _sorted(
                    [for (final contract in contracts) if (contract.kind == kind) contract],
                    kind,
                    agentsById,
                    seasonStarts,
                  ),
                  agentsById: agentsById,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Agents alphabetically, seasons most recent first.
  static List<Contract> _sorted(
    List<Contract> contracts,
    ContractKind kind,
    Map<String, Agent> agentsById,
    Map<String, DateTime> seasonStarts,
  ) {
    switch (kind) {
      case ContractKind.agent:
        contracts.sort((a, b) {
          final aName = agentsById[a.relationUuid]?.displayName ?? a.displayName;
          final bName = agentsById[b.relationUuid]?.displayName ?? b.displayName;
          return aName.compareTo(bName);
        });
      case ContractKind.season:
      case ContractKind.event:
        contracts.sort((a, b) {
          final aStart = seasonStarts[a.relationUuid];
          final bStart = seasonStarts[b.relationUuid];
          if (aStart != null && bStart != null) return bStart.compareTo(aStart);
          if (aStart != null) return -1;
          if (bStart != null) return 1;
          return a.displayName.compareTo(b.displayName);
        });
    }
    return contracts;
  }
}

class _ContractList extends StatelessWidget {
  const _ContractList({required this.contracts, required this.agentsById});

  final List<Contract> contracts;
  final Map<String, Agent> agentsById;

  @override
  Widget build(BuildContext context) {
    if (contracts.isEmpty) return const Center(child: Text('Aucun contrat.'));

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      itemCount: contracts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final contract = contracts[index];
        final agent = agentsById[contract.relationUuid];
        final icon = agent?.displayIcon;

        return PressableScale(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ContractDetailScreen(contract: contract)),
          ),
          child: ClipPath(
            clipper: const DiagonalCutClipper(cut: 8),
            child: Container(
              color: AppTheme.valorantSurface,
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: icon == null
                        ? Icon(
                            contract.kind == ContractKind.season ? Icons.workspace_premium_outlined : Icons.event,
                            color: Colors.white38,
                          )
                        : FadeInNetworkImage(url: icon, fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contract.displayName.toUpperCase(),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_levels(contract.levelCount)} · ${contract.rewards.length} '
                          'récompense${contract.rewards.length > 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 10.5, color: AppTheme.valorantMuted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.valorantMuted),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Every reward of one contract, level by level.
class ContractDetailScreen extends ConsumerWidget {
  const ContractDetailScreen({super.key, required this.contract});

  final Contract contract;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(rewardCatalogProvider);

    return Scaffold(
      appBar: AppBar(title: Text(contract.displayName.toUpperCase())),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _RewardList(contract: contract, catalog: RewardCatalog()),
        data: (catalog) => _RewardList(contract: contract, catalog: catalog),
      ),
    );
  }
}

class _RewardList extends StatelessWidget {
  const _RewardList({required this.contract, required this.catalog});

  final Contract contract;
  final RewardCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final rewards = [...contract.rewards.where((reward) => !reward.isFree), ...contract.rewards.where((reward) => reward.isFree)];
    if (rewards.isEmpty) return const Center(child: Text('Ce contrat ne liste aucune récompense.'));

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      itemCount: rewards.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            '${_levels(contract.levelCount)} · ${_formatXp(contract.totalXp)} XP au total',
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.valorantMuted),
          );
        }
        final reward = rewards[index - 1];
        return _RewardRow(reward: reward, resolved: catalog.resolve(reward));
      },
    );
  }

  static String _formatXp(int xp) {
    final digits = xp.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(' ');
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.reward, required this.resolved});

  final ContractReward reward;
  final ResolvedReward resolved;

  @override
  Widget build(BuildContext context) {
    final image = resolved.imageUrl;
    final level = reward.level;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppTheme.valorantSurface,
        border: Border(
          left: BorderSide(
            color: reward.isHighlighted ? AppTheme.valorantRed : AppTheme.outlineDark,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              reward.isFree ? 'GRAT.' : '$level',
              style: TextStyle(
                fontSize: reward.isFree ? 9.5 : 12,
                fontWeight: FontWeight.w900,
                color: reward.isFree ? const Color(0xFF2FBF8F) : Colors.white70,
              ),
            ),
          ),
          SizedBox(
            width: 52,
            height: 40,
            child: image == null
                ? Icon(Icons.card_giftcard, color: Colors.white.withValues(alpha: 0.2))
                : FadeInNetworkImage(url: image, fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resolved.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  reward.type.label.toUpperCase(),
                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppTheme.valorantMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _levels(int count) => '$count niveau${count > 1 ? 'x' : ''}';
