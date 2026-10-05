import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../core/widgets/fade_in_network_image.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/staggered_fade_slide.dart';
import '../../encyclopedia/domain/agent.dart';
import '../../encyclopedia/domain/game_map.dart';
import '../../encyclopedia/domain/weapon.dart';
import '../../encyclopedia/presentation/weapons/weapon_category_style.dart';
import '../../encyclopedia/providers/encyclopedia_providers.dart';
import '../domain/career_overview.dart';
import '../domain/player_query.dart';
import '../domain/player_stats_summary.dart';
import '../providers/profile_providers.dart';
import 'overview_sections.dart';
import 'profile_error.dart';
import 'profile_section.dart';

const _headColor = Color(0xFFFF7A2F);
const _bodyColor = Color(0xFF8A99A8);
const _legColor = Color(0xFF3F4A54);

/// The weapons with the most kills, with their picture and shot spread.
class TopWeaponsSection extends ConsumerWidget {
  const TopWeaponsSection({super.key, required this.query, this.limit = 5, this.onSeeAll});

  final PlayerQuery query;

  /// How many weapons are listed.
  final int limit;

  /// Shows a "see all" link when set.
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogue = ref.watch(weaponsProvider).value ?? const <Weapon>[];
    final byId = {for (final weapon in catalogue) weapon.uuid.toLowerCase(): weapon};
    final byName = {for (final weapon in catalogue) weapon.displayName.toLowerCase(): weapon};

    return ProfileSection(
      title: 'Meilleures armes',
      action: _SeeAll(onPressed: onSeeAll),
      child: ref
          .watch(careerOverviewProvider(query))
          .when(
            loading: () => const ProfileMessage.loading(text: 'Calcul des armes…'),
            error: (error, _) => ProfileMessage(text: profileErrorText(error), icon: Icons.gps_off),
            data: (overview) {
              final weapons = [
                for (final weapon in overview.weapons)
                  if (weapon.kills > 0 || weapon.shots > 0) weapon,
              ].take(limit).toList();
              if (weapons.isEmpty) {
                return const ProfileMessage(
                  text: 'Aucun kill enregistré sur les parties chargées.',
                  icon: Icons.gps_off,
                );
              }
              return Column(
                children: [
                  for (final (index, weapon) in weapons.indexed) ...[
                    if (index > 0) const SizedBox(height: 6),
                    StaggeredFadeSlide(
                      index: index,
                      child: _WeaponRow(
                        stats: weapon,
                        weapon: byId[weapon.weaponId] ?? byName[weapon.weaponName.toLowerCase()],
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

class _WeaponRow extends StatelessWidget {
  const _WeaponRow({required this.stats, required this.weapon});

  final WeaponStats stats;
  final Weapon? weapon;

  @override
  Widget build(BuildContext context) {
    final icon = weapon?.displayIcon;
    final category = weapon == null ? null : WeaponCategoryStyle.of(weapon!.category);

    return ProfileCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 96,
                height: 34,
                child: icon == null
                    ? const Icon(Icons.gps_fixed, color: Colors.white24)
                    : FadeInNetworkImage(url: icon, fit: BoxFit.contain, alignment: Alignment.centerLeft),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.weaponName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                    ),
                    if (category != null)
                      Text(
                        category.label,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: category.color),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FireText('${stats.kills}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const Text(
                    'KILLS',
                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: AppTheme.valorantMuted),
                  ),
                ],
              ),
            ],
          ),
          if (stats.shots > 0) ...[const SizedBox(height: 8), _ShotSplit(stats: stats)],
        ],
      ),
    );
  }
}

class _ShotSplit extends StatelessWidget {
  const _ShotSplit({required this.stats});

