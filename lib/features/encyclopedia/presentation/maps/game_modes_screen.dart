import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/async_list_view.dart';
import '../../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../../core/widgets/fade_in_network_image.dart';
import '../../domain/store_content.dart';
import '../../providers/encyclopedia_providers.dart';

/// The game modes of the client, with their rules in a sentence and their
/// usual length.
class GameModesScreen extends ConsumerWidget {
  const GameModesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('MODES DE JEU')),
      body: AsyncListView<GameMode>(
        value: ref.watch(gameModesProvider),
        emptyMessage: 'Aucun mode trouvé.',
        builder: (context, modes) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
          itemCount: modes.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _ModeCard(mode: modes[index]),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode});

  final GameMode mode;

  @override
  Widget build(BuildContext context) {
    final icon = mode.displayIcon;
    final description = mode.description;

    return ClipPath(
      clipper: const DiagonalCutClipper(cut: 10),
      child: Container(
        color: AppTheme.valorantSurface,
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: icon == null
                  ? const Icon(Icons.sports_esports_outlined, color: Colors.white24)
                  : FadeInNetworkImage(url: icon, fit: BoxFit.contain),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          mode.displayName.toUpperCase(),
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                        ),
                      ),
                      if (mode.duration != null)
                        Text(
                          mode.duration!,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.valorantRed,
                          ),
                        ),
                    ],
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(description, style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.45)),
                  ],
                  if (mode.roundsPerHalf > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Changement de camp après ${mode.roundsPerHalf} manche${mode.roundsPerHalf > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 10.5, color: AppTheme.valorantMuted),
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
