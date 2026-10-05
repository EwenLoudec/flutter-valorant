import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/match_detail.dart';
import 'match_detail_screen.dart';
import 'profile_section.dart';

IconData _resultIcon(MatchRound round) => switch (round.result.toLowerCase()) {
  'bomb detonated' || 'detonate' => Icons.local_fire_department,
  'bomb defused' || 'defuse' => Icons.handyman_outlined,
  'round timer expired' || 'time expired' => Icons.timer_outlined,
  _ => Icons.close,
};

/// The rounds in order: who took each one, how, and on which side.
class MatchRoundsSection extends StatelessWidget {
  const MatchRoundsSection({super.key, required this.detail});

  final MatchDetail detail;

  @override
  Widget build(BuildContext context) {
    final team = detail.playerTeamId!;

    return ProfileSection(
      title: 'Manches',
      child: ProfileCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 4,
              runSpacing: 6,
              children: [
                for (final round in detail.rounds)
                  _RoundChip(round: round, isWon: round.isWonBy(team), side: detail.playerSide(round.index)),
              ],
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _Legend(icon: Icons.close, label: 'Élimination'),
                _Legend(icon: Icons.local_fire_department, label: 'Spike explosé'),
                _Legend(icon: Icons.handyman_outlined, label: 'Désamorcé'),
                _Legend(icon: Icons.timer_outlined, label: 'Temps écoulé'),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Vert : manche gagnée par ton équipe · rouge : perdue. A / D : ton camp.',
              style: TextStyle(fontSize: 10.5, color: AppTheme.valorantMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundChip extends StatelessWidget {
  const _RoundChip({required this.round, required this.isWon, required this.side});

  final MatchRound round;
  final bool isWon;
  final RoundSide? side;

  @override
  Widget build(BuildContext context) {
    final color = isWon ? matchWinColor : AppTheme.valorantRed;
    final side = this.side;

    return Tooltip(
      message: [
        'Manche ${round.number}',
        isWon ? 'gagnée' : 'perdue',
        round.resultLabel,
        if (round.plantSite != null) 'spike posé en ${round.plantSite}',
        if (side != null) side.label.toLowerCase(),
      ].join(' · '),
      child: Container(
        width: 30,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          border: Border.all(color: color.withValues(alpha: 0.7)),
        ),
        child: Column(
          children: [
            Text(
              '${round.number}',
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white70),
            ),
            const SizedBox(height: 2),
            Icon(_resultIcon(round), size: 13, color: color),
            const SizedBox(height: 2),
            Text(
              switch (side) {
                RoundSide.attack => 'A',
                RoundSide.defense => 'D',
                null => '·',
              },
              style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: AppTheme.valorantMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white54),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.white70)),
      ],
    );
  }
}

/// Round by round, what each team could afford — the reason behind many
/// lost rounds.
class MatchEconomySection extends StatelessWidget {
  const MatchEconomySection({super.key, required this.detail});

  final MatchDetail detail;

  @override
  Widget build(BuildContext context) {
    final team = detail.playerTeamId!;
    final enemy = detail.enemyTeamId;

    final rows = <_EconomyRowData>[];
    final wins = <BuyType, int>{};
    final played = <BuyType, int>{};
    for (final round in detail.rounds) {
      final own = detail.buyOf(team, round.index);
      if (own == null) continue;
      final isWon = round.isWonBy(team);
      rows.add(
        _EconomyRowData(
          round: round,
          own: own,
          enemy: enemy == null ? null : detail.buyOf(enemy, round.index),
          ownLoadout: round.averageLoadoutOf(team),
          isWon: isWon,
        ),
      );
      played[own] = (played[own] ?? 0) + 1;
      if (isWon) wins[own] = (wins[own] ?? 0) + 1;
    }

    return ProfileSection(
      title: 'Économie',
      child: ProfileCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                for (final type in BuyType.values)
                  if ((played[type] ?? 0) > 0)
                    Text(
                      '${type.label} : ${wins[type] ?? 0}/${played[type]} gagnées',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white70),
                    ),
              ],
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                SizedBox(width: 30, child: Text('R.', style: _headerStyle)),
                Expanded(child: Text('TON ÉQUIPE', style: _headerStyle)),
                Expanded(child: Text('ADVERSAIRES', style: _headerStyle)),
                SizedBox(width: 22),
              ],
            ),
            const Divider(height: 10),
            for (final row in rows) _EconomyRow(data: row),
            const SizedBox(height: 6),
            const Text(
              'Achat estimé d\'après la valeur moyenne des équipements : éco sous 1 500, '
              'full buy à partir de 3 900 crédits par joueur.',
              style: TextStyle(fontSize: 10.5, color: AppTheme.valorantMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

const _headerStyle = TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.valorantMuted);

class _EconomyRowData {
  const _EconomyRowData({
    required this.round,
    required this.own,
    required this.enemy,
    required this.ownLoadout,
    required this.isWon,
  });

  final MatchRound round;
  final BuyType own;
  final BuyType? enemy;
  final double? ownLoadout;
  final bool isWon;
}

class _EconomyRow extends StatelessWidget {
  const _EconomyRow({required this.data});

  final _EconomyRowData data;

  @override
  Widget build(BuildContext context) {
    final color = data.isWon ? matchWinColor : AppTheme.valorantRed;
    final loadout = data.ownLoadout;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '${data.round.number}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white70),
            ),
          ),
          Expanded(
            child: Text(
              loadout == null ? data.own.label : '${data.own.label} · ${loadout.round()}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              data.enemy?.label ?? '—',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ),
          SizedBox(
            width: 22,
            child: Text(
              data.isWon ? 'G' : 'P',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
