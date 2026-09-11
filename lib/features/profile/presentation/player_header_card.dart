import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../core/widgets/fade_in_network_image.dart';
import '../domain/player_account.dart';
import '../domain/player_query.dart';
import '../providers/profile_providers.dart';
import 'profile_error.dart';
import 'profile_section.dart';

/// Player card banner: who the profile belongs to, and their account level.
class PlayerHeaderCard extends ConsumerWidget {
  const PlayerHeaderCard({super.key, required this.query});

  final PlayerQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(playerAccountProvider(query))
        .when(
          loading: () => const ProfileMessage.loading(text: 'Recherche du compte…'),
          error: (error, _) => ProfileMessage(text: profileErrorText(error), icon: Icons.person_off_outlined),
          data: (account) => _Banner(account: account, region: query.region),
        );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.account, required this.region});

  final PlayerAccount account;
  final ValorantRegion region;

  @override
  Widget build(BuildContext context) {
    final cardWide = account.cardWide;

    return ClipPath(
      clipper: const DiagonalCutClipper(cut: 12),
      child: SizedBox(
        height: 104,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (cardWide != null) FadeInNetworkImage(url: cardWide) else const ColoredBox(color: AppTheme.valorantSurface),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xEE0F1923), Color(0x660F1923)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.4),
                  ),
                  Text(
                    '#${account.tag}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.valorantRed),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Tag(text: 'NIVEAU ${account.accountLevel}'),
                      const SizedBox(width: 6),
                      _Tag(text: region.code.toUpperCase()),
                    ],
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

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      color: Colors.black54,
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Colors.white70),
      ),
    );
  }
}
