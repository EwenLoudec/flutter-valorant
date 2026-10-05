import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../core/widgets/entry_tile.dart';
import '../../../core/widgets/fade_in_network_image.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/staggered_fade_slide.dart';
import '../../collection/presentation/skin_prices_screen.dart';
import '../../encyclopedia/domain/cosmetic.dart';
import '../../encyclopedia/domain/store_content.dart';
import '../../encyclopedia/providers/encyclopedia_providers.dart';
import '../domain/featured_store.dart';
import '../providers/profile_providers.dart';
import 'profile_error.dart';
import 'profile_section.dart';

/// The Valorant Points icon, from the currency catalogue.
const valorantPointsIcon =
    'https://media.valorant-api.com/currencies/85ad13f7-3d1b-5128-9eb2-7cd8ee0b5741/displayicon.png';

const _storeGold = Color(0xFFFFC25A);

/// The bundles on sale right now in the store, with their items and prices.
class FeaturedStoreSection extends ConsumerWidget {
  const FeaturedStoreSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundles = ref.watch(bundlesProvider).value ?? const <Bundle>[];
    final bundleById = {for (final bundle in bundles) bundle.uuid: bundle};
    final names = <String, String>{
      for (final kind in [CosmeticKind.card, CosmeticKind.spray, CosmeticKind.buddy, CosmeticKind.title])
        for (final cosmetic in ref.watch(cosmeticsProvider(kind)).value ?? const <Cosmetic>[])
          cosmetic.uuid: cosmetic.titleText ?? cosmetic.displayName,
    };

    return ProfileSection(
      title: 'Boutique en vedette',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StoreNotice(),
          const SizedBox(height: 8),
          EntryTileRow(
            tiles: [
              EntryTile(
                icon: Icons.sell_outlined,
                title: 'PRIX DE TOUS LES SKINS',
                subtitle: 'Ce qui peut tomber dans ta boutique, gamme par gamme',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SkinPricesScreen())),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ref
              .watch(featuredStoreProvider)
              .when(
                loading: () => const ProfileMessage.loading(text: 'Ouverture de la boutique…'),
                error: (error, _) => ProfileMessage(text: profileErrorText(error), icon: Icons.storefront_outlined),
                data: (featured) {
                  if (featured.isEmpty) {
                    return const ProfileMessage(
                      text: 'Aucun pack en vedette pour le moment.',
                      icon: Icons.storefront_outlined,
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (index, bundle) in featured.indexed) ...[
                        if (index > 0) const SizedBox(height: 22),
                        StaggeredFadeSlide(
                          index: index,
                          child: _BundleCard(bundle: bundle, info: bundleById[bundle.uuid], names: names),
                        ),
                      ],
                    ],
                  );
                },
              ),
        ],
      ),
    );
  }
}

class _StoreNotice extends StatelessWidget {
  const _StoreNotice();

  @override
  Widget build(BuildContext context) {
    return const ProfileCard(
      accentColor: _storeGold,
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: _storeGold),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Les packs en vedette sont les mêmes pour tous les joueurs. Les 4 offres du jour '
              'propres à chaque compte ne sont visibles que dans le jeu : Riot ne les donne à '
              'aucune application.',
              style: TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _BundleCard extends StatelessWidget {
  const _BundleCard({required this.bundle, required this.info, required this.names});

  final FeaturedBundle bundle;
  final Bundle? info;
  final Map<String, String> names;

  @override
  Widget build(BuildContext context) {
    final art = info?.displayIcon ?? 'https://media.valorant-api.com/bundles/${bundle.uuid}/displayicon.png';
    final name = info?.displayName.trim();
    final remaining = bundle.remaining(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipPath(
          clipper: const DiagonalCutClipper(cut: 14),
          child: AspectRatio(
            aspectRatio: 16 / 8,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: AppTheme.valorantSurface),
                FadeInNetworkImage(url: art),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x220F1923), Color(0x000F1923), Color(0xF20F1923)],
                      stops: [0, 0.45, 1],
                    ),
                  ),
                ),
                const _ShineSweep(),
                if (remaining != null)
                  Positioned(
                    left: 10,
                    top: 10,
                    child: _Badge(
                      icon: Icons.timer_outlined,
                      text: 'ENCORE ${FeaturedBundle.formatRemaining(remaining).toUpperCase()}',
                    ),
                  ),
                if (bundle.savings > 0)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: _Badge(text: '−${bundle.savings} VP', color: AppTheme.valorantRed),
                  ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'PACK',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: _storeGold,
                              ),
                            ),
                            Text(
                              (name == null || name.isEmpty ? 'Pack en vedette' : name).toUpperCase(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _Price(price: bundle.price, size: 17),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${bundle.items.length} objet${bundle.items.length > 1 ? 's' : ''}'
          '${bundle.savings > 0 ? ' · ${bundle.separatePrice} VP à l\'unité' : ''}'
          '${bundle.wholesaleOnly ? ' · vendu en pack uniquement' : ''}',
          style: const TextStyle(fontSize: 11, color: AppTheme.valorantMuted),
        ),
        const SizedBox(height: 8),
        _ItemGrid(items: bundle.items, names: names),
      ],
    );
  }
}

