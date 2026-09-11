import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../core/widgets/fade_in_network_image.dart';
import '../../../core/widgets/staggered_fade_slide.dart';
import '../../encyclopedia/domain/agent.dart';
import '../../encyclopedia/providers/encyclopedia_providers.dart';
import '../domain/player_match.dart';
import '../domain/player_query.dart';
import '../providers/profile_providers.dart';
import 'profile_error.dart';
import 'profile_section.dart';

const _winColor = Color(0xFF2FBF8F);

/// The player's recent matches, most recent first.
class MatchHistorySection extends ConsumerWidget {
  const MatchHistorySection({super.key, required this.query});

  final PlayerQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agents = ref.watch(agentsProvider).value ?? const <Agent>[];
    final iconsByAgent = {
      for (final agent in agents) agent.displayName.toLowerCase(): agent.displayIcon,
    };

    return ProfileSection(
      title: 'Historique',
      child: ref
          .watch(playerMatchesProvider(query))
          .when(
            loading: () => const ProfileMessage.loading(text: 'Chargement des parties…'),
            error: (error, _) => ProfileMessage(text: profileErrorText(error), icon: Icons.history_toggle_off),
            data: (matches) {
              if (matches.isEmpty) {
                return const ProfileMessage(text: 'Aucune partie récente sur ce compte.', icon: Icons.history);
              }

              return Column(
                children: [
                  for (final (index, match) in matches.indexed) ...[
                    if (index > 0) const SizedBox(height: 8),
                    StaggeredFadeSlide(
                      index: index,
                      child: _MatchTile(
                        match: match,
                        agentIcon: iconsByAgent[match.agentName.toLowerCase()],
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

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.match, required this.agentIcon});

  final PlayerMatch match;
  final String? agentIcon;

  Color get _outcomeColor => switch (match.outcome) {
    MatchOutcome.win => _winColor,
    MatchOutcome.loss => AppTheme.valorantRed,
    _ => AppTheme.valorantMuted,
  };

  String get _outcomeLabel => switch (match.outcome) {
    MatchOutcome.win => 'VICTOIRE',
    MatchOutcome.loss => 'DÉFAITE',
    MatchOutcome.draw => 'ÉGALITÉ',
    null => '—',
  };

  @override
  Widget build(BuildContext context) {
    final agentIcon = this.agentIcon;
    final headshotPercent = match.headshotPercent;

    return ClipPath(
      clipper: const DiagonalCutClipper(cut: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.valorantSurface,
          border: Border(left: BorderSide(color: _outcomeColor, width: 3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: agentIcon == null
                  ? const Icon(Icons.person, color: Colors.white24)
                  : FadeInNetworkImage(url: agentIcon, fit: BoxFit.contain),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.mapName.isEmpty ? 'Carte inconnue' : match.mapName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (match.mode.isNotEmpty) match.mode,
                      if (match.startedAt != null) _formatDate(match.startedAt!),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppTheme.valorantMuted),
                  ),
                  if (headshotPercent != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${headshotPercent.toStringAsFixed(0)} % de têtes',
                      style: const TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _outcomeLabel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _outcomeColor, letterSpacing: 0.6),
                ),
                const SizedBox(height: 2),
                Text(
                  '${match.roundsWon} — ${match.roundsLost}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${match.kills} / ${match.deaths} / ${match.assists}',
                  style: const TextStyle(fontSize: 11.5, color: Colors.white70, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month à ${hour}h$minute';
}
