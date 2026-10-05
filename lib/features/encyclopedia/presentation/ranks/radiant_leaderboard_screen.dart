import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../../core/widgets/fade_in_network_image.dart';
import '../../../../core/widgets/valorant_input.dart';
import '../../../profile/domain/leaderboard.dart';
import '../../../profile/domain/player_query.dart';
import '../../../profile/presentation/missing_api_key_notice.dart';
import '../../../profile/presentation/profile_error.dart';
import '../../../profile/providers/profile_providers.dart';
import '../../domain/rank_tier.dart';
import '../../providers/encyclopedia_providers.dart';

/// The top of the regional ranked ladder, from the HenrikDev leaderboard.
/// It needs the API key saved on the profile page.
class RadiantLeaderboardScreen extends ConsumerStatefulWidget {
  const RadiantLeaderboardScreen({super.key});

  @override
  ConsumerState<RadiantLeaderboardScreen> createState() => _RadiantLeaderboardScreenState();
}

class _RadiantLeaderboardScreenState extends ConsumerState<RadiantLeaderboardScreen> {
  ValorantRegion? _region;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(playerSettingsProvider).value;
    final region = _region ?? settings?.region ?? ValorantRegion.eu;
    final hasKey = settings?.apiKey.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('CLASSEMENT')),
      backgroundColor: AppTheme.valorantDark,
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : !hasKey
          ? const _MissingKey()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: DropdownButtonFormField<String>(
                          initialValue: region.code,
                          isExpanded: true,
                          decoration: valorantInputDecoration(),
                          dropdownColor: AppTheme.valorantSurface,
                          items: [
                            for (final option in ValorantRegion.all)
                              DropdownMenuItem(value: option.code, child: Text(option.label)),
                          ],
                          onChanged: (code) => setState(() => _region = ValorantRegion.fromCode(code)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 6,
                        child: TextField(
                          decoration: valorantInputDecoration(hint: 'Chercher un joueur'),
                          onChanged: (value) => setState(() => _search = value),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _LeaderboardList(
                    region: region,
                    search: _search,
                    ownRiotId: settings.riotId,
                  ),
                ),
              ],
            ),
    );
  }
}

class _LeaderboardList extends ConsumerWidget {
  const _LeaderboardList({required this.region, required this.search, required this.ownRiotId});

  final ValorantRegion region;
  final String search;
  final RiotId? ownRiotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiers = ref.watch(rankTiersProvider).value ?? const <RankTier>[];
    final tiersById = {for (final tier in tiers) tier.tier: tier};

    return ref
        .watch(leaderboardProvider(region.code))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Message(text: profileErrorText(error), icon: Icons.cloud_off),
          data: (leaderboard) {
            final players = leaderboard.players.where((player) => player.matches(search)).toList();
            if (leaderboard.players.isEmpty) {
              return const _Message(text: 'Classement vide pour cette région.', icon: Icons.leaderboard_outlined);
            }
            if (players.isEmpty) {
              return const _Message(
                text: 'Aucun joueur de ce top ne correspond à la recherche.',
                icon: Icons.search_off,
              );
            }

            return RefreshIndicator(
              color: AppTheme.valorantRed,
              backgroundColor: AppTheme.valorantSurface,
              onRefresh: () => ref.refresh(leaderboardProvider(region.code).future),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: players.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Text(
                      'Top ${leaderboard.players.length} · ${region.label}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.valorantMuted),
                    );
                  }
                  final player = players[index - 1];
                  final ownRiotId = this.ownRiotId;
                  return _PlayerRow(
                    player: player,
                    tier: tiersById[player.tierId],
                    isSelf: ownRiotId != null &&
                        !player.isAnonymized &&
                        player.name.toLowerCase() == ownRiotId.name.toLowerCase() &&
                        player.tag.toLowerCase() == ownRiotId.tag.toLowerCase(),
                  );
                },
              ),
            );
          },
        );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player, required this.tier, required this.isSelf});

  final LeaderboardPlayer player;
  final RankTier? tier;
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    final card = player.cardImageUrl;
    final tierIcon = tier?.largeIcon;
    final color = tier?.color ?? AppTheme.valorantRed;

    return ClipPath(
      clipper: const DiagonalCutClipper(cut: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isSelf ? const Color(0xFF243039) : AppTheme.valorantSurface,
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                '#${player.rank}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white70),
              ),
            ),
            SizedBox(
              width: 32,
              height: 32,
              child: card == null
                  ? const Icon(Icons.person, color: Colors.white24)
                  : FadeInNetworkImage(url: card, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: player.isAnonymized ? AppTheme.valorantMuted : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${player.wins} victoire${player.wins > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 10.5, color: AppTheme.valorantMuted),
                  ),
                ],
              ),
            ),
            if (tierIcon != null) SizedBox(width: 24, height: 24, child: FadeInNetworkImage(url: tierIcon, fit: BoxFit.contain)),
            const SizedBox(width: 8),
            Text(
              '${player.rankedRating} RR',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingKey extends StatelessWidget {
  const _MissingKey();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: MissingApiKeyNotice(),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: Colors.white24),
            const SizedBox(height: 14),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
