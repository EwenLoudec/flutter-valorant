import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/staggered_fade_slide.dart';
import '../../encyclopedia/domain/agent.dart';
import '../../encyclopedia/domain/game_map.dart';
import '../../encyclopedia/domain/rank_tier.dart';
import '../../encyclopedia/providers/encyclopedia_providers.dart';
import '../domain/player_query.dart';
import '../domain/stored_match.dart';
import '../providers/profile_providers.dart';
import 'overview_lists.dart';
import 'overview_sections.dart';
import 'profile_error.dart';
import 'profile_section.dart';

/// Loads the act's figures once, with the same loading, error and empty
/// states for every season section.
class _SeasonBuilder extends ConsumerWidget {
  const _SeasonBuilder({required this.query, required this.icon, required this.builder});

  final PlayerQuery query;
  final IconData icon;
  final Widget Function(BuildContext context, SeasonStats season) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(seasonStatsProvider(query))
        .when(
          loading: () => const ProfileMessage.loading(text: 'Lecture de la saison…'),
          error: (error, _) => ProfileMessage(text: profileErrorText(error), icon: icon),
          data: (season) => season.isEmpty
              ? ProfileMessage(text: 'Aucune partie compétitive sur l\'acte en cours.', icon: icon)
              : builder(context, season),
        );
  }
}

/// What the act is called: the catalogue's name when it knows the act,
/// otherwise the short code the games carry.
String _seasonName(WidgetRef ref, SeasonStats season) {
  final current = ref.watch(currentSeasonProvider).value;
  if (current != null && current.actUuid == season.seasonId) return current.label;
  return season.seasonLabel ?? 'Acte en cours';
}

String _games(int count) => '$count partie${count > 1 ? 's' : ''}';

/// The act's competitive figures, as a tracker's overview leads with.
class SeasonOverviewSection extends ConsumerWidget {
  const SeasonOverviewSection({super.key, required this.query});

  final PlayerQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiers = ref.watch(rankTiersProvider).value ?? const <RankTier>[];

    return ProfileSection(
      title: 'Saison compétitive',
      child: _SeasonBuilder(
        query: query,
        icon: Icons.emoji_events_outlined,
        builder: (context, season) {
          final totals = season.totals;
          final record = totals.record;
          String? peakName;
          for (final tier in tiers) {
            if (tier.tier == season.peakTier) peakName = tier.tierName;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${_seasonName(ref, season)} · ${_games(totals.matches)} · ${totals.rounds} manches',
                style: const TextStyle(fontSize: 11, color: AppTheme.valorantMuted),
              ),
              const SizedBox(height: 8),
              StatTileGrid(
                columns: 2,
                height: 74,
                tiles: [
                  StatTile(label: 'Victoires', number: record.winRate, format: formatPercent, isHeadline: true),
                  StatTile(label: 'K/D', number: totals.killDeathRatio, format: formatNumber, isHeadline: true),
                  StatTile(
                    label: 'Tirs à la tête',
                    number: totals.headshotPercent,
                    format: formatPercent,
                    isHeadline: true,
                  ),
                  StatTile(label: 'ACS', number: totals.averageCombatScore, format: formatWhole, isHeadline: true),
                ],
              ),
              const SizedBox(height: 8),
              StatTileGrid(
                columns: 4,
                height: 58,
                tiles: [
                  StatTile(label: 'Victoires', number: record.wins.toDouble(), format: formatWhole),
                  StatTile(label: 'Défaites', number: record.losses.toDouble(), format: formatWhole),
                  StatTile(label: 'ADR', number: totals.averageDamage, format: formatWhole),
                  StatTile(label: 'KDA', number: totals.kdaRatio, format: formatNumber),
                ],
              ),
              if (peakName != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Meilleur rang atteint sur ces parties : $peakName',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Win rate, K/D and ACS on each map over the act.
class SeasonMapsSection extends ConsumerWidget {
  const SeasonMapsSection({super.key, required this.query});

  final PlayerQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maps = ref.watch(mapsProvider).value ?? const <GameMap>[];
    final splashByName = {for (final map in maps) map.displayName.toLowerCase(): map.splash};

    return ProfileSection(
      title: 'Cartes · saison compétitive',
      child: _SeasonBuilder(
        query: query,
        icon: Icons.map_outlined,
        builder: (context, season) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Les plus jouées d\'abord · ${_seasonName(ref, season)}',
              style: const TextStyle(fontSize: 11, color: AppTheme.valorantMuted),
            ),
            const SizedBox(height: 8),
            for (final (index, map) in season.maps.indexed) ...[
              if (index > 0) const SizedBox(height: 6),
              StaggeredFadeSlide(
                index: index,
                child: MapStatRow(
                  name: map.name,
                  record: map.totals.record,
                  splash: splashByName[map.name.toLowerCase()],
                  detail:
                      'K/D ${formatNumber(map.totals.killDeathRatio)} · '
                      'ACS ${formatWhole(map.totals.averageCombatScore)}',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The agents played over the act, most played first.
class SeasonAgentsSection extends ConsumerWidget {
  const SeasonAgentsSection({super.key, required this.query, this.limit = 20, this.onSeeAll});

  final PlayerQuery query;
  final int limit;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agents = ref.watch(agentsProvider).value ?? const <Agent>[];
    final iconById = {for (final agent in agents) agent.uuid.toLowerCase(): agent.displayIcon};
    final iconByName = {for (final agent in agents) agent.displayName.toLowerCase(): agent.displayIcon};
    final onSeeAll = this.onSeeAll;

    return ProfileSection(
      title: 'Agents · saison compétitive',
      action: onSeeAll == null
          ? null
          : TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                foregroundColor: const Color(0xFFFF7A2F),
              ),
              child: const Text(
                'TOUT VOIR',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6),
              ),
            ),
      child: _SeasonBuilder(
        query: query,
        icon: Icons.person_search_outlined,
        builder: (context, season) => Column(
          children: [
            for (final (index, agent) in season.agents.take(limit).indexed) ...[
              if (index > 0) const SizedBox(height: 6),
              StaggeredFadeSlide(
                index: index,
                child: AgentStatRow(
                  name: agent.name,
                  icon: iconById[agent.id?.toLowerCase()] ?? iconByName[agent.name.toLowerCase()],
                  games: agent.totals.matches,
                  winRate: agent.totals.record.winRate,
                  note: 'Tirs à la tête : ${formatPercent(agent.totals.headshotPercent, digits: 0)}',
                  killDeathRatio: agent.totals.killDeathRatio,
                  averageDamage: agent.totals.averageDamage,
                  averageCombatScore: agent.totals.averageCombatScore,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