  final WeaponStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 5,
            child: Row(
              children: [
                if (stats.headshots > 0)
                  Expanded(
                    flex: stats.headshots,
                    child: const ColoredBox(color: _headColor),
                  ),
                if (stats.bodyshots > 0)
                  Expanded(
                    flex: stats.bodyshots,
                    child: const ColoredBox(color: _bodyColor),
                  ),
                if (stats.legshots > 0)
                  Expanded(
                    flex: stats.legshots,
                    child: const ColoredBox(color: _legColor),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            _Legend(color: _headColor, text: 'Tête ${formatPercent(stats.headshotPercent, digits: 0)}'),
            const SizedBox(width: 12),
            _Legend(color: _bodyColor, text: 'Corps ${formatPercent(stats.bodyshotPercent, digits: 0)}'),
            const SizedBox(width: 12),
            _Legend(color: _legColor, text: 'Jambes ${formatPercent(stats.legshotPercent, digits: 0)}'),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

/// Win rate on each map, best played first, with the map's artwork.
class TopMapsSection extends ConsumerWidget {
  const TopMapsSection({
    super.key,
    required this.query,
    this.limit = 6,
    this.onSeeAll,
    this.title = 'Meilleures cartes',
  });

  final String title;

  final PlayerQuery query;

  /// How many maps are listed.
  final int limit;

  /// Shows a "see all" link when set.
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maps = ref.watch(mapsProvider).value ?? const <GameMap>[];
    final splashByName = {for (final map in maps) map.displayName.toLowerCase(): map.splash};

    return ProfileSection(
      title: title,
      action: _SeeAll(onPressed: onSeeAll),
      child: ref
          .watch(playerStatsSummaryProvider(query))
          .when(
            loading: () => const ProfileMessage.loading(text: 'Calcul des cartes…'),
            error: (error, _) => ProfileMessage(text: profileErrorText(error), icon: Icons.map_outlined),
            data: (summary) {
              final played = [...summary.maps]
                ..sort((a, b) {
                  final byRate = (b.record.winRate ?? 0).compareTo(a.record.winRate ?? 0);
                  return byRate != 0 ? byRate : b.record.played.compareTo(a.record.played);
                });
              if (played.isEmpty) {
                return const ProfileMessage(text: 'Aucune partie à manches à analyser.', icon: Icons.map_outlined);
              }
              return Column(
                children: [
                  for (final (index, map) in played.take(limit).indexed) ...[
                    if (index > 0) const SizedBox(height: 6),
                    StaggeredFadeSlide(
                      index: index,
                      child: MapStatRow(
                        name: map.mapName,
                        record: map.record,
                        splash: splashByName[map.mapName.toLowerCase()],
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

/// A map, its artwork and its win rate.
class MapStatRow extends StatelessWidget {
  const MapStatRow({super.key, required this.name, required this.record, required this.splash, this.detail});

  final String name;
  final WinRecord record;
  final String? splash;

  /// A line of figures under the record, such as the K/D.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final rate = record.winRate ?? 0;
    final color = rate >= 55
        ? overviewWinColor
        : rate >= 45
        ? const Color(0xFFF2B90C)
        : AppTheme.valorantRed;
    final splash = this.splash;

    return ClipPath(
      clipper: const DiagonalCutClipper(cut: 8),
      child: SizedBox(
        height: 54,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (splash != null) Opacity(opacity: 0.45, child: FadeInNetworkImage(url: splash)),
            const DecoratedBox(
              decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xF20F1923), Color(0x990F1923)])),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.toUpperCase(),
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, letterSpacing: 0.4),
                        ),
                        Text(
                          '${record.wins} V · ${record.losses} D${detail == null ? '' : ' · $detail'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 92,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatPercent(record.winRate),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color),
                        ),
                        const SizedBox(height: 4),
                        GrowBar(fraction: rate / 100, color: color, height: 4, backgroundColor: Colors.black45),
                      ],
                    ),
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

/// The agents played the most, with their figures and best map.
class TopAgentsSection extends ConsumerWidget {
  const TopAgentsSection({
    super.key,
    required this.query,
    this.limit = 5,
    this.onSeeAll,
    this.title = 'Meilleurs agents',
  });

  final String title;

  final PlayerQuery query;

  /// How many agents are listed.
  final int limit;

  /// Shows a "see all" link when set.
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agents = ref.watch(agentsProvider).value ?? const <Agent>[];
    final iconByName = {for (final agent in agents) agent.displayName.toLowerCase(): agent.displayIcon};

    return ProfileSection(
      title: title,
      action: _SeeAll(onPressed: onSeeAll),
      child: ref
          .watch(careerOverviewProvider(query))
          .when(
            loading: () => const ProfileMessage.loading(text: 'Calcul des agents…'),
            error: (error, _) => ProfileMessage(text: profileErrorText(error), icon: Icons.person_search_outlined),
            data: (overview) {
              if (overview.agents.isEmpty) {
                return const ProfileMessage(text: 'Aucun agent à afficher.', icon: Icons.person_search_outlined);
              }
              return Column(
                children: [
                  for (final (index, agent) in overview.agents.take(limit).indexed) ...[
                    if (index > 0) const SizedBox(height: 6),
                    StaggeredFadeSlide(
                      index: index,
                      child: AgentStatRow(
                        name: agent.agentName,
                        icon: iconByName[agent.agentName.toLowerCase()],
                        games: agent.games,
                        winRate: agent.record.winRate,
                        note: agent.bestMapName == null ? null : 'Meilleure carte : ${agent.bestMapName}',
                        killDeathRatio: agent.killDeathRatio,
                        averageDamage: agent.averageDamage,
                        averageCombatScore: agent.averageCombatScore,
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

/// An agent, its games and its figures.
class AgentStatRow extends StatelessWidget {
  const AgentStatRow({
    super.key,
    required this.name,
    required this.icon,
    required this.games,
    required this.winRate,
    required this.killDeathRatio,
    required this.averageDamage,
    required this.averageCombatScore,
    this.note,
  });

  final String name;
  final String? icon;
  final int games;
  final double? winRate;
  final double? killDeathRatio;
  final double? averageDamage;
  final double? averageCombatScore;

  /// A third line, such as the best map.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    final note = this.note;

    return ProfileCard(
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.black26,
              border: Border.all(color: Colors.white12),
            ),
            child: icon == null
                ? const Icon(Icons.person, color: Colors.white24)
                : FadeInNetworkImage(url: icon, fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                ),
                Text(
                  '$games partie${games > 1 ? 's' : ''} · ${formatPercent(winRate, digits: 0)} de victoires',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, color: Colors.white70),
                ),
                if (note != null)
                  Text(
                    note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: AppTheme.valorantMuted),
                  ),
              ],
            ),
          ),
          _MiniFigure(label: 'K/D', value: formatNumber(killDeathRatio)),
          _MiniFigure(label: 'ADR', value: formatNumber(averageDamage, digits: 0)),
          _MiniFigure(label: 'ACS', value: formatNumber(averageCombatScore, digits: 0)),
        ],
      ),
    );
  }
}

class _MiniFigure extends StatelessWidget {
  const _MiniFigure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: AppTheme.valorantMuted),
          ),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

/// The "see all" link of a shortened list; nothing when there is nowhere to go.
class _SeeAll extends StatelessWidget {
  const _SeeAll({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final onPressed = this.onPressed;
    if (onPressed == null) return const SizedBox.shrink();
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        foregroundColor: const Color(0xFFFF7A2F),
      ),
      child: const Text('TOUT VOIR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
    );
  }
}
