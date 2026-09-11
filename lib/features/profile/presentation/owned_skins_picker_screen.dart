import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_list_view.dart';
import '../../../core/widgets/fade_in_network_image.dart';
import '../../encyclopedia/domain/content_tier.dart';
import '../../encyclopedia/domain/weapon.dart';
import '../../encyclopedia/domain/weapon_skin.dart';
import '../../encyclopedia/providers/encyclopedia_providers.dart';
import '../domain/owned_skin.dart';
import '../providers/profile_providers.dart';

/// Weapon list from which the player ticks the skins they own.
class OwnedSkinsPickerScreen extends ConsumerWidget {
  const OwnedSkinsPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('MA COLLECTION')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              'Riot ne publie pas l\'inventaire d\'un compte : choisissez une arme, '
              'puis cochez les skins que vous possédez.',
              style: TextStyle(fontSize: 12, color: AppTheme.valorantMuted, height: 1.4),
            ),
          ),
          Expanded(
            child: AsyncListView<Weapon>(
              value: ref.watch(weaponsProvider),
              emptyMessage: 'Aucune arme trouvée.',
              builder: (context, weapons) => ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: weapons.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) => _WeaponRow(weapon: weapons[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeaponRow extends ConsumerWidget {
  const _WeaponRow({required this.weapon});

  final Weapon weapon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayIcon = weapon.displayIcon;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: SizedBox(
        width: 56,
        height: 32,
        child: displayIcon == null
            ? const Icon(Icons.gps_fixed, color: Colors.white24)
            : FadeInNetworkImage(url: displayIcon, fit: BoxFit.contain),
      ),
      title: Text(
        weapon.displayName.toUpperCase(),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.3),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.valorantMuted),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _WeaponSkinsScreen(weapon: weapon)),
      ),
    );
  }
}

class _WeaponSkinsScreen extends ConsumerWidget {
  const _WeaponSkinsScreen({required this.weapon});

  final Weapon weapon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiers = ref.watch(contentTiersProvider).value ?? const <String, ContentTier>{};
    final ownedUuids = ref.watch(ownedSkinUuidsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(weapon.displayName.toUpperCase())),
      body: AsyncListView<WeaponSkin>(
        value: ref.watch(weaponSkinsProvider(weapon.uuid)),
        emptyMessage: 'Aucun skin pour cette arme.',
        builder: (context, skins) => ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: skins.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final skin = skins[index];
            return _SkinRow(
              skin: skin,
              tierColor: tiers[skin.contentTierUuid]?.color,
              isOwned: ownedUuids.contains(skin.uuid),
              onToggle: () => ref.read(ownedSkinsProvider.notifier).toggle(
                OwnedSkin(
                  uuid: skin.uuid,
                  displayName: skin.displayName,
                  weaponName: weapon.displayName,
                  displayIcon: skin.displayIcon,
                  contentTierUuid: skin.contentTierUuid,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SkinRow extends StatelessWidget {
  const _SkinRow({required this.skin, required this.tierColor, required this.isOwned, required this.onToggle});

  final WeaponSkin skin;
  final Color? tierColor;
  final bool isOwned;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final displayIcon = skin.displayIcon;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: SizedBox(
        width: 64,
        height: 34,
        child: displayIcon == null
            ? const Icon(Icons.image_not_supported_outlined, color: Colors.white24)
            : FadeInNetworkImage(url: displayIcon, fit: BoxFit.contain),
      ),
      title: Text(
        skin.displayName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: tierColor ?? Colors.white,
        ),
      ),
      trailing: Checkbox(
        value: isOwned,
        activeColor: AppTheme.valorantRed,
        shape: const RoundedRectangleBorder(),
        onChanged: (_) => onToggle(),
      ),
      onTap: onToggle,
    );
  }
}
