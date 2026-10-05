import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valorant_companion/core/theme/app_theme.dart';
import 'package:valorant_companion/features/encyclopedia/domain/agent.dart';
import 'package:valorant_companion/features/encyclopedia/domain/competitive_season.dart';
import 'package:valorant_companion/features/encyclopedia/domain/game_map.dart';
import 'package:valorant_companion/features/encyclopedia/domain/rank_tier.dart';
import 'package:valorant_companion/features/encyclopedia/domain/weapon.dart';
import 'package:valorant_companion/features/encyclopedia/presentation/agents/agents_page.dart';
import 'package:valorant_companion/features/encyclopedia/presentation/maps/maps_page.dart';
import 'package:valorant_companion/features/encyclopedia/presentation/ranks/ranks_page.dart';
import 'package:valorant_companion/features/encyclopedia/presentation/weapons/weapons_page.dart';
import 'package:valorant_companion/features/encyclopedia/providers/encyclopedia_providers.dart';
import 'package:valorant_companion/features/lineups/presentation/lineups_page.dart';
import 'package:valorant_companion/features/profile/data/player_repository.dart';
import 'package:valorant_companion/features/profile/domain/leaderboard.dart';
import 'package:valorant_companion/features/profile/domain/player_account.dart';
import 'package:valorant_companion/features/profile/domain/player_match.dart';
import 'package:valorant_companion/features/profile/domain/player_query.dart';
import 'package:valorant_companion/features/profile/domain/player_rank.dart';
import 'package:valorant_companion/features/profile/domain/rank_history.dart';
import 'package:valorant_companion/features/profile/presentation/match_detail_screen.dart';
import 'package:valorant_companion/features/profile/presentation/match_history_section.dart';
import 'package:valorant_companion/features/profile/presentation/profile_page.dart';
import 'package:valorant_companion/features/profile/providers/profile_providers.dart';
import 'package:valorant_companion/features/training/presentation/catalog_quiz_pages.dart';
import 'package:valorant_companion/features/training/providers/training_providers.dart';

import '../fixtures/henrik_fixtures.dart';

class _FakeRepository implements PlayerRepository {
  @override
  Future<PlayerAccount> getAccount(RiotId riotId) async =>
      PlayerAccount.fromJson({'puuid': fixturePuuid, 'name': riotId.name, 'tag': riotId.tag, 'account_level': 120});

  @override
  Future<PlayerRank> getRank(PlayerQuery query) async => PlayerRank.fromJson(const {
    'current': {
      'tier': {'id': 15, 'name': 'Platinum 1'},
      'rr': 42,
      'last_change': 18,
      'elo': 1242,
    },
  });

  @override
  Future<List<PlayerMatch>> getMatches(PlayerQuery query, {required String puuid, int size = 10}) async => [
    PlayerMatch.fromJson(v4CompetitiveMatch(), puuid: puuid),
  ];

  @override
  Future<List<RankHistoryEntry>> getRankHistory(PlayerQuery query) async => const [];

  @override
  Future<Leaderboard> getLeaderboard(ValorantRegion region, {int size = 200}) async => Leaderboard.fromJson(const {});
}

Agent _agent(String name, String role) => Agent(
  uuid: name,
  displayName: name,
  description: '',
  roleName: role,
  displayIcon: 'https://img/$name.png',
  fullPortrait: null,
  backgroundGradientColors: const [],
  abilities: [
    for (final slot in ['Ability1', 'Ability2', 'Grenade', 'Ultimate'])
      AgentAbility(
        slot: slot,
        displayName: '$name $slot',
        description: 'Une description suffisamment longue pour une question, slot $slot.',
        displayIcon: 'https://img/$name-$slot.png',
      ),
  ],
);

Weapon _weapon(String name, int cost) => Weapon(
  uuid: name,
  displayName: name,
  category: 'Rifle',
  displayIcon: 'https://img/$name.png',
  cost: cost,
  fireRate: null,
  magazineSize: null,
  damageRanges: const [],
  skinPreviews: [WeaponSkinPreview(displayName: '$name Prime', displayIcon: 'https://img/$name-prime.png')],
);

