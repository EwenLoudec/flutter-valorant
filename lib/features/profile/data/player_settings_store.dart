import 'package:shared_preferences/shared_preferences.dart';

import '../domain/owned_skin.dart';
import '../domain/player_query.dart';
import '../domain/player_settings.dart';

/// Persists the profile configuration and the skin collection on the device.
class PlayerSettingsStore {
  static const _riotIdKey = 'profile.riot_id';
  static const _regionKey = 'profile.region';
  static const _apiKeyKey = 'profile.api_key';
  static const _ownedSkinsKey = 'profile.owned_skins';

  Future<PlayerSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    final storedRiotId = preferences.getString(_riotIdKey);

    return PlayerSettings(
      riotId: storedRiotId == null ? null : RiotId.tryParse(storedRiotId),
      region: ValorantRegion.fromCode(preferences.getString(_regionKey)),
      apiKey: preferences.getString(_apiKeyKey) ?? PlayerSettings.defaultApiKey,
    );
  }

  Future<void> save(PlayerSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    final riotId = settings.riotId;

    if (riotId == null) {
      await preferences.remove(_riotIdKey);
    } else {
      await preferences.setString(_riotIdKey, riotId.label);
    }
    await preferences.setString(_regionKey, settings.region.code);
    await preferences.setString(_apiKeyKey, settings.apiKey);
  }

  Future<List<OwnedSkin>> loadOwnedSkins() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getStringList(_ownedSkinsKey) ?? const <String>[];

    return [for (final raw in stored) ?OwnedSkin.tryParse(raw)];
  }

  Future<void> saveOwnedSkins(List<OwnedSkin> skins) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_ownedSkinsKey, [for (final skin in skins) skin.toStorage()]);
  }
}
