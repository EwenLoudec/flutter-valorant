import '../domain/featured_store.dart';
import '../domain/leaderboard.dart';
import '../domain/player_account.dart';
import '../domain/player_match.dart';
import '../domain/player_query.dart';
import '../domain/player_rank.dart';
import '../domain/rank_history.dart';
import '../domain/stored_match.dart';

abstract class PlayerRepository {
  Future<PlayerAccount> getAccount(RiotId riotId);
  Future<PlayerRank> getRank(PlayerQuery query);
  Future<List<PlayerMatch>> getMatches(PlayerQuery query, {required String puuid, int size});
  Future<List<RankHistoryEntry>> getRankHistory(PlayerQuery query);
  Future<Leaderboard> getLeaderboard(ValorantRegion region, {int size});

  /// The featured bundles of the store, the same for every player.
  Future<List<FeaturedBundle>> getFeaturedStore();

  /// The light history of the account's competitive games, newest first.
  Future<List<StoredMatch>> getStoredMatches(PlayerQuery query, {int size});
}