final _overrides = [
  playerRepositoryProvider.overrideWithValue(_FakeRepository()),
  agentsProvider.overrideWith(
    (ref) async => [
      for (final (name, role) in [
        ('Omen', 'Contrôleur'),
        ('Jett', 'Duelliste'),
        ('Sova', 'Initiateur'),
        ('Killjoy', 'Sentinelle'),
        ('Raze', 'Duelliste'),
      ])
        _agent(name, role),
    ],
  ),
  weaponsProvider.overrideWith(
    (ref) async => [for (final (index, name) in ['Classic', 'Sheriff', 'Spectre', 'Vandal', 'Phantom'].indexed) _weapon(name, index * 700)],
  ),
  mapsProvider.overrideWith(
    (ref) async => const [
      GameMap(
        uuid: 'ascent',
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
    ],
  ),
  rankTiersProvider.overrideWith(
    (ref) async => [
      for (final (index, name) in ['FER 1', 'FER 2', 'BRONZE 1', 'ARGENT 1', 'OR 1', 'RADIANT'].indexed)
        RankTier(
          tier: index + 3,
          tierName: name,
          divisionName: index == 5 ? 'RADIANT' : name.split(' ').first,
          color: Colors.white,
          backgroundColor: Colors.black,
          largeIcon: null,
        ),
    ],
  ),
  currentSeasonProvider.overrideWith((ref) async => const CompetitiveSeason(episodeName: 'V26', actName: 'ACTE V')),
  abilitySoundsProvider.overrideWith((ref) async => const <String, Map<String, String>>{}),
  abilityVideosProvider.overrideWith((ref) async => const <String, Map<String, String>>{}),
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

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the tabs show their new entries without overflowing', (tester) async {
    await _pump(tester, const AgentsPage());
    expect(find.text('DÉFI DU JOUR'), findsOneWidget);

    await _pump(tester, const WeaponsPage());
    expect(find.text('ÉCONOMIE'), findsOneWidget);
    expect(find.text('QUIZ ARMES'), findsOneWidget);

    await _pump(tester, const MapsPage());
    expect(find.text('COMPOSITION'), findsOneWidget);
    expect(find.text('MODES DE JEU'), findsOneWidget);

    await _pump(tester, const RanksPage());
    expect(find.text('QUIZ RANGS'), findsOneWidget);
    expect(find.text('CLASSEMENT'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a weapon quiz can be played to the end and is recorded', (tester) async {
    await _pump(tester, const WeaponQuizPage());

    await tester.tap(find.text('LANCER UNE PARTIE'));
    await tester.pumpAndSettle();

    for (var question = 0; question < 10; question++) {
      final choices = find.byWidgetPredicate(
        (widget) => widget is Text && ['CLASSIC', 'SHERIFF', 'SPECTRE', 'VANDAL', 'PHANTOM'].contains(widget.data),
      );
      if (choices.evaluate().isEmpty) break;
      await tester.tap(choices.first);
      await tester.pumpAndSettle();
      final next = find.textContaining(RegExp('QUESTION SUIVANTE|VOIR LE RÉSULTAT'));
      await tester.scrollUntilVisible(next, 200);
      await tester.tap(next);
      await tester.pumpAndSettle();
    }

    expect(find.text('RÉSULTAT'), findsOneWidget);
    final container = ProviderScope.containerOf(tester.element(find.text('RÉSULTAT')));
    expect(container.read(quizProgressProvider).value?.history.first.label, 'Armes');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the daily challenge is locked once played', (tester) async {
    await _pump(tester, const DailyChallengePage());
    expect(find.text('LANCER UNE PARTIE'), findsOneWidget);

    final container = ProviderScope.containerOf(tester.element(find.text('LANCER UNE PARTIE')));
    await container.read(dailyStreakProvider.notifier).complete(DateTime.now(), 700);
    await tester.pumpAndSettle();

    expect(find.text('DÉFI DÉJÀ JOUÉ AUJOURD\'HUI'), findsOneWidget);
    expect(find.textContaining('Série : 1 jour'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the lineups page searches every spot', (tester) async {
    await _pump(tester, const LineupsPage());
    expect(find.text('MES SPOTS'), findsOneWidget);
    expect(find.text('QUIZ LINEUPS'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzzz introuvable');
    await tester.pumpAndSettle();
    expect(find.textContaining('Aucun spot ne correspond'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the profile shows every section and opens a match', (tester) async {
    SharedPreferences.setMockInitialValues({
      'profile.api_key': 'HDEV-test',
      'profile.region': 'eu',
      'profile.riot_id': 'Moi#EUW',
    });
    await _pump(tester, const ProfilePage());

    for (final title in ['RANG COMPÉTITIF', 'ÉVOLUTION DU RR', 'DERNIÈRE SESSION', 'HISTORIQUE', 'COLLECTION ET OUTILS']) {
      await tester.scrollUntilVisible(find.text(title), 300);
      expect(find.text(title), findsOneWidget);
    }

    final matchTile = find.descendant(of: find.byType(MatchHistorySection), matching: find.text('ASCENT'));
    await tester.scrollUntilVisible(matchTile, -300);
    await tester.tap(matchTile);
    await tester.pumpAndSettle();
    expect(find.byType(MatchDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
