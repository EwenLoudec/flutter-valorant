import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../encyclopedia/domain/agent.dart';
import '../../encyclopedia/domain/cosmetic.dart';
import '../../encyclopedia/domain/store_content.dart';
import '../../encyclopedia/providers/encyclopedia_providers.dart';
import '../../profile/domain/featured_store.dart';
import '../../profile/providers/profile_providers.dart';
import '../domain/reward_catalog.dart';
import '../domain/skin_prices.dart';

/// Waits for a catalogue, settling for [fallback] when it cannot load.
Future<T> _orElse<T>(Future<T> future, T fallback) async {
  try {
    return await future;
  } on Object {
    return fallback;
  }
}

/// Everything needed to name contract rewards. Several MB in total, so it is
/// only built when a contract is opened.
final rewardCatalogProvider = FutureProvider<RewardCatalog>((ref) async {
  final results = await Future.wait<Object>([
    _orElse(ref.watch(cosmeticsProvider(CosmeticKind.card).future), const <Cosmetic>[]),
    _orElse(ref.watch(cosmeticsProvider(CosmeticKind.spray).future), const <Cosmetic>[]),
    _orElse(ref.watch(cosmeticsProvider(CosmeticKind.buddy).future), const <Cosmetic>[]),
    _orElse(ref.watch(cosmeticsProvider(CosmeticKind.title).future), const <Cosmetic>[]),
    _orElse(ref.watch(currenciesProvider.future), const <Currency>[]),
    _orElse(ref.watch(skinLevelsProvider.future), const <String, SkinLevelInfo>{}),
    _orElse(ref.watch(agentsProvider.future), const <Agent>[]),
  ]);

  return RewardCatalog(
    cards: results[0] as List<Cosmetic>,
    sprays: results[1] as List<Cosmetic>,
    buddies: results[2] as List<Cosmetic>,
    titles: results[3] as List<Cosmetic>,
    currencies: results[4] as List<Currency>,
    skinLevels: results[5] as Map<String, SkinLevelInfo>,
    agents: results[6] as List<Agent>,
  );
});

/// Every paid skin with its price. The featured store only sharpens the
/// prices of the skins on sale today: without it, or without an API key, the
/// list stands on the editions alone.
final skinPriceListProvider = FutureProvider<SkinPriceList>((ref) async {
  final weapons = await ref.watch(allWeaponsProvider.future);
  final featured = await _orElse(ref.watch(featuredStoreProvider.future), const <FeaturedBundle>[]);
  return SkinPriceList.from(weapons, featured: featured);
});
