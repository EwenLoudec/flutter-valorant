import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/async_list_view.dart';
import '../../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../../core/widgets/fade_in_network_image.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../../core/widgets/staggered_fade_slide.dart';
import '../../domain/rank_tier.dart';
import '../../providers/encyclopedia_providers.dart';
import 'radiant_leaderboard_screen.dart';

class RanksTab extends ConsumerWidget {
  const RanksTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranksAsync = ref.watch(rankTiersProvider);
    final seasonAsync = ref.watch(currentSeasonProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        seasonAsync.when(
          data: (season) => season == null
              ? const SizedBox()
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.event, size: 14, color: Colors.white38),
                      const SizedBox(width: 6),
                      Text(
                        'SAISON ACTUELLE : ${season.label.toUpperCase()}',
                        style: const TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
          loading: () => const SizedBox(),
          error: (error, _) => const SizedBox(),
        ),
        Expanded(
          child: AsyncListView<RankTier>(
            value: ranksAsync,
            emptyMessage: 'Aucun rang trouvé.',
            builder: (context, ascendingRanks) {
              final ranks = ascendingRanks.reversed.toList();
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: ranks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return StaggeredFadeSlide(index: index, child: _RankTile(rank: ranks[index]));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({required this.rank});

  final RankTier rank;

  bool get _isRadiant => rank.divisionName.toUpperCase() == 'RADIANT';

  @override
  Widget build(BuildContext context) {
    final tile = ClipPath(
      clipper: const DiagonalCutClipper(cut: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.valorantSurface,
          border: Border(left: BorderSide(color: rank.color, width: 3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            if (rank.largeIcon != null)
              SizedBox(
                width: 40,
                height: 40,
                child: FadeInNetworkImage(url: rank.largeIcon!, fit: BoxFit.contain),
              )
            else
              const SizedBox(width: 40, height: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                rank.tierName,
                style: TextStyle(fontWeight: FontWeight.w800, color: rank.color, fontSize: 15),
              ),
            ),
            if (_isRadiant) ...[
              const Icon(Icons.leaderboard, size: 16, color: AppTheme.valorantRed),
              const SizedBox(width: 4),
              const Text(
                'CLASSEMENT',
                style: TextStyle(color: AppTheme.valorantRed, fontSize: 10.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 18, color: AppTheme.valorantRed),
            ],
          ],
        ),
      ),
    );

    if (!_isRadiant) return tile;

    return PressableScale(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RadiantLeaderboardScreen()),
      ),
      child: tile,
    );
  }
}
