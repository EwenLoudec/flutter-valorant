import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_list_view.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../core/widgets/fade_in_network_image.dart';
import '../../../core/widgets/valorant_input.dart';
import '../../encyclopedia/domain/store_content.dart';
import '../../encyclopedia/providers/encyclopedia_providers.dart';

/// Every store bundle Riot ever sold, with its artwork.
class BundlesScreen extends ConsumerStatefulWidget {
  const BundlesScreen({super.key});

  @override
  ConsumerState<BundlesScreen> createState() => _BundlesScreenState();
}

class _BundlesScreenState extends ConsumerState<BundlesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BUNDLES')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              decoration: valorantInputDecoration(hint: 'Rechercher un bundle'),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          Expanded(
            child: AsyncListView<Bundle>(
              value: ref.watch(bundlesProvider),
              emptyMessage: 'Aucun bundle trouvé.',
              builder: (context, all) {
                final bundles = all.where((bundle) => bundle.matches(_search)).toList();
                if (bundles.isEmpty) return const Center(child: Text('Aucun résultat.'));

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                  itemCount: bundles.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _BundleCard(bundle: bundles[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BundleCard extends StatelessWidget {
  const _BundleCard({required this.bundle});

  final Bundle bundle;

  @override
  Widget build(BuildContext context) {
    final image = bundle.displayIcon;
    final subtitle = bundle.subtitle;

    return ClipPath(
      clipper: const DiagonalCutClipper(cut: 14),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image == null)
              const ColoredBox(color: AppTheme.valorantSurface)
            else
              FadeInNetworkImage(url: image),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bundle.displayName.toUpperCase(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.4),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
