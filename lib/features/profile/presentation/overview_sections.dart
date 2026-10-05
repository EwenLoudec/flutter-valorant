import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../core/widgets/motion.dart';
import '../../encyclopedia/presentation/agents/agent_role_style.dart';
import '../domain/career_overview.dart';
import '../domain/player_query.dart';
import '../domain/player_stats_summary.dart';
import '../providers/profile_providers.dart';
import 'profile_error.dart';
import 'profile_section.dart';

/// The fire gradient used on the headline figures.
const fireGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFFFD27A), Color(0xFFFF7A2F), Color(0xFFFF4655)],
);

const overviewWinColor = Color(0xFF2FBF8F);

String formatPercent(double? value, {int digits = 1}) => value == null ? '—' : '${value.toStringAsFixed(digits)} %';
String formatNumber(double? value, {int digits = 2}) => value == null ? '—' : value.toStringAsFixed(digits);

/// Text painted with [fireGradient].
class FireText extends StatelessWidget {
  const FireText(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => fireGradient.createShader(bounds),
      child: Text(text, maxLines: 1, style: style),
    );
  }
}

/// Loads the overview once and hands it to [builder], with the same loading,
/// error and empty states everywhere.
class _OverviewBuilder extends ConsumerWidget {
  const _OverviewBuilder({required this.query, required this.builder, required this.icon});

  final PlayerQuery query;
  final Widget Function(CareerOverview overview) builder;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(careerOverviewProvider(query))
        .when(
          loading: () => const ProfileMessage.loading(text: 'Calcul des statistiques…'),
          error: (error, _) => ProfileMessage(text: profileErrorText(error), icon: icon),
          data: (overview) => overview.isEmpty
              ? ProfileMessage(
                  text: 'Aucune partie à manches parmi les dernières : les combats à mort ne sont pas comptés.',
                  icon: icon,
                )
              : builder(overview),
        );
  }
}

/// The headline figures, as on a tracker overview: four big tiles, then the
/// details.
class OverviewStatsSection extends StatelessWidget {
  const OverviewStatsSection({super.key, required this.query});

  final PlayerQuery query;

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      title: 'Performances',
      child: _OverviewBuilder(
        query: query,
        icon: Icons.insights,
        builder: (overview) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Détail des ${overview.matchCount} dernière${overview.matchCount > 1 ? 's' : ''} '
              'partie${overview.matchCount > 1 ? 's' : ''}, tous modes · ${overview.rounds} manches',
              style: const TextStyle(fontSize: 11, color: AppTheme.valorantMuted),
            ),
            const SizedBox(height: 8),
            StatTileGrid(
              columns: 2,
              height: 74,
              tiles: [
                StatTile(label: 'K/D', number: overview.killDeathRatio, format: formatNumber, isHeadline: true),
                StatTile(
                  label: 'Tirs à la tête',
                  number: overview.headshotPercent,
                  format: formatPercent,
                  isHeadline: true,
                ),
                StatTile(label: 'Victoires', number: overview.winRate, format: formatPercent, isHeadline: true),
                StatTile(label: 'ACS', number: overview.averageCombatScore, format: formatWhole, isHeadline: true),
              ],
            ),
            const SizedBox(height: 8),
            StatTileGrid(
              columns: 4,
              height: 58,
              tiles: [
                StatTile(label: 'ADR', number: overview.averageDamage, format: formatWhole),
                StatTile(label: 'KAST', number: overview.kastPercent, format: formatWholePercent),
                StatTile(label: 'KAD', number: overview.kadRatio, format: formatNumber),
                StatTile(label: 'Kills/manche', number: overview.killsPerRound, format: formatNumber),
                StatTile(label: 'Kills', number: overview.kills.toDouble(), format: formatWhole),
                StatTile(label: '1ers kills', number: overview.firstBloods.toDouble(), format: formatWhole),
                StatTile(label: 'Parfaites', number: overview.flawlessRounds.toDouble(), format: formatWhole),
                StatTile(label: 'Aces', number: overview.aces.toDouble(), format: formatWhole),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiles laid out [columns] by row, all of the same height.
class StatTileGrid extends StatelessWidget {
  const StatTileGrid({super.key, required this.columns, required this.height, required this.tiles});

  final int columns;
  final double height;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var start = 0; start < tiles.length; start += columns) ...[
          if (start > 0) const SizedBox(height: 6),
          SizedBox(
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = start; index < start + columns; index++) ...[
                  if (index > start) const SizedBox(width: 6),
                  Expanded(child: index < tiles.length ? tiles[index] : const SizedBox()),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

String formatWhole(double? value) => formatNumber(value, digits: 0);
String formatWholePercent(double? value) => formatPercent(value, digits: 0);

/// A labelled figure counting up, in fire for the headline ones.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.number, required this.format, this.isHeadline = false});

  final String label;

  /// null shows a dash.
  final double? number;
  final String Function(double? value) format;
  final bool isHeadline;

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(fontSize: isHeadline ? 24 : 15, fontWeight: FontWeight.w900, height: 1.1);
    Widget text(String value) =>
        isHeadline ? FireText(value, style: valueStyle) : Text(value, maxLines: 1, style: valueStyle);

    return ClipPath(
      clipper: DiagonalCutClipper(cut: isHeadline ? 10 : 6),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.valorantSurface,
          border: isHeadline ? const Border(left: BorderSide(color: Color(0xFFFF7A2F), width: 3)) : null,
        ),
        padding: EdgeInsets.symmetric(horizontal: isHeadline ? 12 : 8, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isHeadline ? 10 : 8.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: AppTheme.valorantMuted,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: number == null
                  ? text(format(null))
                  : CountUp(value: number!, builder: (context, value) => text(format(value))),
            ),
          ],
        ),
      ),
    );
  }
}

