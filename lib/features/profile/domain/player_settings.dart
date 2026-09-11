import 'player_query.dart';

/// The locally stored profile configuration: which account to look up, and
/// with which HenrikDev API key.
class PlayerSettings {
  const PlayerSettings({this.riotId, this.region = ValorantRegion.eu, this.apiKey = defaultApiKey});

  /// Lets a key be baked in at build time:
  /// `flutter run --dart-define=HENRIK_API_KEY=HDEV-...`.
  static const defaultApiKey = String.fromEnvironment('HENRIK_API_KEY');

  final RiotId? riotId;
  final ValorantRegion region;
  final String apiKey;

  bool get isComplete => riotId != null && apiKey.isNotEmpty;

  PlayerQuery? get query {
    final riotId = this.riotId;
    if (riotId == null) return null;
    return PlayerQuery(riotId: riotId, region: region);
  }

  PlayerSettings copyWith({RiotId? riotId, ValorantRegion? region, String? apiKey}) {
    return PlayerSettings(
      riotId: riotId ?? this.riotId,
      region: region ?? this.region,
      apiKey: apiKey ?? this.apiKey,
    );
  }
}
