import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../core/widgets/fade_in_network_image.dart';
import '../../../core/widgets/flame_backdrop.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/staggered_fade_slide.dart';
import '../../encyclopedia/domain/rank_tier.dart';
import '../../encyclopedia/providers/encyclopedia_providers.dart';
import '../domain/player_account.dart';
import '../domain/player_query.dart';
import '../domain/player_rank.dart';
import '../providers/profile_providers.dart';
import 'profile_error.dart';
import 'profile_section.dart';
import 'rank_aura.dart';
import 'rank_theme.dart';

const heroWinColor = Color(0xFF2FBF8F);

/// The top of an account page, tracker style: the player card behind a fire
/// in the rank's colours, the name, and the rank in its aura as the
/// centrepiece.
class ProfileHero extends ConsumerWidget {
  const ProfileHero({super.key, required this.query});

  final PlayerQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(playerAccountProvider(query))
        .when(
          loading: () => const ProfileMessage.loading(text: 'Recherche du compte…'),
          error: (error, _) => ProfileMessage(text: profileErrorText(error), icon: Icons.person_off_outlined),
          data: (account) => _Hero(query: query, account: account),
        );
  }
}

RankTier? _tierFor(List<RankTier> tiers, int? tierId) {
  if (tierId == null) return null;
  for (final tier in tiers) {
    if (tier.tier == tierId) return tier;
  }
  return null;
}

class _Hero extends ConsumerWidget {
  const _Hero({required this.query, required this.account});

  final PlayerQuery query;
  final PlayerAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiers = ref.watch(rankTiersProvider).value ?? const <RankTier>[];
    final rankAsync = ref.watch(playerRankProvider(query));
    final rank = rankAsync.value;
    final tier = _tierFor(tiers, rank?.tierId);
    final theme = RankTheme.ofTier(rank?.tierId);
    // The act's competitive record, as trackers show it; the recent games
    // only when the act has none.
    final seasonRecord = ref.watch(seasonStatsProvider(query)).value?.totals.record;
    final hasSeason = seasonRecord != null && seasonRecord.played > 0;
    final record = hasSeason ? seasonRecord : ref.watch(careerOverviewProvider(query)).value?.record;
    final title = ref.watch(equippedTitleProvider(query));
    final cardWide = account.cardWide;
    final watermark = tier?.largeIcon;

    return ClipPath(
      clipper: const DiagonalCutClipper(cut: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.valorantSurface,
          border: Border(bottom: BorderSide(color: theme.main, width: 3)),
        ),
        child: Stack(
          children: [
            if (cardWide != null)
              Positioned.fill(
                child: Opacity(opacity: 0.32, child: FadeInNetworkImage(url: cardWide)),
              ),
            Positioned.fill(
              child: FlameBackdrop(palette: theme.palette, intensity: 0.55 + theme.energy * 0.45),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xCC0F1923), Color(0x330F1923), Color(0xE60F1923)],
                    stops: [0, 0.45, 1],
                  ),
                ),
              ),
            ),
            // The rank's emblem, huge and faded, behind everything.
            if (watermark != null)
              Positioned(
                right: -46,
                bottom: -30,
                width: 210,
                height: 210,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.10,
                    child: FadeInNetworkImage(url: watermark, fit: BoxFit.contain),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StaggeredFadeSlide(
                    index: 0,
                    child: _Identity(account: account, region: query.region, theme: theme, title: title),
                  ),
                  const SizedBox(height: 18),
                  StaggeredFadeSlide(
                    index: 1,
                    child: rankAsync.when(
                      loading: () => const _RankLoading(),
                      error: (error, _) =>
                          Text(profileErrorText(error), style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      data: (rank) =>
                          _RankPanel(rank: rank, tier: tier, peakTier: _tierFor(tiers, rank.peakTierId), theme: theme),
                    ),
                  ),
                  if (record != null && record.played > 0) ...[
                    const SizedBox(height: 14),
                    StaggeredFadeSlide(
                      index: 2,
                      child: _RecordBar(
                        wins: record.wins,
                        losses: record.losses,
                        label: hasSeason ? 'ACTE EN COURS · COMPÉTITIF' : 'DERNIÈRES PARTIES',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.account, required this.region, required this.theme, required this.title});

  final PlayerAccount account;
  final ValorantRegion region;
  final RankTheme theme;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final cardSmall = account.cardSmall;
    final title = this.title;

    return Row(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            border: Border.all(color: theme.main, width: 2),
            boxShadow: [BoxShadow(color: theme.main.withValues(alpha: 0.55), blurRadius: 18, spreadRadius: -2)],
          ),
          child: cardSmall == null
              ? const ColoredBox(
                  color: Colors.black38,
                  child: Icon(Icons.person, color: Colors.white38),
                )
              : FadeInNetworkImage(url: cardSmall),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: account.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                    ),
                    TextSpan(
                      text: '  #${account.tag}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: theme.core),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (title != null) ...[
                const SizedBox(height: 1),
                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1, color: theme.main),
                ),
              ],
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _Chip(text: 'NIVEAU ${account.accountLevel}'),
                  _Chip(text: region.label.toUpperCase()),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black54,
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Colors.white70),
      ),
    );
  }
}

