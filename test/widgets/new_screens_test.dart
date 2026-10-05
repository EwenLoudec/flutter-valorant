
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valorant_companion/core/theme/app_theme.dart';
import 'package:valorant_companion/features/collection/presentation/contracts_screen.dart';
import 'package:valorant_companion/features/collection/presentation/cosmetics_screen.dart';
import 'package:valorant_companion/features/encyclopedia/domain/agent.dart';
import 'package:valorant_companion/features/encyclopedia/domain/contract.dart';
import 'package:valorant_companion/features/encyclopedia/domain/cosmetic.dart';
import 'package:valorant_companion/features/encyclopedia/domain/game_map.dart';
import 'package:valorant_companion/features/encyclopedia/domain/rank_tier.dart';
import 'package:valorant_companion/features/encyclopedia/domain/store_content.dart';
import 'package:valorant_companion/features/encyclopedia/domain/weapon.dart';
import 'package:valorant_companion/features/encyclopedia/presentation/ranks/radiant_leaderboard_screen.dart';
import 'package:valorant_companion/features/encyclopedia/providers/encyclopedia_providers.dart';
import 'package:valorant_companion/features/profile/data/player_repository.dart';
import 'package:valorant_companion/features/profile/domain/leaderboard.dart';
import 'package:valorant_companion/features/profile/domain/player_account.dart';
import 'package:valorant_companion/features/profile/domain/player_match.dart';
import 'package:valorant_companion/features/profile/domain/player_query.dart';
import 'package:valorant_companion/features/profile/domain/player_rank.dart';
import 'package:valorant_companion/features/profile/domain/rank_history.dart';
import 'package:valorant_companion/features/profile/presentation/match_detail_screen.dart';
import 'package:valorant_companion/features/profile/presentation/player_stats_section.dart';
import 'package:valorant_companion/features/profile/presentation/rank_history_section.dart';
import 'package:valorant_companion/features/profile/providers/profile_providers.dart';
import 'package:valorant_companion/features/tools/presentation/composition_builder_screen.dart';
import 'package:valorant_companion/features/tools/presentation/crosshair_screen.dart';
import 'package:valorant_companion/features/tools/presentation/economy_screen.dart';

import '../fixtures/henrik_fixtures.dart';

class _FakeRepository implements PlayerRepository {
  @override
  Future<PlayerAccount> getAccount(RiotId riotId) async =>
      PlayerAccount.fromJson({'puuid': fixturePuuid, 'name': riotId.name, 'tag': riotId.tag});

  @override
  Future<PlayerRank> getRank(PlayerQuery query) async => PlayerRank.fromJson(const {});

  @override
  Future<List<PlayerMatch>> getMatches(PlayerQuery query, {required String puuid, int size = 10}) async => [
    PlayerMatch.fromJson(v4CompetitiveMatch(), puuid: puuid),
  ];

  @override
  Future<List<RankHistoryEntry>> getRankHistory(PlayerQuery query) async => RankHistoryEntry.listFromJson({
    'history': [
      for (var index = 0; index < 8; index++)
        {
          'match_id': index == 0 ? 'match-1' : 'm$index',
          'tier': {'id': 15, 'name': 'Platinum 1'},
          'map': {'name': 'Ascent'},
          'rr': 40 + index,
          'last_change': index.isEven ? 18 : -14,
          'elo': 1240 + index * 6,
          'date': DateTime(2026, 10, 1 + index).toIso8601String(),
        },
    ],
  });

  @override
  Future<Leaderboard> getLeaderboard(ValorantRegion region, {int size = 200}) async => Leaderboard.fromJson({
    'players': [
      for (var index = 1; index <= 30; index++)
        {
          'leaderboard_rank': index,
          'name': index == 3 ? 'Moi' : 'Joueur très très long numéro $index',
          'tag': index == 3 ? 'EUW' : 'TAG$index',
          'tier': 27,
          'rr': 1200 - index,
          'wins': 300 - index,
          'is_anonymized': index == 5,
        },
    ],
  });
}

