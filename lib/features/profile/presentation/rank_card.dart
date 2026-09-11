import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fade_in_network_image.dart';
import '../../encyclopedia/domain/rank_tier.dart';
import '../../encyclopedia/providers/encyclopedia_providers.dart';
import '../domain/player_query.dart';
import '../domain/player_rank.dart';
import '../providers/profile_providers.dart';
import 'profile_error.dart';
import 'profile_section.dart';

/// Current competitive rank: tier, RR, and the peak ever reached. The tier
/// artwork and its French name come from the encyclopedia catalogue.
class RankCard extends ConsumerWidget {
  const RankCard({super.key, required this.query});

  final PlayerQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiers = ref.watch(rankTiersProvider).value ?? const <RankTier>[];

    return ref
        .watch(playerRankProvider(query))
        .when(
          loading: () => const ProfileMessage.loading(text: 'Lecture du classement…'),
          error: (error, _) => ProfileMessage(text: profileErrorText(error), icon: Icons.military_tech_outlined),
          data: (rank) => _RankBody(rank: rank, tiers: tiers),
        );
  }
}

class _RankBody extends StatelessWidget {
  const _RankBody({required this.rank, required this.tiers});

  final PlayerRank rank;
  final List<RankTier> tiers;

  RankTier? _tierFor(int? tierId) {
    if (tierId == null) return null;
    for (final tier in tiers) {
      if (tier.tier == tierId) return tier;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tier = _tierFor(rank.tierId);
    final color = tier?.color ?? AppTheme.valorantMuted;
    final icon = tier?.largeIcon;
    final peakTier = _tierFor(rank.peakTierId);
    final peakName = peakTier?.tierName ?? rank.peakTierName;

    return ProfileCard(
      accentColor: color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: icon == null
                ? Icon(Icons.military_tech_rounded, size: 44, color: color)
                : FadeInNetworkImage(url: icon, fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (tier?.tierName ?? rank.tierName).toUpperCase(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.4),
                ),
                const SizedBox(height: 6),
                if (rank.isPlacement)
                  Text(
                    'PLACEMENTS · ${rank.gamesNeededForRating} partie(s) restante(s)',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white70),
                  )
                else ...[
                  Row(
                    children: [
                      Text(
                        '${rank.rankedRating} RR',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 8),
                      if (rank.lastChange != 0) _LastChangeBadge(value: rank.lastChange),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.zero,
                    child: LinearProgressIndicator(
                      value: (rank.rankedRating / 100).clamp(0, 1).toDouble(),
                      minHeight: 6,
                      backgroundColor: Colors.black38,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    if (rank.elo > 0) _Stat(label: 'ELO', value: '${rank.elo}'),
                    if (peakName != null)
                      _Stat(
                        label: 'PIC',
                        value: rank.peakSeason == null
                            ? peakName
                            : '$peakName · ${rank.peakSeason!.toUpperCase()}',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LastChangeBadge extends StatelessWidget {
  const _LastChangeBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final isGain = value > 0;
    final color = isGain ? const Color(0xFF2FBF8F) : AppTheme.valorantRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: color.withValues(alpha: 0.16),
      child: Text(
        '${isGain ? '+' : ''}$value',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.valorantMuted),
        ),
        const SizedBox(width: 5),
        Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white70)),
      ],
    );
  }
}
