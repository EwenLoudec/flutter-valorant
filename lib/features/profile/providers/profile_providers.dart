import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/henrik_api_client.dart';
import '../../encyclopedia/domain/cosmetic.dart';
import '../data/cosmetic_collection_store.dart';
import '../data/henrik_player_repository.dart';
import '../data/player_repository.dart';
import '../data/player_settings_store.dart';
import '../domain/leaderboard.dart';
import '../domain/owned_skin.dart';
import '../domain/player_account.dart';
import '../domain/player_match.dart';
import '../domain/player_query.dart';
import '../domain/player_rank.dart';
import '../domain/player_settings.dart';
import '../domain/player_stats_summary.dart';
import '../domain/rank_history.dart';
import '../domain/weapon_accuracy.dart';

/// How many recent matches the profile pulls in one go. The API returns the
/// full round detail of each one, so this stays small on purpose.
const matchHistorySize = 10;

final playerSettingsStoreProvider = Provider<PlayerSettingsStore>((ref) {
  return PlayerSettingsStore();
});

class PlayerSettingsNotifier extends AsyncNotifier<PlayerSettings> {
  @override
  Future<PlayerSettings> build() {
    return ref.read(playerSettingsStoreProvider).load();
  }

  Future<void> save(PlayerSettings settings) async {
    state = AsyncData(settings);
    await ref.read(playerSettingsStoreProvider).save(settings);
  }

  /// Drops the saved Riot ID but keeps the API key, so the user only has to
  /// type the account again.
  Future<void> forgetRiotId() async {
    final current = state.value ?? const PlayerSettings();
    await save(PlayerSettings(region: current.region, apiKey: current.apiKey));
  }
}

final playerSettingsProvider = AsyncNotifierProvider<PlayerSettingsNotifier, PlayerSettings>(
  PlayerSettingsNotifier.new,
);

/// null until settings are loaded, or while no Riot ID has been saved.
final playerQueryProvider = Provider<PlayerQuery?>((ref) {
  return ref.watch(playerSettingsProvider).value?.query;
});

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  final apiKey = ref.watch(playerSettingsProvider).value?.apiKey ?? '';
  return HenrikPlayerRepository(apiKey: apiKey);
});

/// A refused key or an unknown Riot ID will fail again just the same: only a
/// hiccup on Riot's side is worth a second attempt. Without this, Riverpod
/// retries ten times before showing anything, and the page stays on its
/// spinner for half a minute.
Duration? _retryTransientFailures(int retryCount, Object error) {
  if (error is HenrikApiException && !error.isTransient) return null;
  if (retryCount >= 2) return null;
  return Duration(milliseconds: 600 * (retryCount + 1));
}

final playerAccountProvider = FutureProvider.family<PlayerAccount, PlayerQuery>((ref, query) {
  return ref.watch(playerRepositoryProvider).getAccount(query.riotId);
}, retry: _retryTransientFailures);

final playerRankProvider = FutureProvider.family<PlayerRank, PlayerQuery>((ref, query) {
  return ref.watch(playerRepositoryProvider).getRank(query);
}, retry: _retryTransientFailures);

final playerMatchesProvider = FutureProvider.family<List<PlayerMatch>, PlayerQuery>((ref, query) async {
  final account = await ref.watch(playerAccountProvider(query).future);
  return ref.watch(playerRepositoryProvider).getMatches(
    query,
    puuid: account.puuid,
    size: matchHistorySize,
  );
}, retry: _retryTransientFailures);

/// Derived from the very same match payload, so it costs no extra request.
final weaponAccuracyProvider = FutureProvider.family<List<WeaponAccuracy>, PlayerQuery>((ref, query) async {
  final matches = await ref.watch(playerMatchesProvider(query).future);
  return WeaponAccuracy.aggregate(matches);
}, retry: _retryTransientFailures);

/// RR movement of the recent competitive games, most recent first.
final playerRankHistoryProvider = FutureProvider.family<List<RankHistoryEntry>, PlayerQuery>((ref, query) {
  return ref.watch(playerRepositoryProvider).getRankHistory(query);
}, retry: _retryTransientFailures);

/// Per agent, per map, per side and per session figures, all computed from
/// the loaded matches. The RR history only adds the session's RR balance, so
/// its failure never hides the rest.
final playerStatsSummaryProvider = FutureProvider.family<PlayerStatsSummary, PlayerQuery>((ref, query) async {
  final matches = await ref.watch(playerMatchesProvider(query).future);

  var rankHistory = const <RankHistoryEntry>[];
  try {
    rankHistory = await ref.watch(playerRankHistoryProvider(query).future);
  } on Object {
    // Keep the summary without the RR balance.
  }
  return PlayerStatsSummary.from(matches, rankHistory: rankHistory);
}, retry: _retryTransientFailures);

/// The top of one region's ranked ladder, keyed by region code.
final leaderboardProvider = FutureProvider.family<Leaderboard, String>((ref, regionCode) {
  return ref.watch(playerRepositoryProvider).getLeaderboard(ValorantRegion.fromCode(regionCode));
}, retry: _retryTransientFailures);

/// Riot exposes no public endpoint for an account's owned skins, so the
/// collection is curated by the user and kept on the device.
class OwnedSkinsNotifier extends AsyncNotifier<List<OwnedSkin>> {
  @override
  Future<List<OwnedSkin>> build() {
    return ref.read(playerSettingsStoreProvider).loadOwnedSkins();
  }

  Future<void> toggle(OwnedSkin skin) async {
    final owned = [...?state.value];
    final removed = owned.length;
    owned.removeWhere((entry) => entry.uuid == skin.uuid);
    if (owned.length == removed) owned.add(skin);

    owned.sort((a, b) => a.weaponName.compareTo(b.weaponName));
    state = AsyncData(owned);
    await ref.read(playerSettingsStoreProvider).saveOwnedSkins(owned);
  }
}

final ownedSkinsProvider = AsyncNotifierProvider<OwnedSkinsNotifier, List<OwnedSkin>>(
  OwnedSkinsNotifier.new,
);

/// The uuids of the owned skins, for quick membership checks in the picker.
final ownedSkinUuidsProvider = Provider<Set<String>>((ref) {
  final owned = ref.watch(ownedSkinsProvider).value ?? const <OwnedSkin>[];
  return {for (final skin in owned) skin.uuid};
});

final cosmeticCollectionStoreProvider = Provider<CosmeticCollectionStore>((ref) => CosmeticCollectionStore());

/// The cosmetics ticked as owned, per kind.
class OwnedCosmeticsNotifier extends AsyncNotifier<Map<CosmeticKind, Set<String>>> {
  @override
  Future<Map<CosmeticKind, Set<String>>> build() {
    return ref.read(cosmeticCollectionStoreProvider).load();
  }

  Future<void> toggle(Cosmetic cosmetic) async {
    final current = state.value ?? const <CosmeticKind, Set<String>>{};
    final owned = {...?current[cosmetic.kind]};
    if (!owned.remove(cosmetic.uuid)) owned.add(cosmetic.uuid);

    state = AsyncData({...current, cosmetic.kind: owned});
    await ref.read(cosmeticCollectionStoreProvider).save(cosmetic.kind, owned);
  }
}

final ownedCosmeticsProvider = AsyncNotifierProvider<OwnedCosmeticsNotifier, Map<CosmeticKind, Set<String>>>(
  OwnedCosmeticsNotifier.new,
);
