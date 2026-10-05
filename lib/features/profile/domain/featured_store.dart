import 'json_reading.dart';

int? _intOrNull(Object? value) => value == null ? null : asInt(value);

/// What a store item is, as the featured store names it.
enum StoreItemType {
  skin('Skin'),
  card('Carte'),
  spray('Graffiti'),
  buddy('Porte-bonheur'),
  title('Titre'),
  other('Objet');

  const StoreItemType(this.label);

  final String label;

  static StoreItemType fromCode(String? code) => switch (code) {
    'skin_level' || 'skin_chroma' || 'skin' => skin,
    'player_card' => card,
    'spray' => spray,
    'buddy' => buddy,
    'player_title' => title,
    _ => other,
  };
}

/// One item of a featured bundle, with its price alone and in the bundle.
class StoreItem {
  const StoreItem({
    required this.uuid,
    required this.name,
    required this.image,
    required this.type,
    required this.amount,
    required this.basePrice,
    required this.discountedPrice,
    required this.discountPercent,
  });

  static StoreItem? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final uuid = json['uuid'];
    if (uuid is! String || uuid.isEmpty) return null;
    final basePrice = _intOrNull(json['base_price']) ?? 0;
    final image = json['image'];

    return StoreItem(
      uuid: uuid,
      name: (json['name'] as String?)?.trim() ?? '',
      image: image is String && image.isNotEmpty ? image : null,
      type: StoreItemType.fromCode(json['type'] as String?),
      amount: _intOrNull(json['amount']) ?? 1,
      basePrice: basePrice,
      discountedPrice: _intOrNull(json['discounted_price']) ?? basePrice,
      discountPercent: (asDoubleOrNull(json['discount_percent']) ?? 0).clamp(0, 1).toDouble(),
    );
  }

  final String uuid;
  final String name;
  final String? image;
  final StoreItemType type;
  final int amount;

  /// In Valorant Points, bought alone.
  final int basePrice;

  /// In Valorant Points, as part of the bundle.
  final int discountedPrice;

  /// 0 to 1.
  final double discountPercent;

  bool get isDiscounted => discountedPrice < basePrice;
}

/// A bundle of the featured store: the same one for every player of the
/// game, unlike the daily offers, which only the player's own client sees.
class FeaturedBundle {
  const FeaturedBundle({
    required this.uuid,
    required this.price,
    required this.wholesaleOnly,
    required this.expiresAt,
    required this.items,
  });

  /// [now] dates the remaining time when the API only gives a countdown.
  static FeaturedBundle? fromJson(Object? json, {required DateTime now}) {
    if (json is! Map<String, dynamic>) return null;
    final uuid = json['bundle_uuid'];
    if (uuid is! String || uuid.isEmpty) return null;

    final expiresText = json['expires_at'];
    final seconds = _intOrNull(json['seconds_remaining']);
    final expiresAt = dateOf(expiresText) ?? (seconds == null ? null : now.add(Duration(seconds: seconds)));

    return FeaturedBundle(
      uuid: uuid,
      price: _intOrNull(json['bundle_price']) ?? 0,
      wholesaleOnly: json['whole_sale_only'] == true,
      expiresAt: expiresAt,
      items: [for (final item in json['items'] as List<dynamic>? ?? const []) ?StoreItem.fromJson(item)],
    );
  }

  static List<FeaturedBundle> listFromJson(Object? data, {DateTime? now}) {
    final moment = now ?? DateTime.now();
    final entries = data is List<dynamic> ? data : (data is Map<String, dynamic> ? [data] : const []);
    return [for (final entry in entries) ?FeaturedBundle.fromJson(entry, now: moment)];
  }

  final String uuid;

  /// In Valorant Points.
  final int price;

  /// Whether the items can only be bought together.
  final bool wholesaleOnly;
  final DateTime? expiresAt;
  final List<StoreItem> items;

  /// What the items would cost bought one by one.
  int get separatePrice => items.fold(0, (sum, item) => sum + item.basePrice);

  /// What the bundle saves, in Valorant Points; 0 when it saves nothing.
  int get savings => (separatePrice - price).clamp(0, separatePrice);

  Duration? remaining(DateTime now) {
    final expiresAt = this.expiresAt;
    if (expiresAt == null) return null;
    final left = expiresAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  static String formatRemaining(Duration left) {
    if (left.inDays >= 1) return '${left.inDays} j ${left.inHours % 24} h';
    if (left.inHours >= 1) return '${left.inHours} h ${left.inMinutes % 60} min';
    return '${left.inMinutes.clamp(0, 59)} min';
  }
}
