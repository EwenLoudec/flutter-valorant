import '../../../core/network/henrik_api_client.dart';
import '../domain/leaderboard.dart';
import '../domain/player_account.dart';
import '../domain/player_match.dart';
import '../domain/player_query.dart';
import '../domain/player_rank.dart';
import '../domain/rank_history.dart';
import 'player_repository.dart';

class HenrikPlayerRepository implements PlayerRepository {
  HenrikPlayerRepository({required this.apiKey, HenrikApiClient? client})
    : _client = client ?? HenrikApiClient();

  /// The API only serves PC accounts for these endpoints; console has its own
  /// platform value, which the app does not expose yet.
  static const _platform = 'pc';

  /// The ladder holds thousands of players; the top of it is what the app
  /// shows, and searching beyond it is done by name.
  static const leaderboardSize = 200;

  final String apiKey;
  final HenrikApiClient _client;

  @override
  Future<PlayerAccount> getAccount(RiotId riotId) async {
    final data = await _client.getObject('/v2/account/${_escape(riotId.name)}/${_escape(riotId.tag)}', apiKey: apiKey);
    return PlayerAccount.fromJson(data);
  }

  @override
  Future<PlayerRank> getRank(PlayerQuery query) async {
    final riotId = query.riotId;
    final data = await _client.getObject(
      '/v3/mmr/${query.region.code}/$_platform/${_escape(riotId.name)}/${_escape(riotId.tag)}',
      apiKey: apiKey,
    );
    return PlayerRank.fromJson(data);
  }

  @override
  Future<List<PlayerMatch>> getMatches(PlayerQuery query, {required String puuid, int size = 10}) async {
    final riotId = query.riotId;
    final data = await _client.getList(
      '/v4/matches/${query.region.code}/$_platform/${_escape(riotId.name)}/${_escape(riotId.tag)}',
      apiKey: apiKey,
      query: {'size': '$size'},
    );

    return [
      for (final match in data) PlayerMatch.fromJson(match as Map<String, dynamic>, puuid: puuid),
    ];
  }

  @override
  Future<List<RankHistoryEntry>> getRankHistory(PlayerQuery query) async {
    final riotId = query.riotId;
    final data = await _client.getData(
      '/v2/mmr-history/${query.region.code}/$_platform/${_escape(riotId.name)}/${_escape(riotId.tag)}',
      apiKey: apiKey,
    );
    return RankHistoryEntry.listFromJson(data);
  }

  @override
  Future<Leaderboard> getLeaderboard(ValorantRegion region, {int size = leaderboardSize}) async {
    final data = await _client.getData(
      '/v3/leaderboard/${region.code}/$_platform',
      apiKey: apiKey,
      query: {'size': '$size'},
    );
    return Leaderboard.fromJson(data);
  }

  String _escape(String value) => Uri.encodeComponent(value);
}
