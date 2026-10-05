import '../../../core/text/search_text.dart';

/// The account cosmetics valorant-api.com lists, besides weapon skins.
enum CosmeticKind {
  card('playercards', 'Cartes'),
  spray('sprays', 'Graffitis'),
  buddy('buddies', 'Porte-bonheur'),
  title('playertitles', 'Titres');

  const CosmeticKind(this.endpoint, this.label);

  static CosmeticKind? fromCode(String? code) {
    for (final kind in CosmeticKind.values) {
      if (kind.name == code) return kind;
    }
    return null;
  }

  /// Path segment on valorant-api.com.
  final String endpoint;
  final String label;
}

/// A player card, spray, gun buddy or title.
class Cosmetic {
  const Cosmetic({
    required this.uuid,
    required this.kind,
    required this.displayName,
    required this.imageUrl,
    this.wideImageUrl,
    this.titleText,
    this.levelUuids = const [],
  });

  /// Returns null for the entries the game never shows: the empty spray
  /// slot and titles without text.
  static Cosmetic? fromJson(Map<String, dynamic> json, CosmeticKind kind) {
    final uuid = json['uuid'] as String?;
    final name = json['displayName'] as String?;
    if (uuid == null || name == null || name.trim().isEmpty) return null;

    final levels = [
      for (final level in json['levels'] as List<dynamic>? ?? const [])
        if (level is Map<String, dynamic> && level['uuid'] is String) level['uuid'] as String,
    ];

    switch (kind) {
      case CosmeticKind.card:
        return Cosmetic(
          uuid: uuid,
          kind: kind,
          displayName: name,
          imageUrl: json['smallArt'] as String? ?? json['displayIcon'] as String?,
          wideImageUrl: json['wideArt'] as String?,
        );
      case CosmeticKind.spray:
        if (json['isNullSpray'] == true) return null;
        return Cosmetic(
          uuid: uuid,
          kind: kind,
          displayName: name,
          imageUrl:
              json['fullTransparentIcon'] as String? ?? json['displayIcon'] as String? ?? json['fullIcon'] as String?,
          levelUuids: levels,
        );
      case CosmeticKind.buddy:
        return Cosmetic(
          uuid: uuid,
          kind: kind,
          displayName: name,
          imageUrl: json['displayIcon'] as String?,
          levelUuids: levels,
        );
      case CosmeticKind.title:
        final text = (json['titleText'] as String?)?.trim();
        if (text == null || text.isEmpty) return null;
        return Cosmetic(uuid: uuid, kind: kind, displayName: name, imageUrl: null, titleText: text);
    }
  }

  final String uuid;
  final CosmeticKind kind;
  final String displayName;
  final String? imageUrl;

  /// Player cards also have a banner-shaped artwork.
  final String? wideImageUrl;

  /// What a title reads in game.
  final String? titleText;

  /// Sprays and buddies have levels, which is what contracts reward.
  final List<String> levelUuids;

  bool matches(String search) => matchesSearch(search, [displayName, titleText]);
}