class _RankPanel extends StatelessWidget {
  const _RankPanel({required this.rank, required this.tier, required this.peakTier, required this.theme});

  final PlayerRank rank;
  final RankTier? tier;
  final RankTier? peakTier;
  final RankTheme theme;

  @override
  Widget build(BuildContext context) {
    final icon = tier?.largeIcon;
    final peakName = peakTier?.tierName ?? rank.peakTierName;
    final peakIcon = peakTier?.largeIcon;
    final peakTheme = RankTheme.ofTier(rank.peakTierId);
    final changeColor = rank.lastChange > 0 ? heroWinColor : AppTheme.valorantRed;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RankAura(
          theme: theme,
          size: 104,
          child: icon == null
              ? Icon(Icons.military_tech_rounded, size: 56, color: theme.main)
              : FadeInNetworkImage(url: icon, fit: BoxFit.contain),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RANG ACTUEL',
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.white54),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => theme.gradient.createShader(bounds),
                  child: Text(
                    (tier?.tierName ?? rank.tierName).toUpperCase(),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                      shadows: [Shadow(color: theme.main.withValues(alpha: 0.6), blurRadius: 12)],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (rank.isPlacement)
                Text(
                  'Placements · ${rank.gamesNeededForRating} partie(s) restante(s)',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white70),
                )
              else if (rank.isRanked) ...[
                Row(
                  children: [
                    CountUp(
                      value: rank.rankedRating.toDouble(),
                      builder: (context, value) => Text(
                        '${value.round()} RR',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (rank.lastChange != 0) ...[
                      const SizedBox(width: 6),
                      Icon(
                        rank.lastChange > 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        size: 20,
                        color: changeColor,
                      ),
                      Text(
                        '${rank.lastChange > 0 ? '+' : ''}${rank.lastChange}',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: changeColor),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                GrowBar(fraction: rank.rankedRating / 100, color: theme.main, height: 5, glow: true),
              ],
            ],
          ),
        ),
        if (peakName != null) ...[
          const SizedBox(width: 10),
          Column(
            children: [
              const Text(
                'PIC',
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.white54),
              ),
              const SizedBox(height: 4),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: peakTheme.main.withValues(alpha: 0.35), blurRadius: 14)],
                ),
                child: peakIcon == null
                    ? const Icon(Icons.emoji_events_outlined, color: Colors.white38)
                    : FadeInNetworkImage(url: peakIcon, fit: BoxFit.contain),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: 62,
                child: Text(
                  peakName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white70),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _RankLoading extends StatelessWidget {
  const _RankLoading();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.valorantRed)),
        SizedBox(width: 10),
        Text('Lecture du classement…', style: TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}

/// Wins in green over losses in red, as one bar filling up.
class _RecordBar extends StatelessWidget {
  const _RecordBar({required this.wins, required this.losses, required this.label});

  final int wins;
  final int losses;
  final String label;

  @override
  Widget build(BuildContext context) {
    final total = wins + losses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$wins V',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: heroWinColor),
            ),
            const SizedBox(width: 8),
            Text(
              '$losses D',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.valorantRed),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Colors.white38),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        GrowBar(
          fraction: total == 0 ? 0 : wins / total,
          color: heroWinColor,
          backgroundColor: total == 0 ? Colors.white12 : AppTheme.valorantRed,
          height: 5,
        ),
      ],
    );
  }
}
