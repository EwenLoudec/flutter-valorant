import 'package:shared_preferences/shared_preferences.dart';

import '../../encyclopedia/domain/cosmetic.dart';

/// The cards, sprays, buddies and titles the player ticked as owned. As for
/// skins, Riot publishes no inventory, so the list lives on the device.
class CosmeticCollectionStore {
  static String _keyFor(CosmeticKind kind) => 'collection.${kind.name}';

  Future<Map<CosmeticKind, Set<String>>> load() async {
    final preferences = await SharedPreferences.getInstance();
    return {
      for (final kind in CosmeticKind.values)
        kind: {...preferences.getStringList(_keyFor(kind)) ?? const <String>[]},
    };
  }

  Future<void> save(CosmeticKind kind, Set<String> uuids) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_keyFor(kind), uuids.toList()..sort());
  }
}
