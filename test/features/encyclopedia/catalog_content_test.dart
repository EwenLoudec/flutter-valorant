import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_companion/features/collection/domain/reward_catalog.dart';
import 'package:valorant_companion/features/encyclopedia/domain/contract.dart';
import 'package:valorant_companion/features/encyclopedia/domain/cosmetic.dart';
import 'package:valorant_companion/features/encyclopedia/domain/game_map.dart';
import 'package:valorant_companion/features/encyclopedia/domain/store_content.dart';
import 'package:valorant_companion/features/encyclopedia/domain/weapon.dart';

void main() {
  group('Cosmetic.fromJson', () {
    test('reads each kind with the right picture', () {
      final card = Cosmetic.fromJson({
        'uuid': 'card',
        'displayName': 'Carte Duo fluo',
        'smallArt': 'small.png',
        'wideArt': 'wide.png',
      }, CosmeticKind.card)!;
      expect(card.imageUrl, 'small.png');
      expect(card.wideImageUrl, 'wide.png');

      final spray = Cosmetic.fromJson({
        'uuid': 'spray',
        'displayName': 'Graffiti',
        'displayIcon': 'icon.png',
        'fullTransparentIcon': 'transparent.png',
        'levels': [
          {'uuid': 'spray-level'},
        ],
      }, CosmeticKind.spray)!;
      expect(spray.imageUrl, 'transparent.png');
      expect(spray.levelUuids, ['spray-level']);

      final title = Cosmetic.fromJson({
        'uuid': 'title',
        'displayName': 'Titre Fortune',
        'titleText': 'Fortune',
      }, CosmeticKind.title)!;
      expect(title.titleText, 'Fortune');
      expect(title.matches('fort'), isTrue);
    });

    test('drops what the game never shows', () {
      expect(Cosmetic.fromJson({'uuid': 'x', 'displayName': 'Vide', 'isNullSpray': true}, CosmeticKind.spray), isNull);
      expect(Cosmetic.fromJson({'uuid': 'x', 'displayName': 'Titre', 'titleText': ' '}, CosmeticKind.title), isNull);
      expect(Cosmetic.fromJson({'displayName': 'Sans uuid'}, CosmeticKind.card), isNull);
      expect(Cosmetic.fromJson({'uuid': 'x', 'displayName': '  '}, CosmeticKind.card), isNull);
      expect(CosmeticKind.fromCode('buddy'), CosmeticKind.buddy);
      expect(CosmeticKind.fromCode('nope'), isNull);
    });
  });

  group('Contract', () {
    final json = {
      'uuid': 'contract',
      'displayName': 'Équipement de Sova',
      'content': {
        'relationType': 'Agent',
        'relationUuid': 'sova',
        'chapters': [
          {
            'levels': [
              {
                'reward': {'type': 'Spray', 'uuid': 'spray', 'amount': 1, 'isHighlighted': false},
                'xp': 1000,
              },
              {
                'reward': {'type': 'EquippableSkinLevel', 'uuid': 'skin-level', 'amount': 1, 'isHighlighted': true},
                'xp': 2000,
              },
            ],
            'freeRewards': [
              {'type': 'Currency', 'uuid': 'radianite', 'amount': 10},
            ],
          },
        ],
      },
    };

    test('reads levels, free rewards and the XP total', () {
      final contract = Contract.fromJson(json)!;
      expect(contract.kind, ContractKind.agent);
      expect(contract.relationUuid, 'sova');
      expect(contract.levelCount, 2);
      expect(contract.totalXp, 3000);
      expect(contract.rewards.first.level, 1);
      expect(contract.rewards[1].isHighlighted, isTrue);
      expect(contract.rewards.last.isFree, isTrue);
      expect(contract.rewards.last.amount, 10);
    });

    test('skips contracts it cannot place', () {
      expect(Contract.fromJson({'uuid': 'x', 'content': {'relationType': null}}), isNull);
      expect(Contract.fromJson({'uuid': 'x'}), isNull);
      expect(RewardType.fromCode('Totem'), RewardType.other);
    });

    test('names its rewards from the catalogues', () {
      final contract = Contract.fromJson(json)!;
      final catalog = RewardCatalog(
        sprays: [
          Cosmetic.fromJson({'uuid': 'spray', 'displayName': 'Graffiti Hibou', 'displayIcon': 'owl.png'}, CosmeticKind.spray)!,
        ],
        currencies: [Currency.fromJson({'uuid': 'radianite', 'displayName': 'Radianite', 'displayIcon': 'r.png'})],
        skinLevels: {
          'skin-level': SkinLevelInfo.fromJson({'uuid': 'skin-level', 'displayName': 'Arc Hibou', 'displayIcon': 'bow.png'}),
        },
      );

      expect(catalog.resolve(contract.rewards[0]).name, 'Graffiti Hibou');
      expect(catalog.resolve(contract.rewards[1]).imageUrl, 'bow.png');
      expect(catalog.resolve(contract.rewards[2]).name, '10 × Radianite');
      expect(RewardCatalog().resolve(contract.rewards[0]).name, 'Graffiti', reason: 'falls back on the type');
    });

    test('finds a buddy from one of its levels', () {
      final buddy = Cosmetic.fromJson({
        'uuid': 'buddy',
        'displayName': 'Porte-bonheur 809',
        'displayIcon': 'buddy.png',
        'levels': [
          {'uuid': 'buddy-level'},
        ],
      }, CosmeticKind.buddy)!;
      const reward = ContractReward(
        type: RewardType.buddyLevel,
        uuid: 'buddy-level',
        amount: 1,
        isHighlighted: false,
        isFree: false,
      );
      expect(RewardCatalog(buddies: [buddy]).resolve(reward).name, 'Porte-bonheur 809');
    });
  });

  group('Store content', () {
    test('reads gear prices and details', () {
      final gear = Gear.fromJson({
        'uuid': 'heavy',
        'displayName': 'Armure lourde',
        'description': 'Absorbe 66 % des dégâts.',
        'details': [
          {'name': 'DÉGÂTS ABSORBÉS', 'value': '66%'},
        ],
        'shopData': {'cost': 1000},
      });
      expect(gear.cost, 1000);
      expect(gear.details.single.value, '66%');
    });

    test('keeps only playable game modes', () {
      expect(GameMode.fromJson({'uuid': 'a', 'displayName': 'Standard', 'duration': '30-40 MIN'}).isPlayable, isTrue);
      expect(GameMode.fromJson({'uuid': 'b', 'displayName': 'Entraînement'}).isPlayable, isFalse);
    });

    test('weapons keep their paid skins only', () {
      final weapon = Weapon.fromJson({
        'uuid': 'vandal',
        'displayName': 'Vandal',
        'category': 'EEquippableCategory::Rifle',
        'skins': [
          {'displayName': 'Vandal standard', 'contentTierUuid': null, 'displayIcon': 'default.png'},
          {'displayName': 'Vandal Prime', 'contentTierUuid': 'premium', 'displayIcon': 'prime.png'},
          {'displayName': 'Vandal sans image', 'contentTierUuid': 'premium', 'displayIcon': null},
        ],
      });
      expect(weapon.skinPreviews.map((skin) => skin.displayName), ['Vandal Prime']);
    });
  });

  test('GameMap places game points like callouts', () {
    const map = GameMap(
      uuid: 'm',
      displayName: 'M',
      tacticalDescription: null,
      splash: null,
      displayIcon: null,
      xMultiplier: 0.0001,
      yMultiplier: -0.0001,
      xScalarToAdd: 0.5,
      yScalarToAdd: 0.5,
      callouts: [],
    );
    const callout = MapCallout(regionName: 'Site', superRegionName: 'A', gameX: 1000, gameY: 2000);

    expect(map.normalizedPoint(1000, 2000), map.normalizedPosition(callout));
    expect(map.canPlaceGamePoints, isTrue);
  });
}