/// Win rate and KDA of each role played.
class RolesSection extends StatelessWidget {
  const RolesSection({super.key, required this.query});

  final PlayerQuery query;

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      title: 'Rôles',
      child: _OverviewBuilder(
        query: query,
        icon: Icons.groups_2_outlined,
        builder: (overview) {
          if (overview.roles.isEmpty) {
            return const ProfileMessage(text: 'Rôles indisponibles pour le moment.', icon: Icons.groups_2_outlined);
          }
          return Column(
            children: [
              for (final (index, role) in overview.roles.indexed) ...[
                if (index > 0) const SizedBox(height: 6),
                _RoleRow(stats: role),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({required this.stats});

  final RoleStats stats;

  @override
  Widget build(BuildContext context) {
    final style = AgentRoleStyle.of(stats.role);
    final record = stats.record;

    return ProfileCard(
      accentColor: style.color,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Icon(style.icon, size: 20, color: style.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stats.role.toUpperCase(), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900)),
                Text(
                  '${record.wins} V · ${record.losses} D',
                  style: const TextStyle(fontSize: 10.5, color: AppTheme.valorantMuted),
                ),
              ],
            ),
          ),
          _Figure(label: 'VICT.', value: formatPercent(record.winRate)),
          const SizedBox(width: 16),
          _Figure(label: 'KDA', value: formatNumber(stats.kda)),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.valorantMuted),
        ),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

/// Rounds won on attack and on defense.
class SidesSection extends ConsumerWidget {
  const SidesSection({super.key, required this.query});

  final PlayerQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(playerStatsSummaryProvider(query)).value;
    final sides = summary?.sides;
    if (sides == null || sides.isEmpty) return const SizedBox.shrink();

    return ProfileSection(
      title: 'Attaque et défense',
      child: ProfileCard(
        child: Column(
          children: [
            _SideRow(label: 'Attaque', record: sides.attack, color: const Color(0xFFFF7A2F)),
            const SizedBox(height: 10),
            _SideRow(label: 'Défense', record: sides.defense, color: const Color(0xFF4FD1C5)),
          ],
        ),
      ),
    );
  }
}

class _SideRow extends StatelessWidget {
  const _SideRow({required this.label, required this.record, required this.color});

  final String label;
  final WinRecord record;
  final Color color;

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
              rate == null ? '—' : '${formatPercent(rate, digits: 0)} · ${record.wins}/${record.played} manches',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 5),
        GrowBar(fraction: (rate ?? 0) / 100, color: color),
      ],
    );
  }
}
