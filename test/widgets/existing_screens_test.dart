import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valorant_companion/core/theme/app_theme.dart';
import 'package:valorant_companion/features/encyclopedia/domain/agent.dart';
import 'package:valorant_companion/features/encyclopedia/domain/content_tier.dart';
import 'package:valorant_companion/features/encyclopedia/domain/game_map.dart';
import 'package:valorant_companion/features/encyclopedia/domain/rank_tier.dart';
import 'package:valorant_companion/features/encyclopedia/domain/weapon.dart';
import 'package:valorant_companion/features/encyclopedia/domain/weapon_skin.dart';
import 'package:valorant_companion/features/encyclopedia/presentation/agents/agent_detail_screen.dart';
import 'package:valorant_companion/features/encyclopedia/presentation/maps/map_detail_screen.dart';
import 'package:valorant_companion/features/encyclopedia/presentation/weapons/weapon_detail_screen.dart';
import 'package:valorant_companion/features/encyclopedia/providers/encyclopedia_providers.dart';
import 'package:valorant_companion/features/lineups/presentation/lineup_editor_screen.dart';
import 'package:valorant_companion/features/lineups/data/lineup_sources.dart';
import 'package:valorant_companion/features/lineups/domain/lineup.dart';
import 'package:valorant_companion/features/lineups/providers/lineups_providers.dart';
import 'package:valorant_companion/features/lineups/presentation/map_lineups_screen.dart';
import 'package:valorant_companion/features/profile/presentation/owned_skins_picker_screen.dart';
import 'package:valorant_companion/features/profile/presentation/profile_page.dart';
import 'package:valorant_companion/features/training/domain/quiz_run.dart';
import 'package:valorant_companion/features/training/presentation/agent_quiz_page.dart';
import 'package:valorant_companion/features/training/presentation/map_quiz_page.dart';
import 'package:valorant_companion/features/training/providers/training_providers.dart';

/// The screens that existed before the latest features, opened at phone
/// width to make sure nothing they show broke or overflows.

const _sova = Agent(
  uuid: 'sova',
  displayName: 'Sova',
  description: 'Né dans la toundra glaciale de Russie, Sova traque, trouve et élimine ses ennemis.',
  roleName: 'Initiateur',
  displayIcon: null,
  fullPortrait: null,
  backgroundGradientColors: ['ff8800ff', '2244ffff'],
  abilities: [
    AgentAbility(slot: 'Ability1', displayName: 'Rafale de choc', description: 'Une flèche qui explose.'),
    AgentAbility(slot: 'Ability2', displayName: 'Flèche de reconnaissance', description: 'Révèle les ennemis.'),
    AgentAbility(slot: 'Grenade', displayName: 'Drone hibou', description: 'Un drone pilotable.'),
    AgentAbility(slot: 'Ultimate', displayName: 'Furie du chasseur', description: 'Trois rayons.'),
  ],
);

const _ascent = GameMap(
  uuid: 'ascent',
  displayName: 'Ascent',
  tacticalDescription: 'Sites A/B',
  splash: null,
  displayIcon: null,
  xMultiplier: 0.00007,
  yMultiplier: -0.00007,
  xScalarToAdd: 0.8,
  yScalarToAdd: 0.6,
  callouts: [
    MapCallout(regionName: 'Main', superRegionName: 'A', gameX: 3000, gameY: -2000),
    MapCallout(regionName: 'Site', superRegionName: 'A', gameX: 5000, gameY: -4000),
    MapCallout(regionName: 'Main', superRegionName: 'B', gameX: -3000, gameY: -2000),
    MapCallout(regionName: 'Site', superRegionName: 'B', gameX: -5000, gameY: -4000),
    MapCallout(regionName: 'Market', superRegionName: 'Mid', gameX: 0, gameY: -1000),
  ],
);

