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

/// A skin reduced to what a quiz question shows: its name and picture.
class WeaponSkinPreview {
  const WeaponSkinPreview({required this.displayName, required this.displayIcon});

  final String displayName;
  final String displayIcon;
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
              skin['displayIcon'] is String &&
              skin['displayName'] is String)
            WeaponSkinPreview(displayName: skin['displayName'] as String, displayIcon: skin['displayIcon'] as String),
      ],
    );
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
