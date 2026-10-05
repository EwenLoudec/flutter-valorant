import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fade_in_network_image.dart';
import '../../encyclopedia/domain/agent.dart';
import '../../encyclopedia/providers/encyclopedia_providers.dart';
import '../domain/player_match.dart';
import '../domain/player_query.dart';
import '../domain/player_stats_summary.dart';
import '../providers/profile_providers.dart';
import 'match_detail_screen.dart';
import 'profile_error.dart';
import 'profile_section.dart';

String _percent(double? value) => value == null ? '—' : '${value.round()} %';

/// The latest session: games in a row, their balance and the current streak.
class SessionSection extends ConsumerWidget {
  const SessionSection({super.key, required this.query});

  final PlayerQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProfileSection(
      title: 'Dernière session',
      child: ref
          .watch(playerStatsSummaryProvider(query))
          .when(
            loading: () => const ProfileMessage.loading(text: 'Calcul de la session…'),
            error: (error, _) => ProfileMessage(text: profileErrorText(error), icon: Icons.timelapse),
            data: (summary) {
              final session = summary.session;
              if (session == null) {
                return const ProfileMessage(
                  text: 'Aucune partie à manches récente (les combats à mort ne comptent pas).',
                  icon: Icons.timelapse,
                );
              }
              return _SessionCard(session: session, streak: summary.streak);
            },
          ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.streak});

  final SessionSummary session;
  final Streak? streak;

  @override
  Widget build(BuildContext context) {
    final change = session.rankedRatingChange;
    final startedAt = session.startedAt;
    final streak = this.streak;
    final record = session.record;

    return ProfileCard(
      accentColor: AppTheme.valorantRed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${session.matches.length} partie${session.matches.length > 1 ? 's' : ''}'
            '${startedAt == null ? '' : ' depuis le ${formatMatchDate(startedAt)}'}',
            style: const TextStyle(fontSize: 11.5, color: AppTheme.valorantMuted),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 22,
            runSpacing: 10,
            children: [
              _Figure(label: 'BILAN', value: '${record.wins} V · ${record.losses} D'),
              if (change != null)
                _Figure(
                  label: 'RR',
                  value: '${change > 0 ? '+' : ''}$change',
                  color: change > 0
                      ? matchWinColor
                      : change < 0
                      ? AppTheme.valorantRed
                      : null,
                ),
              _Figure(label: 'K/D', value: session.killDeathRatio.toStringAsFixed(2)),
              if (streak != null && streak.length >= 2)
                _Figure(
                  label: 'SÉRIE',
                  value: '${streak.length} ${streak.outcome == MatchOutcome.win ? 'victoires' : 'défaites'}',
                  color: streak.outcome == MatchOutcome.win ? matchWinColor : AppTheme.valorantRed,
                ),
            ],
          ),
          if (change == null && session.matches.any((match) => match.isCompetitive)) ...[
            const SizedBox(height: 8),
            const Text(
              'Le bilan RR apparaît quand l\'historique classé est disponible.',
              style: TextStyle(fontSize: 10.5, color: AppTheme.valorantMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppTheme.valorantMuted),
        ),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}

/// Per agent, per map and per side figures over the loaded games.
class PlayerStatsSection extends ConsumerWidget {
  const PlayerStatsSection({super.key, required this.query});

  static const _maximumAgents = 5;

  final PlayerQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agents = ref.watch(agentsProvider).value ?? const <Agent>[];
    final iconsByAgent = {for (final agent in agents) agent.displayName.toLowerCase(): agent.displayIcon};

    return ProfileSection(
      title: 'Statistiques',
      child: ref
          .watch(playerStatsSummaryProvider(query))
          .when(
            loading: () => const ProfileMessage.loading(text: 'Calcul des statistiques…'),
            error: (error, _) => ProfileMessage(text: profileErrorText(error), icon: Icons.insights),
            data: (summary) {
              if (summary.isEmpty) {
                return const ProfileMessage(
                  text: 'Aucune partie à manches parmi les dernières : les combats à mort ne sont pas comptés.',
                  icon: Icons.insights,
                );
              }

              final bestAndWorst = summary.bestAndWorstMaps();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Sur ${summary.matchCount} partie${summary.matchCount > 1 ? 's' : ''} à manches '
                      '— les combats à mort ne sont pas comptés.',
                      style: const TextStyle(fontSize: 11, color: AppTheme.valorantMuted),
                    ),
                  ),
                  ProfileCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _CardTitle('Mes agents'),
                        const SizedBox(height: 8),
                        const _AgentRow.header(),
                        const Divider(height: 10),
                        for (final stats in summary.agents.take(_maximumAgents))
                          _AgentRow(stats: stats, icon: iconsByAgent[stats.agentName.toLowerCase()]),
                      ],
                    ),
                  ),
                  if (summary.maps.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ProfileCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _CardTitle('Mes cartes'),
                          if (bestAndWorst != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Meilleure : ${bestAndWorst.$1.mapName} (${_percent(bestAndWorst.$1.record.winRate)}) · '
                              'à travailler : ${bestAndWorst.$2.mapName} (${_percent(bestAndWorst.$2.record.winRate)})',
                              style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.4),
                            ),
                          ],
                          const SizedBox(height: 8),
                          for (final map in summary.maps) _MapRow(stats: map),
                        ],
                      ),
                    ),
                  ],
                  if (!summary.sides.isEmpty) ...[
                    const SizedBox(height: 8),
                    ProfileCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _CardTitle('Manches gagnées par camp'),
                          const SizedBox(height: 10),
                          _SideRow(label: 'Attaque', record: summary.sides.attack),
                          const SizedBox(height: 8),
                          _SideRow(label: 'Défense', record: summary.sides.defense),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.6, color: Colors.white70),
    );
  }
}

