import '../../../core/text/search_text.dart';
import '../../encyclopedia/domain/weapon.dart';
import '../../profile/domain/featured_store.dart';

/// The editions a paid skin comes in, cheapest first. The gun prices are the
/// usual ones; Exclusive skins often cost more.
enum SkinEdition {
  select('Select', '12683d76-48d7-84a3-4e09-6985794f0445', 875),
  deluxe('Deluxe', '0cebb8be-46d7-c12a-d306-e9907bfc5a25', 1275),
  premium('Premium', '60bca009-4182-7998-dee7-b8a2558dc369', 1775),
  exclusive('Exclusive', 'e046854e-406c-37f4-6607-19a9ba8426fc', 2175),
  ultra('Ultra', '411e4a55-4e59-7757-41f0-86a53f101bb5', 2475);

  const SkinEdition(this.label, this.tierUuid, this.gunPrice);

  final String label;

  /// The content tier uuid of valorant-api.com.
  final String tierUuid;

  /// The usual price of a gun skin of this edition, in Valorant Points.
  /// Melee skins cost twice as much.
  final int gunPrice;

  static SkinEdition? ofTier(String? tierUuid) {
    for (final edition in values) {
      if (edition.tierUuid == tierUuid?.toLowerCase()) return edition;
    }
    return null;
  }
}

/// One skin of the price list.
class SkinPrice {
  const SkinPrice({
    required this.uuid,
    required this.name,
    required this.weaponName,
    required this.isMelee,
    required this.icon,
    required this.edition,
    required this.price,
    required this.isExact,
  });

  final String? uuid;
  final String name;
  final String weaponName;
  final bool isMelee;
  final String icon;
  final SkinEdition edition;

  /// In Valorant Points.
  final int price;

  /// Whether the price was read on the store today, rather than inferred from
  /// the edition.
  final bool isExact;

  /// Exclusive skins cost 2,175 VP or more (Champions ones 2,675): unless the
  /// store gave it, their price is a floor.
  bool get isFloor => !isExact && edition == SkinEdition.exclusive;

  bool matches(String search) => matchesSearch(search, [name, weaponName, edition.label]);
}

/// Every paid skin with its price. Riot no longer publishes the store's
/// prices, but they follow the edition: 875 VP for a Select gun skin up to
/// 2,475 for an Ultra one, twice that for a knife. The skins on sale today in
/// the featured store carry their exact price instead, which catches the
/// exceptions (Champions skins, collaborations).
class SkinPriceList {
  const SkinPriceList._(this.skins);

  factory SkinPriceList.from(List<Weapon> weapons, {List<FeaturedBundle> featured = const []}) {
    final exact = <String, int>{
      for (final bundle in featured)
        for (final item in bundle.items)
          if (item.type == StoreItemType.skin && item.basePrice > 0) item.uuid.toLowerCase(): item.basePrice,
    };

    final skins = <SkinPrice>[];
    for (final weapon in weapons) {
      final isMelee = weapon.category == 'Melee';
      for (final skin in weapon.skinPreviews) {
        final edition = SkinEdition.ofTier(skin.contentTierUuid);
        if (edition == null) continue;
        final known = exact[skin.uuid?.toLowerCase()];
        skins.add(
          SkinPrice(
            uuid: skin.uuid,
            name: skin.displayName,
            weaponName: weapon.displayName,
            isMelee: isMelee,
            icon: skin.displayIcon,
            edition: edition,
            price: known ?? edition.gunPrice * (isMelee ? 2 : 1),
            isExact: known != null,
          ),
        );
      }
    }
    skins.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return SkinPriceList._(skins);
  }

  /// Sorted by name.
  final List<SkinPrice> skins;
}
