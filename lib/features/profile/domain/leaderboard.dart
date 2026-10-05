import 'json_reading.dart';

/// One player of the regional ranked leaderboard.
class LeaderboardPlayer {
  const LeaderboardPlayer({
    required this.rank,
    required this.puuid,
    required this.name,
    required this.tag,
    required this.tierId,
    required this.rankedRating,
    required this.wins,
    required this.cardUuid,
    required this.isAnonymized,
  });

  factory LeaderboardPlayer.fromJson(Map<String, dynamic> json) {
    return LeaderboardPlayer(
      rank: asInt(json['leaderboard_rank'] ?? json['leaderboardRank']),
      puuid: asStringOrNull(json['puuid']),
      name: (json['name'] ?? json['gameName'] ?? '').toString(),
      tag: (json['tag'] ?? json['tagLine'] ?? '').toString(),
      tierId: asInt(json['tier'] ?? json['competitiveTier']),
      rankedRating: asInt(json['rr'] ?? json['rankedRating']),
      wins: asInt(json['wins'] ?? json['numberOfWins']),
      cardUuid: asStringOrNull(json['card'] ?? json['PlayerCardID']),
      isAnonymized: json['is_anonymized'] == true || json['IsAnonymized'] == true,
    );
  }

  final int rank;
  final String? puuid;
  final String name;
  final String tag;
  final int tierId;
  final int rankedRating;
  final int wins;
  final String? cardUuid;

  /// Players can hide their name from the leaderboard.
  final bool isAnonymized;

  String get label {
    if (isAnonymized || name.isEmpty) return 'Joueur anonyme';
    return tag.isEmpty ? name : '$name#$tag';
  }

  /// The small artwork of the player card, from valorant-api.com's media host.
  String? get cardImageUrl {
    final uuid = cardUuid;
    if (uuid == null) return null;
    return 'https://media.valorant-api.com/playercards/$uuid/smallart.png';
  }

  bool matches(String search) {
    final query = search.trim().toLowerCase();
    if (query.isEmpty) return true;
    return label.toLowerCase().contains(query);
  }
}

/// The top of a region's ranked ladder.
class Leaderboard {
  const Leaderboard({required this.players, required this.updatedAt, required this.total});

  factory Leaderboard.fromJson(Object? data) {
    final map = asMap(data);
    final raw = map.isEmpty ? asList(data) : asList(map['players']);

    final players = [
      for (final entry in raw)
        if (entry is Map<String, dynamic>) LeaderboardPlayer.fromJson(entry),
    ]..sort((a, b) => a.rank.compareTo(b.rank));

    return Leaderboard(
      players: players,
      updatedAt: dateOf(map['updated_at']),
      total: players.length,
    );
  }

  final List<LeaderboardPlayer> players;
  final DateTime? updatedAt;
  final int total;
}
