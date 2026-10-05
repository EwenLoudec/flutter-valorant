import 'json_reading.dart';

/// The RR movement of one competitive game, from the MMR history endpoint.
class RankHistoryEntry {
  const RankHistoryEntry({
    required this.matchId,
    required this.date,
    required this.tierId,
    required this.tierName,
    required this.rankedRating,
    required this.lastChange,
    required this.elo,
    required this.mapName,
    required this.seasonShort,
  });

  factory RankHistoryEntry.fromJson(Map<String, dynamic> json) {
    final tier = json['tier'];

    return RankHistoryEntry(
      matchId: (json['match_id'] ?? '').toString(),
      date: dateOf(json['date'] ?? json['date_raw']),
      tierId: tier is Map<String, dynamic> ? asInt(tier['id']) : asInt(json['currenttier']),
      tierName: tier is Map<String, dynamic>
          ? (tier['name'] ?? '').toString()
          : (json['currenttierpatched'] ?? '').toString(),
      rankedRating: asInt(json['rr'] ?? json['ranking_in_tier']),
      lastChange: asInt(json['last_change'] ?? json['mmr_change_to_last_game']),
      elo: asInt(json['elo']),
      mapName: displayNameOf(json['map']),
      seasonShort: asStringOrNull(asMap(json['season'])['short']),
    );
  }

  /// Most recent first, as the API sends them; entries without an elo are
  /// dropped since they cannot be placed on the curve.
  static List<RankHistoryEntry> listFromJson(Object? data) {
    final map = asMap(data);
    final raw = map.isEmpty ? asList(data) : asList(map['history']);

    final entries = [
      for (final entry in raw)
        if (entry is Map<String, dynamic>) RankHistoryEntry.fromJson(entry),
    ].where((entry) => entry.elo > 0).toList();

    entries.sort((a, b) {
      final aDate = a.date;
      final bDate = b.date;
      if (aDate == null || bDate == null) return 0;
      return bDate.compareTo(aDate);
    });
    return entries;
  }

  final String matchId;
  final DateTime? date;
  final int tierId;
  final String tierName;
  final int rankedRating;
  final int lastChange;

  /// Tier × 100 + RR: one continuous number across rank changes, the only
  /// value a single curve can follow.
  final int elo;
  final String mapName;
  final String? seasonShort;
}