const _vandal = Weapon(
  uuid: 'vandal',
  displayName: 'Vandal',
  category: 'Rifle',
  displayIcon: null,
  cost: 2900,
  fireRate: 9.75,
  magazineSize: 25,
  damageRanges: [
    DamageRange(rangeStartMeters: 0, rangeEndMeters: 50, headDamage: 160, bodyDamage: 40, legDamage: 34),
  ],
);

final _overrides = [
  // The real bundled spots, read synchronously: the asset bundle decodes big
  // files on an isolate the fake test clock never waits for.
  bundledLineupsSourceProvider.overrideWithValue(_FileLineupsSource()),
  agentsProvider.overrideWith((ref) async => const [_sova]),
  mapsProvider.overrideWith((ref) async => const [_ascent]),
  weaponsProvider.overrideWith((ref) async => const [_vandal]),
  weaponSkinsProvider.overrideWith((ref, uuid) async => const <WeaponSkin>[]),
  contentTiersProvider.overrideWith((ref) async => const <String, ContentTier>{}),
  rankTiersProvider.overrideWith((ref) async => const <RankTier>[]),
  abilityVideosProvider.overrideWith((ref) async => const <String, Map<String, String>>{}),
  abilitySoundsProvider.overrideWith((ref) async => const <String, Map<String, String>>{}),
];

Future<ProviderContainer> _pump(WidgetTester tester, Widget child, {bool settle = true}) async {
  tester.view.physicalSize = const Size(375 * 3, 812 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides,
      child: MaterialApp(theme: AppTheme.theme, home: child),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('agent detail', (tester) async {
    await _pump(tester, const AgentDetailScreen(agent: _sova));
    expect(find.text('SOVA'), findsWidgets);
    expect(find.textContaining('RAFALE DE CHOC'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('weapon detail', (tester) async {
    await _pump(tester, const WeaponDetailScreen(weapon: _vandal));
    expect(find.text('VANDAL'), findsWidgets);
    expect(find.textContaining('160'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('map detail', (tester) async {
    await _pump(tester, const MapDetailScreen(map: _ascent));
    expect(find.text('ASCENT'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('map lineups list the bundled spots and open the editor', (tester) async {
    await _pump(tester, const MapLineupsScreen(mapName: 'Ascent'), settle: false);
    expect(find.textContaining('RECON A MAIN'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Ajouter un spot'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LineupEditorScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('map quiz page shows only map games in its history', (tester) async {
    final container = await _pump(tester, const MapQuizPage());
    await container.read(quizProgressProvider.notifier).record(
      QuizRun(kind: QuizKind.weapon, label: 'Armes', mode: 'mixed', score: 300, maxScore: 1000, playedAt: DateTime(2026)),
    );
    await container.read(quizProgressProvider.notifier).record(
      QuizRun(kind: QuizKind.map, label: 'Ascent', mode: 'focus', score: 480, maxScore: 600, playedAt: DateTime(2026)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('480 / 600'), 300);
    expect(find.text('480 / 600'), findsOneWidget);
    expect(find.text('300 / 1000'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('agent quiz page still starts a run', (tester) async {
    await _pump(tester, const AgentQuizPage());
    expect(find.text('LANCER UNE PARTIE'), findsNothing, reason: 'one agent is not enough for a run');
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile setup and skin picker', (tester) async {
    await _pump(tester, const ProfilePage());
    expect(find.text('RETROUVEZ VOTRE COMPTE'), findsOneWidget);
    expect(find.text('AFFICHER MON PROFIL'), findsOneWidget);

    await _pump(tester, const OwnedSkinsPickerScreen());
    expect(tester.takeException(), isNull);
  });
}

class _FileLineupsSource extends BundledLineupsSource {
  @override
  Future<List<Lineup>> load() async {
    final decoded = jsonDecode(File(BundledLineupsSource.assetPath).readAsStringSync()) as Map<String, dynamic>;
    return [
      for (final entry in decoded['lineups'] as List<dynamic>)
        Lineup.fromJson(entry as Map<String, dynamic>, isBundled: true),
    ];
  }
}
