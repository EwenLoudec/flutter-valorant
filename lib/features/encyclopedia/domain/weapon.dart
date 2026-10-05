class DamageRange {
  const DamageRange({
    required this.rangeStartMeters,
    required this.rangeEndMeters,
    required this.headDamage,
    required this.bodyDamage,
    required this.legDamage,
  });

  factory DamageRange.fromJson(Map<String, dynamic> json) {
    return DamageRange(
      rangeStartMeters: (json['rangeStartMeters'] as num).toDouble(),
      rangeEndMeters: (json['rangeEndMeters'] as num).toDouble(),
      headDamage: (json['headDamage'] as num).toDouble(),
      bodyDamage: (json['bodyDamage'] as num).toDouble(),
      legDamage: (json['legDamage'] as num).toDouble(),
    );
  }

  final double rangeStartMeters;
  final double rangeEndMeters;
  final double headDamage;
  final double bodyDamage;
  final double legDamage;
}

/// A paid skin reduced to what a quiz question and the price list show.
class WeaponSkinPreview {
  const WeaponSkinPreview({required this.displayName, required this.displayIcon, this.uuid, this.contentTierUuid});

  final String displayName;
  final String displayIcon;
  final String? uuid;

  /// The edition (Select, Deluxe…), which sets the price.
  final String? contentTierUuid;
}

class Weapon {
  const Weapon({
    required this.uuid,
    required this.displayName,
    required this.category,
    required this.displayIcon,
    required this.cost,
    required this.fireRate,
    required this.magazineSize,
    required this.damageRanges,
    this.skinPreviews = const [],
  });

  factory Weapon.fromJson(Map<String, dynamic> json) {
    final rawCategory = json['category'] as String? ?? '';
    final stats = json['weaponStats'] as Map<String, dynamic>?;
    final shopData = json['shopData'] as Map<String, dynamic>?;

    return Weapon(
      uuid: json['uuid'] as String,
      displayName: json['displayName'] as String,
      category: rawCategory.split('::').last,
      displayIcon: json['displayIcon'] as String?,
      cost: (shopData?['cost'] as num?)?.toInt() ?? 0,
      fireRate: (stats?['fireRate'] as num?)?.toDouble(),
      magazineSize: (stats?['magazineSize'] as num?)?.toInt(),
      damageRanges: (stats?['damageRanges'] as List<dynamic>? ?? [])
          .map((d) => DamageRange.fromJson(d as Map<String, dynamic>))
          .toList(),
      skinPreviews: [
        for (final skin in json['skins'] as List<dynamic>? ?? const [])
          if (skin is Map<String, dynamic> &&
              skin['contentTierUuid'] != null &&
              _skinIcon(skin) != null &&
              skin['displayName'] is String)
            WeaponSkinPreview(
              displayName: skin['displayName'] as String,
              displayIcon: _skinIcon(skin)!,
              uuid: skin['uuid'] as String?,
              contentTierUuid: skin['contentTierUuid'] as String?,
            ),
      ],
    );
  }

  /// The skin's picture; a few skins only have one on their first level or
  /// variant.
  static String? _skinIcon(Map<String, dynamic> skin) {
    String? first(Object? list, String field) {
      if (list is! List<dynamic> || list.isEmpty) return null;
      final entry = list.first;
      return entry is Map<String, dynamic> && entry[field] is String ? entry[field] as String : null;
    }

    final icon = skin['displayIcon'];
    return icon is String ? icon : first(skin['levels'], 'displayIcon') ?? first(skin['chromas'], 'fullRender');
  }

  final String uuid;
  final String displayName;
  final String category;
  final String? displayIcon;
  final int cost;
  final double? fireRate;
  final int? magazineSize;
  final List<DamageRange> damageRanges;

  /// The paid skins, the default one left out.
  final List<WeaponSkinPreview> skinPreviews;
}
