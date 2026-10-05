import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/player_match.dart';
import '../domain/player_query.dart';
import '../domain/player_stats_summary.dart';
import '../providers/profile_providers.dart';
import 'match_detail_screen.dart';
import 'profile_error.dart';
import 'profile_section.dart';

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
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
        ),
      ],
    );
  }
}