Agent _agent(String name, String role) => Agent(
  uuid: name,
  displayName: name,
  description: '',
  roleName: role,
  displayIcon: null,
  fullPortrait: null,
  backgroundGradientColors: const [],
  abilities: const [],
);

final _agents = [
  _agent('Omen', 'Contrôleur'),
  _agent('Jett', 'Duelliste'),
  _agent('Sova', 'Initiateur'),
  _agent('Killjoy', 'Sentinelle'),
  _agent('KAY/O', 'Initiateur'),
  _agent('Raze', 'Duelliste'),
];

const _maps = [
  GameMap(
    uuid: 'MAP-UUID',
    displayName: 'Ascent',
    tacticalDescription: 'A/B',
    splash: null,
    displayIcon: null,
    xMultiplier: 0.00007,
    yMultiplier: -0.00007,
    xScalarToAdd: 0.8,
    yScalarToAdd: 0.6,
    callouts: [],
  ),
];

final _overrides = [
  playerRepositoryProvider.overrideWithValue(_FakeRepository()),
  agentsProvider.overrideWith((ref) async => _agents),
  mapsProvider.overrideWith((ref) async => _maps),
  rankTiersProvider.overrideWith((ref) async => const <RankTier>[]),
  weaponsProvider.overrideWith(
    (ref) async => const [
      Weapon(
        uuid: 'vandal',
        displayName: 'Vandal',
        category: 'Rifle',
        displayIcon: null,
        cost: 2900,
        fireRate: 9.75,
        magazineSize: 25,
        damageRanges: [],
      ),
      Weapon(
        uuid: 'operator',
        displayName: 'Operator',
        category: 'Sniper',
        displayIcon: null,
        cost: 4700,
        fireRate: 0.75,
        magazineSize: 5,
        damageRanges: [],
      ),
    ],
  ),
  gearProvider.overrideWith(
    (ref) async => [
      Gear.fromJson({
        'uuid': 'heavy',
        'displayName': 'Armure lourde',
        'description': 'Absorbe 66 % des dégâts subis.',
        'shopData': {'cost': 1000},
      }),
    ],
  ),
  cosmeticsProvider.overrideWith(
    (ref, kind) async => [
      for (var index = 0; index < 12; index++)
        Cosmetic(
          uuid: '${kind.name}-$index',
          kind: kind,
          displayName: 'Élément ${kind.label} numéro $index au nom assez long',
          imageUrl: null,
          titleText: kind == CosmeticKind.title ? 'Titre $index' : null,
        ),
    ],
  ),
  contractsProvider.overrideWith(
    (ref) async => [
      Contract.fromJson({
        'uuid': 'c1',
        'displayName': 'Équipement de Sova',
        'content': {
          'relationType': 'Agent',
          'relationUuid': 'Sova',
          'chapters': [
            {
              'levels': [
                {
                  'reward': {'type': 'Spray', 'uuid': 's'},
                  'xp': 2000,
                },
              ],
            },
          ],
        },
      })!,
    ],
  ),
  seasonStartsProvider.overrideWith((ref) async => const <String, DateTime>{}),
  currenciesProvider.overrideWith((ref) async => const <Currency>[]),
  skinLevelsProvider.overrideWith((ref) async => const <String, SkinLevelInfo>{}),
];

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(375 * 3, 812 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides,
      child: MaterialApp(theme: AppTheme.theme, home: child),
    ),
  );
  await tester.pumpAndSettle();
}

