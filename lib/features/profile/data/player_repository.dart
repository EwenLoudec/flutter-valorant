import '../domain/player_account.dart';
import '../domain/player_match.dart';
import '../domain/player_query.dart';
import '../domain/player_rank.dart';

abstract class PlayerRepository {
  Future<PlayerAccount> getAccount(RiotId riotId);
  Future<PlayerRank> getRank(PlayerQuery query);
  Future<List<PlayerMatch>> getMatches(PlayerQuery query, {required String puuid, int size});
}
