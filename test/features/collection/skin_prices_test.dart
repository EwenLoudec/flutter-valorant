import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_companion/features/collection/domain/skin_prices.dart';
import 'package:valorant_companion/features/encyclopedia/domain/weapon.dart';
import 'package:valorant_companion/features/profile/domain/featured_store.dart';

import '../../fixtures/henrik_fixtures.dart';

Weapon _weapon(String name, String category, List<WeaponSkinPreview> skins) => Weapon(
  uuid: name,
  displayName: name,
  category: category,
  displayIcon: null,
  cost: 0,
  fireRate: null,
  magazineSize: null,
  damageRanges: const [],
  skinPreviews: skins,
);

WeaponSkinPreview _skin(String uuid, String name, SkinEdition? edition) => WeaponSkinPreview(
  uuid: uuid,
  displayName: name,
  displayIcon: 'https://img/$uuid.png',
  contentTierUuid: edition?.tierUuid,
);

void main() {
  final weapons = [
    _weapon('Vandal', 'Rifle', [
      _skin('v1', 'Zèbre Vandal', SkinEdition.select),
      _skin('v2', 'Aube Vandal', SkinEdition.ultra),
      _skin('v3', 'Sans gamme Vandal', null),
    ]),
    _weapon('Phantom', 'Rifle', [_skin('skin-1', 'Champions Phantom', SkinEdition.exclusive)]),
    _weapon('Couteau', 'Melee', [
      _skin('k1', 'Lame Deluxe', SkinEdition.deluxe),
      _skin('k2', 'Lame Exclusive', SkinEdition.exclusive),
    ]),
  ];

  test('each edition has its usual price, a knife twice as much', () {
    final skins = {for (final skin in SkinPriceList.from(weapons).skins) skin.uuid: skin};

    expect(skins['v1']!.price, 875);
    expect(skins['v2']!.price, 2475);
    expect(skins['k1']!.price, 2550);
    expect(skins['k1']!.isMelee, isTrue);
    expect(skins['k2']!.price, 4350);
    expect(skins.containsKey('v3'), isFalse, reason: 'un skin sans gamme ne se vend pas en boutique');
  });

  test('Exclusive prices are a floor, unless the store gives the exact one', () {
    final inferred = {for (final skin in SkinPriceList.from(weapons).skins) skin.uuid: skin};
    expect(inferred['skin-1']!.price, 2175);
    expect(inferred['skin-1']!.isFloor, isTrue);
    expect(inferred['v2']!.isFloor, isFalse);

    final featured = FeaturedBundle.listFromJson(featuredStoreFixture());
    final skins = {for (final skin in SkinPriceList.from(weapons, featured: featured).skins) skin.uuid: skin};
    expect(skins['skin-1']!.price, 5350);
    expect(skins['skin-1']!.isExact, isTrue);
    expect(skins['skin-1']!.isFloor, isFalse);
    expect(skins['v1']!.isExact, isFalse);
  });

  test('sorted by name, searchable by skin or weapon', () {
    final skins = SkinPriceList.from(weapons).skins;

    expect(skins.map((skin) => skin.name), [
      'Aube Vandal',
      'Champions Phantom',
      'Lame Deluxe',
      'Lame Exclusive',
      'Zèbre Vandal',
    ]);
    expect(skins.where((skin) => skin.matches('couteau')), hasLength(2));
    expect(skins.where((skin) => skin.matches('aube')), hasLength(1));
  });

  test('weapons keep the uuid and edition of their paid skins', () {
    final weapon = Weapon.fromJson({
      'uuid': 'w',
      'displayName': 'Vandal',
      'category': 'EEquippableCategory::Rifle',
      'skins': [
        {'uuid': 'paid', 'displayName': 'Aube Vandal', 'displayIcon': 'https://img/a.png', 'contentTierUuid': SkinEdition.ultra.tierUuid},
        {'uuid': 'free', 'displayName': 'Vandal standard', 'displayIcon': 'https://img/s.png', 'contentTierUuid': null},
      ],
    });

    final skin = weapon.skinPreviews.single;
    expect(skin.uuid, 'paid');
    expect(skin.contentTierUuid, SkinEdition.ultra.tierUuid);
    expect(SkinPriceList.from([weapon]).skins.single.price, 2475);
  });

  test('a skin without a picture of its own takes the first level one', () {
    final weapon = Weapon.fromJson({
      'uuid': 'w',
      'displayName': 'Vandal',
      'skins': [
        {
          'uuid': 'lvl',
          'displayName': 'Vandal (Niveau)',
          'displayIcon': null,
          'contentTierUuid': SkinEdition.select.tierUuid,
          'levels': [{'displayIcon': 'https://img/level.png'}],
        },
        {
          'uuid': 'none',
          'displayName': 'Vandal (Sans image)',
          'displayIcon': null,
          'contentTierUuid': SkinEdition.select.tierUuid,
          'levels': <Object>[],
          'chromas': <Object>[],
        },
      ],
    });

    expect(weapon.skinPreviews.single.displayIcon, 'https://img/level.png');
  });

  test('editions are found by tier uuid, whatever its case', () {
    expect(SkinEdition.ofTier(SkinEdition.premium.tierUuid.toUpperCase()), SkinEdition.premium);
    expect(SkinEdition.ofTier(null), isNull);
    expect(SkinEdition.ofTier('inconnu'), isNull);
  });
}
