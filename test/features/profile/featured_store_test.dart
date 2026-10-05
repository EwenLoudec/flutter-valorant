import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_companion/features/profile/domain/featured_store.dart';
import 'package:valorant_companion/features/profile/domain/player_account.dart';
import 'package:valorant_companion/features/profile/presentation/rank_theme.dart';

import '../../fixtures/henrik_fixtures.dart';

void main() {
  group('featured store', () {
    final now = DateTime.utc(2099, 10, 5, 12);
    final bundles = FeaturedBundle.listFromJson(featuredStoreFixture(), now: now);

    test('reads the bundles and skips the broken entries', () {
      expect(bundles, hasLength(1));
      final bundle = bundles.single;
      expect(bundle.uuid, 'bundle-1');
      expect(bundle.price, 4615);
      expect(bundle.items.map((item) => item.uuid), ['skin-1', 'card-1', 'buddy-1']);
    });

    test('types, prices and discounts of the items', () {
      final [skin, card, buddy] = bundles.single.items;
      expect(skin.type, StoreItemType.skin);
      expect(skin.isDiscounted, isTrue);
      expect(skin.discountedPrice, 3531);
      expect(card.type, StoreItemType.card);
      expect(buddy.type, StoreItemType.buddy);
      expect(buddy.amount, 2);
      expect(buddy.image, isNull);
      expect(buddy.isDiscounted, isFalse);
    });

    test('the bundle saves the difference with the separate prices', () {
      final bundle = bundles.single;
      expect(bundle.separatePrice, 5350 + 375 + 475);
      expect(bundle.savings, 6200 - 4615);
    });

    test('the remaining time comes from the end date, or the countdown', () {
      final bundle = bundles.single;
      expect(bundle.remaining(DateTime.utc(2099, 10, 21, 5, 1, 27)), Duration.zero);
      expect(bundle.remaining(DateTime.utc(2099, 10, 20, 3))!.inHours, 26);

      final countdownOnly = FeaturedBundle.listFromJson([
        {'bundle_uuid': 'b', 'seconds_remaining': 7200, 'items': <Object>[]},
      ], now: now).single;
      expect(countdownOnly.remaining(now), const Duration(hours: 2));
      expect(countdownOnly.savings, 0);
    });

    test('remaining times read in French', () {
      expect(FeaturedBundle.formatRemaining(const Duration(days: 15, hours: 16)), '15 j 16 h');
      expect(FeaturedBundle.formatRemaining(const Duration(hours: 3, minutes: 5)), '3 h 5 min');
      expect(FeaturedBundle.formatRemaining(const Duration(minutes: 42)), '42 min');
    });

    test('a store payload of another shape reads as empty', () {
      expect(FeaturedBundle.listFromJson(null), isEmpty);
      expect(FeaturedBundle.listFromJson('oops'), isEmpty);
    });
  });

  group('account', () {
    test('v2 sends the card and the title as uuids', () {
      final account = PlayerAccount.fromJson(const {
        'puuid': 'p',
        'name': 'Moi',
        'tag': 'EUW',
        'account_level': 120,
        'card': 'card-uuid',
        'title': 'title-uuid',
      });
      expect(account.cardSmall, 'https://media.valorant-api.com/playercards/card-uuid/smallart.png');
      expect(account.cardWide, 'https://media.valorant-api.com/playercards/card-uuid/wideart.png');
      expect(account.title, 'title-uuid');
    });

    test('v1 sends the card pictures', () {
      final account = PlayerAccount.fromJson(const {
        'card': {'small': 'https://img/small.png', 'wide': 'https://img/wide.png', 'id': 'c'},
      });
      expect(account.cardSmall, 'https://img/small.png');
      expect(account.cardWide, 'https://img/wide.png');
      expect(account.title, isNull);
    });
  });

  group('rank themes', () {
    test('each family of three tiers has its own colours', () {
      expect(RankTheme.ofTier(null).family, RankFamily.unranked);
      expect(RankTheme.ofTier(0).family, RankFamily.unranked);
      expect(RankTheme.ofTier(3).family, RankFamily.iron);
      expect(RankTheme.ofTier(5).family, RankFamily.iron);
      expect(RankTheme.ofTier(6).family, RankFamily.bronze);
      expect(RankTheme.ofTier(15).family, RankFamily.platinum);
      expect(RankTheme.ofTier(21).family, RankFamily.ascendant);
      expect(RankTheme.ofTier(24).family, RankFamily.immortal);
      expect(RankTheme.ofTier(26).family, RankFamily.immortal);
      expect(RankTheme.ofTier(27).family, RankFamily.radiant);
    });

    test('Immortal burns red, and higher ranks burn brighter', () {
      final immortal = RankTheme.ofTier(25);
      expect(immortal.main.r, greaterThan(immortal.main.g + 0.4));
      expect(RankTheme.ofTier(27).energy, greaterThan(immortal.energy));
      expect(immortal.energy, greaterThan(RankTheme.ofTier(4).energy));
    });
  });
}