const _query = PlayerQuery(riotId: RiotId(name: 'Moi', tag: 'EUW'), region: ValorantRegion.eu);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'profile.api_key': 'HDEV-test',
      'profile.region': 'eu',
      'profile.riot_id': 'Moi#EUW',
    });
  });

  testWidgets('match detail shows the scoreboard, rounds and economy', (tester) async {
    final match = PlayerMatch.fromJson(v4CompetitiveMatch(), puuid: fixturePuuid);
    await _pump(tester, MatchDetailScreen(match: match, puuid: fixturePuuid));

    expect(find.text('TON ÉQUIPE'), findsOneWidget);
    expect(find.text('ADVERSAIRES'), findsOneWidget);
    expect(find.text('VICTOIRE'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('ÉCONOMIE'), 300);
    expect(find.text('MANCHES'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaderboard lists the players and filters them', (tester) async {
    await _pump(tester, const RadiantLeaderboardScreen());

    expect(find.text('#1'), findsOneWidget);
    expect(find.text('Joueur anonyme'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'moi');
    await tester.pumpAndSettle();
    expect(find.text('Moi#EUW'), findsOneWidget);
    expect(find.text('#1'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaderboard asks for the key, then shows the ladder', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _pump(tester, const RadiantLeaderboardScreen());

    expect(find.text('UNE CLÉ API EST NÉCESSAIRE'), findsOneWidget);
    expect(find.text('OBTENIR UNE CLÉ GRATUITE'), findsOneWidget);
    await tester.tap(find.text('AFFICHER LE CLASSEMENT'));
    await tester.pumpAndSettle();
    expect(find.textContaining('HDEV-'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'HDEV-test-key');
    await tester.tap(find.text('AFFICHER LE CLASSEMENT'));
    await tester.pumpAndSettle();
    expect(find.text('#1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile stats sections render from the match history', (tester) async {
    await _pump(
      tester,
      Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            RankHistorySection(query: _query),
            SessionSection(query: _query),
            PlayerStatsSection(query: _query),
          ],
        ),
      ),
    );

    expect(find.text('ÉVOLUTION DU RR'), findsOneWidget);
    expect(find.text('MES AGENTS'), findsOneWidget);
    expect(find.text('ATTAQUE'), findsOneWidget);
    expect(find.textContaining('Bilan sur 8 parties'), findsOneWidget);

    await tester.tapAt(tester.getCenter(find.byType(RankHistoryChart)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bilan sur'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('economy screen computes the next round', (tester) async {
    await _pump(tester, const EconomyScreen());

    await tester.tap(find.text('3900'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vandal · 2900'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.textContaining('Achat possible'), 300);
    expect(find.textContaining('1000 ¤ restants'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('composition builder analyses the picked agents', (tester) async {
    await _pump(tester, const CompositionBuilderScreen(initialMapName: 'Ascent'));

    for (final name in ['Omen', 'Jett', 'Sova', 'Killjoy', 'KAY/O']) {
      await tester.scrollUntilVisible(find.text(name).last, 200);
      await tester.tap(find.text(name).last);
      await tester.pumpAndSettle();
    }
    await tester.scrollUntilVisible(find.textContaining('équilibrée'), -200);
    expect(find.textContaining('équilibrée'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('crosshair screen previews and saves a code', (tester) async {
    await _pump(tester, const CrosshairScreen());

    expect(find.byType(CustomPaint), findsWidgets);
    await tester.enterText(find.byType(TextField).first, 'pas un code');
    await tester.pumpAndSettle();
    expect(find.textContaining('Ce n\'est pas un code'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '0;P;c;5;d;1');
    await tester.pumpAndSettle();
    await tester.tap(find.text('ENREGISTRER'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Mon point');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Mon point'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('collection ticks a cosmetic as owned', (tester) async {
    await _pump(tester, const CosmeticsScreen());

    expect(find.textContaining('Possédés (0)'), findsOneWidget);
    await tester.tap(find.textContaining('numéro 0').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Possédés (1)'), findsOneWidget);

    await tester.ensureVisible(find.text('TITRES'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TITRES'));
    await tester.pumpAndSettle();
    expect(find.text('Titre 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('contracts list opens a contract', (tester) async {
    await _pump(tester, const ContractsScreen());

    await tester.tap(find.text('ÉQUIPEMENT DE SOVA'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 niveau ·'), findsOneWidget);
    expect(find.text('Graffiti'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