const _headerStyle = TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.valorantMuted);
const _valueStyle = TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white70);

class _AgentRow extends StatelessWidget {
  const _AgentRow({required AgentStats this.stats, required this.icon});

  const _AgentRow.header() : stats = null, icon = null;

  final AgentStats? stats;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final stats = this.stats;
    if (stats == null) {
      return const Row(
        children: [
          Expanded(child: Padding(padding: EdgeInsets.only(left: 32), child: Text('AGENT', style: _headerStyle))),
          SizedBox(width: 44, child: Text('PARTIES', textAlign: TextAlign.right, style: _headerStyle)),
          SizedBox(width: 48, child: Text('VICT.', textAlign: TextAlign.right, style: _headerStyle)),
          SizedBox(width: 42, child: Text('K/D', textAlign: TextAlign.right, style: _headerStyle)),
          SizedBox(width: 40, child: Text('ACS', textAlign: TextAlign.right, style: _headerStyle)),
        ],
      );
    }

    final icon = this.icon;
    final acs = stats.averageCombatScore;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: icon == null
                ? const Icon(Icons.person, size: 16, color: Colors.white24)
                : FadeInNetworkImage(url: icon, fit: BoxFit.contain),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              stats.agentName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(width: 44, child: Text('${stats.games}', textAlign: TextAlign.right, style: _valueStyle)),
          SizedBox(
            width: 48,
            child: Text(_percent(stats.record.winRate), textAlign: TextAlign.right, style: _valueStyle),
          ),
          SizedBox(
            width: 42,
            child: Text(stats.killDeathRatio.toStringAsFixed(2), textAlign: TextAlign.right, style: _valueStyle),
          ),
          SizedBox(
            width: 40,
            child: Text(acs == null ? '—' : '${acs.round()}', textAlign: TextAlign.right, style: _valueStyle),
          ),
        ],
      ),
    );
  }
}

class _MapRow extends StatelessWidget {
  const _MapRow({required this.stats});

  final MapStats stats;

  @override
  Widget build(BuildContext context) {
    final record = stats.record;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              stats.mapName.toUpperCase(),
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.3),
            ),
          ),
          Text('${record.wins} V · ${record.losses} D', style: _valueStyle),
          SizedBox(
            width: 52,
            child: Text(
              _percent(record.winRate),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideRow extends StatelessWidget {
  const _SideRow({required this.label, required this.record});

  final String label;
  final WinRecord record;

  @override
  Widget build(BuildContext context) {
    final rate = record.winRate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
            ),
            Text(
              rate == null ? '—' : '${_percent(rate)} · ${record.wins}/${record.played}',
              style: _valueStyle,
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: (rate ?? 0) / 100,
            minHeight: 6,
            backgroundColor: Colors.black38,
            valueColor: const AlwaysStoppedAnimation(AppTheme.valorantRed),
          ),
        ),
      ],
    );
  }
}
