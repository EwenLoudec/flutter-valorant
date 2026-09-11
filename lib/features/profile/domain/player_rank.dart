/// Competitive standing of a player: current tier and RR, plus the best tier
/// ever reached.
class PlayerRank {
  const PlayerRank({
    required this.tierId,
    required this.tierName,
    required this.rankedRating,
    required this.elo,
    required this.lastChange,
    required this.gamesNeededForRating,
    required this.peakTierId,
    required this.peakTierName,
    required this.peakSeason,
  });

  factory PlayerRank.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>? ?? const {};
    final currentTier = current['tier'] as Map<String, dynamic>? ?? const {};
    final peak = json['peak'] as Map<String, dynamic>? ?? const {};
    final peakTier = peak['tier'] as Map<String, dynamic>? ?? const {};
    final peakSeason = peak['season'] as Map<String, dynamic>? ?? const {};

    return PlayerRank(
      tierId: currentTier['id'] as int? ?? 0,
      tierName: currentTier['name'] as String? ?? 'Non classé',
      rankedRating: current['rr'] as int? ?? 0,
      elo: current['elo'] as int? ?? 0,
      lastChange: current['last_change'] as int? ?? 0,
      gamesNeededForRating: current['games_needed_for_rating'] as int? ?? 0,
      peakTierId: peakTier['id'] as int?,
      peakTierName: peakTier['name'] as String?,
      peakSeason: peakSeason['short'] as String?,
    );
  }

  final int tierId;
  final String tierName;
  final int rankedRating;
  final int elo;
  final int lastChange;
  final int gamesNeededForRating;
  final int? peakTierId;
  final String? peakTierName;
  final String? peakSeason;

  bool get isPlacement => gamesNeededForRating > 0;
  bool get isRanked => tierId > 0;
}
