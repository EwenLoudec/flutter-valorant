import '../domain/leaderboard.dart';
import '../domain/player_account.dart';
import '../domain/player_match.dart';
import '../domain/player_query.dart';
import '../domain/player_rank.dart';
import '../domain/rank_history.dart';

abstract class PlayerRepository {
  Future<PlayerAccount> getAccount(RiotId riotId);
  Future<PlayerRank> getRank(PlayerQuery query);
  Future<List<PlayerMatch>> getMatches(PlayerQuery query, {required String puuid, int size});
  Future<List<RankHistoryEntry>> getRankHistory(PlayerQuery query);
  Future<Leaderboard> getLeaderboard(ValorantRegion region, {int size});
}
