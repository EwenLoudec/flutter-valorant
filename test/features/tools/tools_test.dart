import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_companion/features/encyclopedia/domain/agent.dart';
import 'package:valorant_companion/features/encyclopedia/domain/map_composition.dart';
import 'package:valorant_companion/features/tools/domain/composition.dart';
import 'package:valorant_companion/features/tools/domain/crosshair.dart';
import 'package:valorant_companion/features/tools/domain/economy.dart';

Agent _agent(String name, String role) => Agent(
  uuid: name.toLowerCase(),
  displayName: name,
  description: '',
  roleName: role,
  displayIcon: null,
  fullPortrait: null,
  backgroundGradientColors: const [],
  abilities: const [],
);

void main() {
  group('EconomyPlan', () {
    test('computes what is left and the next round', () {
      const plan = EconomyPlan(credits: 4500, weaponCost: 2900, shieldCost: 1000, kills: 2);

      expect(plan.spent, 3900);
      expect(plan.remaining, 600);
      expect(plan.isAffordable, isTrue);
      expect(plan.nextIfWin, 600 + 3000 + 400);
      expect(plan.nextIfLoss, 600 + 1900 + 400);
    });

    test('grows the loss bonus with the streak', () {
      expect(EconomyRules.lossReward(1), 1900);
      expect(EconomyRules.lossReward(2), 2400);
      expect(EconomyRules.lossReward(3), 2900);
      expect(EconomyRules.lossReward(7), 2900);
      expect(const EconomyPlan(credits: 0, lossesBefore: 1).nextIfLoss, 2400);
      expect(const EconomyPlan(credits: 0, lossesBefore: 2).nextIfLoss, 2900);
    });

    test('caps the credits and counts the plant', () {
      const plan = EconomyPlan(credits: 9000, kills: 5, plantsSpike: true);
      expect(plan.nextIfWin, EconomyRules.maxCredits);
      expect(const EconomyPlan(credits: 0, plantsSpike: true).nextIfLoss, 1900 + 300);
    });

    test('flags an unaffordable buy without counting debt', () {
      const plan = EconomyPlan(credits: 1000, weaponCost: 2900);
      expect(plan.isAffordable, isFalse);
      expect(plan.remaining, -1900);
      expect(plan.nextIfWin, 3000);
    });

    test('tells how much can be spent while keeping a full buy', () {
      expect(const EconomyPlan(credits: 3000).maxSpendKeepingFullBuy, 1000);
      expect(const EconomyPlan(credits: 1000).maxSpendKeepingFullBuy, isNull);
      expect(const EconomyPlan(credits: 9000).maxSpendKeepingFullBuy, 7000);
    });
  });

  group('CompositionAnalysis', () {
    final omen = _agent('Omen', AgentRoles.controller);
    final jett = _agent('Jett', AgentRoles.duelist);
    final raze = _agent('Raze', AgentRoles.duelist);
    final reyna = _agent('Reyna', AgentRoles.duelist);
    final sova = _agent('Sova', AgentRoles.initiator);
    final killjoy = _agent('Killjoy', AgentRoles.sentinel);
    final kayo = _agent('KAY/O', AgentRoles.initiator);

    test('accepts a balanced line-up and compares it with the meta', () {
      const meta = MapComposition(
        winRatePercent: 55,
        agents: [
          CompositionAgent('Omen', AgentRoles.controller),
          CompositionAgent('Jett', AgentRoles.duelist),
          CompositionAgent('Sova', AgentRoles.initiator),
          CompositionAgent('Killjoy', AgentRoles.sentinel),
          CompositionAgent('Fade', AgentRoles.initiator),
        ],
      );
      final analysis = CompositionAnalysis.of([omen, jett, sova, killjoy, kayo], meta: meta);

      expect(analysis.isComplete, isTrue);
      expect(analysis.isBalanced, isTrue);
      expect(analysis.roleCounts[AgentRoles.initiator], 2);
      expect(analysis.metaMatches, 4);
      expect(analysis.metaSize, 5);
    });

    test('warns about missing roles and stacked duelists', () {
      final analysis = CompositionAnalysis.of([jett, raze, reyna, sova, kayo]);
      final messages = analysis.issues.map((issue) => issue.message).join(' ');

      expect(analysis.isBalanced, isFalse);
      expect(messages, contains('contrôleur'));
      expect(messages, contains('sentinelle'));
      expect(messages, contains('deux duellistes'));
    });

    test('says how many agents are still missing', () {
      final analysis = CompositionAnalysis.of([omen]);
      expect(analysis.isComplete, isFalse);
      expect(analysis.issues.first.message, contains('4 agents'));
      expect(CompositionAnalysis.of(const []).issues.single.level, CompositionIssueLevel.info);
    });
  });

  group('Crosshair', () {
    test('reads a typical code over the defaults', () {
      final crosshair = Crosshair.tryParse('0;P;c;1;h;0;0l;4;0o;2;0a;1;0f;0;1b;0')!;

      expect(crosshair.color, const Color(0xFF00FF00));
      expect(crosshair.hasOutlines, isFalse);
      expect(crosshair.inner.length, 4);
      expect(crosshair.inner.offset, 2);
      expect(crosshair.inner.opacity, 1);
      expect(crosshair.inner.thickness, Crosshair.defaults.inner.thickness);
      expect(crosshair.outer.isVisible, isFalse);
      expect(crosshair.hasCenterDot, isFalse);
    });

    test('keeps the defaults for a bare code', () {
      final crosshair = Crosshair.tryParse('0;P')!;
      expect(crosshair.color, Crosshair.defaults.color);
      expect(crosshair.outer.isVisible, isTrue);
      expect(crosshair.extent, greaterThan(10));
    });

    test('reads a custom color, a center dot and separate vertical lines', () {
      final crosshair = Crosshair.tryParse('0;P;c;8;u;FF8800FF;d;1;z;3;a;0.5;0g;1;0l;4;0v;7;0b;1')!;

      expect(crosshair.color, const Color(0xFFFF8800));
      expect(crosshair.hasCenterDot, isTrue);
      expect(crosshair.centerDotThickness, 3);
      expect(crosshair.centerDotOpacity, 0.5);
      expect(crosshair.inner.length, 4);
      expect(crosshair.inner.verticalLength, 7);
    });

    test('ignores the ADS and sniper sections', () {
      final crosshair = Crosshair.tryParse('0;P;c;7;A;c;1;0l;9;S;c;2')!;
      expect(crosshair.color, const Color(0xFFFF0000));
      expect(crosshair.inner.length, Crosshair.defaults.inner.length);
    });

    test('refuses what is not a code', () {
      expect(Crosshair.tryParse(''), isNull);
      expect(Crosshair.tryParse('bonjour'), isNull);
      expect(Crosshair.tryParse('1;P;c;1'), isNull);
      expect(Crosshair.tryParse('0'), isNull);
    });

    test('survives garbage values and a trailing key', () {
      final crosshair = Crosshair.tryParse('0;P;c;abc;0l;x;0a;5;h')!;
      expect(crosshair.color, Crosshair.defaults.color);
      expect(crosshair.inner.length, Crosshair.defaults.inner.length);
      expect(crosshair.inner.opacity, 1, reason: 'opacity is clamped');
    });

    test('round-trips a saved crosshair', () {
      const saved = SavedCrosshair(name: 'Mon réticule', code: '0;P;c;5');
      expect(SavedCrosshair.fromJson(saved.toJson())?.code, '0;P;c;5');
      expect(SavedCrosshair.fromJson('nope'), isNull);
      expect(SavedCrosshair.fromJson({'name': 1}), isNull);
    });
  });
}
