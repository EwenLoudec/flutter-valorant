import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../core/widgets/fade_in_network_image.dart';
import '../../encyclopedia/domain/agent.dart';
import '../../encyclopedia/domain/game_map.dart';
import '../../encyclopedia/domain/rank_tier.dart';
import '../../encyclopedia/providers/encyclopedia_providers.dart';
import '../domain/match_detail.dart';
import '../domain/player_match.dart';
import 'match_kill_map.dart';
import 'match_rounds_section.dart';
import 'profile_section.dart';

const matchWinColor = Color(0xFF2FBF8F);

/// Everything one match of the history says: the score, the ten players'
/// lines, the rounds, the buys and where the fights happened.
class MatchDetailScreen extends ConsumerWidget {
  const MatchDetailScreen({super.key, required this.match, required this.puuid});

  final PlayerMatch match;
  final String puuid;

  GameMap? _findMap(List<GameMap> maps) {
    final mapId = match.mapId?.toLowerCase();
    for (final map in maps) {
      if (mapId != null && map.uuid.toLowerCase() == mapId) return map;
    }
    for (final map in maps) {
      if (map.displayName.toLowerCase() == match.mapName.toLowerCase()) return map;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = match.detail;
    final map = _findMap(ref.watch(mapsProvider).value ?? const <GameMap>[]);
    final agents = ref.watch(agentsProvider).value ?? const <Agent>[];
    final tiers = ref.watch(rankTiersProvider).value ?? const <RankTier>[];

    final iconsByAgent = {for (final agent in agents) agent.displayName.toLowerCase(): agent.displayIcon};
    final tierIcons = {for (final tier in tiers) tier.tier: tier.largeIcon};

    return Scaffold(
      appBar: AppBar(title: Text(match.mapName.isEmpty ? 'PARTIE' : match.mapName.toUpperCase())),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _MatchHeader(match: match, splash: map?.splash),
          const SizedBox(height: 20),
          if (detail == null || detail.players.isEmpty)
            const ProfileMessage(
              text: 'Le détail de cette partie n\'est pas disponible.',
              icon: Icons.info_outline,
            )
          else ...[
            ProfileSection(
              title: 'Tableau des scores',
              child: Column(
                children: [
                  for (final (index, teamId) in detail.teamIds.indexed) ...[
                    if (index > 0) const SizedBox(height: 10),
                    _TeamScoreboard(
                      detail: detail,
                      teamId: teamId,
                      puuid: puuid,
                      agentIcons: iconsByAgent,
                      tierIcons: tierIcons,
                    ),
                  ],
                ],
              ),
            ),
            if (detail.rounds.isNotEmpty && detail.playerTeamId != null) ...[
              const SizedBox(height: 20),
              MatchRoundsSection(detail: detail),
              if (detail.rounds.any((round) => round.averageLoadoutByTeam.isNotEmpty)) ...[
                const SizedBox(height: 20),
                MatchEconomySection(detail: detail),
              ],
            ],
            if (map != null && map.displayIcon != null && map.canPlaceGamePoints && detail.kills.isNotEmpty) ...[
              const SizedBox(height: 20),
              ProfileSection(
                title: 'Carte des kills',
                child: MatchKillMap(map: map, kills: detail.kills, puuid: puuid),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _MatchHeader extends StatelessWidget {
  const _MatchHeader({required this.match, required this.splash});

  final PlayerMatch match;
  final String? splash;

  @override
  Widget build(BuildContext context) {
    final color = switch (match.outcome) {
      MatchOutcome.win => matchWinColor,
      MatchOutcome.loss => AppTheme.valorantRed,
      _ => AppTheme.valorantMuted,
    };
    final label = switch (match.outcome) {
      MatchOutcome.win => 'VICTOIRE',
      MatchOutcome.loss => 'DÉFAITE',
      MatchOutcome.draw => 'ÉGALITÉ',
      null => 'TERMINÉE',
    };
    final splash = this.splash;
    final length = match.detail?.gameLength ?? Duration.zero;
    final startedAt = match.startedAt;

    return ClipPath(
      clipper: const DiagonalCutClipper(cut: 14),
      child: SizedBox(
        height: 150,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (splash != null) FadeInNetworkImage(url: splash) else const ColoredBox(color: AppTheme.valorantSurface),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.25), Colors.black.withValues(alpha: 0.85)],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${match.roundsWon} — ${match.roundsLost}',
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, height: 1.1),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (match.mode.isNotEmpty) match.mode,
                            if (startedAt != null) formatMatchDate(startedAt),
                            if (length > Duration.zero) '${length.inMinutes} min',
                          ].join(' · '),
                          style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        match.agentName.toUpperCase(),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white70),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${match.kills} / ${match.deaths} / ${match.assists}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamScoreboard extends StatelessWidget {
  const _TeamScoreboard({
    required this.detail,
    required this.teamId,
    required this.puuid,
    required this.agentIcons,
    required this.tierIcons,
  });

  final MatchDetail detail;
  final String teamId;
  final String puuid;
  final Map<String, String?> agentIcons;
  final Map<int, String?> tierIcons;

  @override
  Widget build(BuildContext context) {
    final players = detail.playersOf(teamId);
    final isOwnTeam = teamId == detail.playerTeamId;
    final roundsWon = detail.rounds.where((round) => round.isWonBy(teamId)).length;
    final color = isOwnTeam ? matchWinColor : AppTheme.valorantRed;
    final rounds = detail.roundCount;

    return ProfileCard(
      accentColor: color,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isOwnTeam ? 'TON ÉQUIPE' : 'ADVERSAIRES',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                ),
              ),
              if (rounds > 0)
                Text(
                  '$roundsWon manche${roundsWon > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const _ScoreRow.header(),
          const Divider(height: 10),
          for (final player in players)
            _ScoreRow(
              player: player,
              rounds: rounds,
              isSelf: player.puuid == puuid,
              agentIcon: agentIcons[player.agentName.toLowerCase()],
              tierIcon: player.tierId > 0 ? tierIcons[player.tierId] : null,
            ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required MatchPlayer this.player,
    required this.rounds,
    required this.isSelf,
    required this.agentIcon,
    required this.tierIcon,
  });

  const _ScoreRow.header() : player = null, rounds = 0, isSelf = false, agentIcon = null, tierIcon = null;

  final MatchPlayer? player;
  final int rounds;
  final bool isSelf;
  final String? agentIcon;
  final String? tierIcon;

  static const _headerStyle = TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.valorantMuted);
  static const _valueStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70);

  @override
  Widget build(BuildContext context) {
    final player = this.player;
    if (player == null) {
      return const Row(
        children: [
          SizedBox(width: 54),
          Expanded(child: Text('JOUEUR', style: _headerStyle)),
          SizedBox(width: 62, child: Text('K / D / A', textAlign: TextAlign.center, style: _headerStyle)),
          SizedBox(width: 34, child: Text('ACS', textAlign: TextAlign.right, style: _headerStyle)),
          SizedBox(width: 34, child: Text('HS %', textAlign: TextAlign.right, style: _headerStyle)),
          SizedBox(width: 34, child: Text('ADR', textAlign: TextAlign.right, style: _headerStyle)),
        ],
      );
    }

    final agentIcon = this.agentIcon;
    final tierIcon = this.tierIcon;
    final headshotPercent = player.headshotPercent;

    return Container(
      color: isSelf ? Colors.white.withValues(alpha: 0.06) : null,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: agentIcon == null
                ? const Icon(Icons.person, size: 18, color: Colors.white24)
                : FadeInNetworkImage(url: agentIcon, fit: BoxFit.contain),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 18,
            height: 18,
            child: tierIcon == null ? null : FadeInNetworkImage(url: tierIcon, fit: BoxFit.contain),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              player.name.isEmpty ? player.agentName : player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelf ? FontWeight.w900 : FontWeight.w600,
                color: isSelf ? Colors.white : Colors.white70,
              ),
            ),
          ),
          SizedBox(
            width: 62,
            child: Text(
              '${player.kills}/${player.deaths}/${player.assists}',
              textAlign: TextAlign.center,
              style: _valueStyle,
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(
              player.averageCombatScore(rounds).round().toString(),
              textAlign: TextAlign.right,
              style: _valueStyle,
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(
              headshotPercent == null ? '—' : headshotPercent.round().toString(),
              textAlign: TextAlign.right,
              style: _valueStyle,
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(
              player.damageDealt == 0 ? '—' : player.averageDamage(rounds).round().toString(),
              textAlign: TextAlign.right,
              style: _valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}

String formatMatchDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month à ${hour}h$minute';
}