class _ItemGrid extends StatelessWidget {
  const _ItemGrid({required this.items, required this.names});

  final List<StoreItem> items;
  final Map<String, String> names;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var start = 0; start < items.length; start += 2) ...[
          if (start > 0) const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = start; index < start + 2; index++) ...[
                  if (index > start) const SizedBox(width: 8),
                  Expanded(
                    child: index < items.length
                        ? StaggeredFadeSlide(
                            index: index,
                            child: _ItemCard(item: items[index], name: names[items[index].uuid]),
                          )
                        : const SizedBox(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.name});

  final StoreItem item;

  /// The French name, when the catalogue knows the item.
  final String? name;

  static Color _colorOf(StoreItemType type) => switch (type) {
    StoreItemType.skin => _storeGold,
    StoreItemType.card => const Color(0xFF4FD1C5),
    StoreItemType.spray => const Color(0xFFC77DFF),
    StoreItemType.buddy => const Color(0xFFFF7A2F),
    StoreItemType.title => const Color(0xFF8A99A8),
    StoreItemType.other => const Color(0xFF8A99A8),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colorOf(item.type);
    final image = item.image;
    final label = name ?? item.name;

    return ClipPath(
      clipper: const DiagonalCutClipper(cut: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.valorantSurface,
          border: Border(bottom: BorderSide(color: color, width: 2)),
        ),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 64,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: RadialGradient(colors: [color.withValues(alpha: 0.22), Colors.transparent]),
              ),
              padding: const EdgeInsets.all(4),
              child: image == null
                  ? Icon(Icons.local_offer_outlined, color: color.withValues(alpha: 0.7))
                  : FadeInNetworkImage(url: image, fit: BoxFit.contain),
            ),
            const SizedBox(height: 8),
            Text(
              '${item.type.label.toUpperCase()}${item.amount > 1 ? ' ×${item.amount}' : ''}',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: color),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                label.isEmpty ? 'Objet' : label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, height: 1.2),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Price(price: item.discountedPrice, size: 12.5),
                if (item.isDiscounted)
                  Text(
                    '${item.basePrice}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppTheme.valorantMuted,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppTheme.valorantMuted,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Price extends StatelessWidget {
  const _Price({required this.price, required this.size});

  final int price;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: size,
          child: const FadeInNetworkImage(url: valorantPointsIcon, fit: BoxFit.contain),
        ),
        const SizedBox(width: 4),
        Text(
          '$price',
          style: TextStyle(fontSize: size, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.icon, this.color = Colors.black87});

  final String text;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      color: color.withValues(alpha: 0.85),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: Colors.white), const SizedBox(width: 4)],
          Text(text, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
        ],
      ),
    );
  }
}

/// A band of light crossing the banner every few seconds, like a store
/// highlight. Nothing moves under reduced motion.
class _ShineSweep extends StatefulWidget {
  const _ShineSweep();

  @override
  State<_ShineSweep> createState() => _ShineSweepState();
}

class _ShineSweepState extends State<_ShineSweep> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (motionDisabled(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (motionDisabled(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // The band crosses during the first 40 % of the cycle, then rests.
          final pass = math.min(1.0, _controller.value / 0.4);
          if (pass >= 1) return const SizedBox.shrink();
          final position = -1.6 + pass * 3.2;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(position - 0.5, -1),
                end: Alignment(position + 0.5, 1),
                colors: const [Color(0x00FFFFFF), Color(0x2EFFFFFF), Color(0x00FFFFFF)],
              ),
            ),
          );
        },
      ),
    );
  }
}
