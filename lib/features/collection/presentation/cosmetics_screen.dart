import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/diagonal_cut_clipper.dart';
import '../../../core/widgets/fade_in_network_image.dart';
import '../../../core/widgets/valorant_input.dart';
import '../../encyclopedia/domain/cosmetic.dart';
import '../../encyclopedia/providers/encyclopedia_providers.dart';
import '../../profile/providers/profile_providers.dart';

const _ownedColor = Color(0xFF2FBF8F);

/// Every player card, spray, gun buddy and title of the game, with the ones
/// the player owns ticked. Touching an item ticks or unticks it.
class CosmeticsScreen extends StatelessWidget {
  const CosmeticsScreen({super.key, this.initialKind = CosmeticKind.card});

  final CosmeticKind initialKind;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: CosmeticKind.values.length,
      initialIndex: CosmeticKind.values.indexOf(initialKind),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('COLLECTION'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final kind in CosmeticKind.values) Tab(text: kind.label.toUpperCase())],
          ),
        ),
        body: TabBarView(
          children: [for (final kind in CosmeticKind.values) _CosmeticTab(kind: kind)],
        ),
      ),
    );
  }
}

class _CosmeticTab extends ConsumerStatefulWidget {
  const _CosmeticTab({required this.kind});

  final CosmeticKind kind;

  @override
  ConsumerState<_CosmeticTab> createState() => _CosmeticTabState();
}

class _CosmeticTabState extends ConsumerState<_CosmeticTab> with AutomaticKeepAliveClientMixin {
  String _search = '';
  bool _ownedOnly = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final owned = ref.watch(ownedCosmeticsProvider).value?[widget.kind] ?? const <String>{};

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: valorantInputDecoration(hint: 'Rechercher'),
                  onChanged: (value) => setState(() => _search = value),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text('Possédés (${owned.length})'),
                selected: _ownedOnly,
                onSelected: (value) => setState(() => _ownedOnly = value),
                selectedColor: _ownedColor.withValues(alpha: 0.2),
                checkmarkColor: _ownedColor,
                shape: const RoundedRectangleBorder(),
                labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        Expanded(
          child: ref
              .watch(cosmeticsProvider(widget.kind))
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Impossible de charger le catalogue : $error', textAlign: TextAlign.center),
                  ),
                ),
                data: (all) {
                  final items = [
                    for (final item in all)
                      if (item.matches(_search) && (!_ownedOnly || owned.contains(item.uuid))) item,
                  ];
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        _ownedOnly ? 'Rien de coché pour l\'instant.' : 'Aucun résultat.',
                        style: const TextStyle(color: AppTheme.valorantMuted),
                      ),
                    );
                  }

                  if (widget.kind == CosmeticKind.title) {
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) => _TitleRow(
                        cosmetic: items[index],
                        isOwned: owned.contains(items[index].uuid),
                        onTap: () => ref.read(ownedCosmeticsProvider.notifier).toggle(items[index]),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: widget.kind == CosmeticKind.card ? 0.62 : 0.8,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _CosmeticTile(
                      cosmetic: items[index],
                      isOwned: owned.contains(items[index].uuid),
                      onTap: () => ref.read(ownedCosmeticsProvider.notifier).toggle(items[index]),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }
}

class _CosmeticTile extends StatelessWidget {
  const _CosmeticTile({required this.cosmetic, required this.isOwned, required this.onTap});

  final Cosmetic cosmetic;
  final bool isOwned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = cosmetic.imageUrl;

    return GestureDetector(
      onTap: onTap,
      child: ClipPath(
        clipper: const DiagonalCutClipper(cut: 8),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.valorantSurface,
            border: Border.all(color: isOwned ? _ownedColor : AppTheme.outlineDark, width: isOwned ? 2 : 1),
          ),
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (image == null)
                      const Icon(Icons.image_not_supported_outlined, color: Colors.white24)
                    else
                      FadeInNetworkImage(
                        url: image,
                        fit: cosmetic.kind == CosmeticKind.card ? BoxFit.cover : BoxFit.contain,
                      ),
                    if (isOwned)
                      const Align(
                        alignment: Alignment.topRight,
                        child: Icon(Icons.check_circle, size: 18, color: _ownedColor),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                cosmetic.displayName,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.cosmetic, required this.isOwned, required this.onTap});

  final Cosmetic cosmetic;
  final bool isOwned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppTheme.valorantSurface,
          border: Border(left: BorderSide(color: isOwned ? _ownedColor : AppTheme.outlineDark, width: 3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cosmetic.titleText ?? cosmetic.displayName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(cosmetic.displayName, style: const TextStyle(fontSize: 10.5, color: AppTheme.valorantMuted)),
                ],
              ),
            ),
            Icon(
              isOwned ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 20,
              color: isOwned ? _ownedColor : Colors.white24,
            ),
          ],
        ),
      ),
    );
  }
}
