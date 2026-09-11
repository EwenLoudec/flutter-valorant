import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fade_in_network_image.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../../encyclopedia/domain/content_tier.dart';
import '../../encyclopedia/providers/encyclopedia_providers.dart';
import '../domain/owned_skin.dart';
import '../providers/profile_providers.dart';
import 'owned_skins_picker_screen.dart';
import 'profile_section.dart';

/// The skins the player owns. Riot exposes no public inventory endpoint, so
/// the collection is ticked by hand and kept on the device.
class OwnedSkinsSection extends ConsumerWidget {
  const OwnedSkinsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiers = ref.watch(contentTiersProvider).value ?? const <String, ContentTier>{};
    final skins = ref.watch(ownedSkinsProvider).value ?? const <OwnedSkin>[];

    return ProfileSection(
      title: 'Mes skins (${skins.length})',
      action: TextButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const OwnedSkinsPickerScreen()),
        ),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('GÉRER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.valorantRed,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          visualDensity: VisualDensity.compact,
        ),
      ),
      child: skins.isEmpty
          ? const ProfileMessage(
              text: 'Riot ne publie pas l\'inventaire d\'un compte. Appuyez sur GÉRER '
                  'pour cocher les skins que vous possédez.',
              icon: Icons.checkroom_outlined,
            )
          : GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.55,
              children: [
                for (final skin in skins)
                  _SkinTile(skin: skin, tierColor: tiers[skin.contentTierUuid]?.color),
              ],
            ),
    );
  }
}

class _SkinTile extends ConsumerWidget {
  const _SkinTile({required this.skin, required this.tierColor});

  final OwnedSkin skin;
  final Color? tierColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayIcon = skin.displayIcon;
    final accentColor = tierColor ?? AppTheme.outlineDark;

    return PressableScale(
      onTap: () => _confirmRemoval(context, ref),
      child: ProfileCard(
        accentColor: accentColor,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: displayIcon == null
                    ? const Icon(Icons.image_not_supported_outlined, color: Colors.white24)
                    : FadeInNetworkImage(url: displayIcon, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              skin.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: tierColor ?? Colors.white),
            ),
            Text(
              skin.weaponName.toUpperCase(),
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppTheme.valorantMuted),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemoval(BuildContext context, WidgetRef ref) async {
    final removed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.valorantSurface,
        title: const Text('Retirer ce skin ?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Text('${skin.displayName} sera retiré de votre collection.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.valorantRed),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (removed ?? false) await ref.read(ownedSkinsProvider.notifier).toggle(skin);
  }
}
