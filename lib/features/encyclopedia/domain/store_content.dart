import '../../../core/text/search_text.dart';

/// A store bundle: the themed collection of skins sold together.
class Bundle {
  const Bundle({
    required this.uuid,
    required this.displayName,
    required this.subtitle,
    required this.displayIcon,
    required this.verticalPromoImage,
  });

  factory Bundle.fromJson(Map<String, dynamic> json) {
    return Bundle(
      uuid: json['uuid'] as String,
      displayName: json['displayName'] as String? ?? '',
      subtitle: json['displayNameSubText'] as String? ?? json['extraDescription'] as String?,
      displayIcon: json['displayIcon'] as String? ?? json['displayIcon2'] as String?,
      verticalPromoImage: json['verticalPromoImage'] as String?,
    );
  }

  final String uuid;
  final String displayName;
  final String? subtitle;
  final String? displayIcon;
  final String? verticalPromoImage;

  bool matches(String search) => matchesSearch(search, [displayName]);
}

/// A way of playing: Standard, Spike Rush, Deathmatch…
class GameMode {
  const GameMode({
    required this.uuid,
    required this.displayName,
    required this.description,
    required this.duration,
    required this.displayIcon,
    required this.roundsPerHalf,
  });

  factory GameMode.fromJson(Map<String, dynamic> json) {
    return GameMode(
      uuid: json['uuid'] as String,
      displayName: json['displayName'] as String? ?? '',
      description: json['description'] as String?,
      duration: json['duration'] as String?,
      displayIcon: json['displayIcon'] as String? ?? json['listViewIconTall'] as String?,
      roundsPerHalf: (json['roundsPerHalf'] as num?)?.toInt() ?? -1,
    );
  }

  final String uuid;
  final String displayName;
  final String? description;
  final String? duration;
  final String? displayIcon;

  /// -1 when the mode is not played in halves.
  final int roundsPerHalf;

  /// Tutorials and the range come back without a duration: not real modes.
  bool get isPlayable => duration != null && duration!.isNotEmpty;
}

/// A shield sold in the buy phase.
class Gear {
  const Gear({
    required this.uuid,
    required this.displayName,
    required this.description,
    required this.cost,
    required this.displayIcon,
    required this.details,
  });

  factory Gear.fromJson(Map<String, dynamic> json) {
    final shopData = json['shopData'] as Map<String, dynamic>?;
    return Gear(
      uuid: json['uuid'] as String,
      displayName: json['displayName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      cost: (shopData?['cost'] as num?)?.toInt() ?? 0,
      displayIcon: json['displayIcon'] as String?,
      details: [
        for (final detail in json['details'] as List<dynamic>? ?? const [])
          if (detail is Map<String, dynamic>) (name: '${detail['name'] ?? ''}', value: '${detail['value'] ?? ''}'),
      ],
    );
  }

  final String uuid;
  final String displayName;
  final String description;
  final int cost;
  final String? displayIcon;
  final List<({String name, String value})> details;
}

/// A premium or event currency, which contracts sometimes reward.
class Currency {
  const Currency({required this.uuid, required this.displayName, required this.displayIcon});

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      uuid: json['uuid'] as String,
      displayName: json['displayName'] as String? ?? '',
      displayIcon: json['displayIcon'] as String?,
    );
  }

  final String uuid;
  final String displayName;
  final String? displayIcon;
}

/// One level of a weapon skin, which is what contracts actually hand out.
class SkinLevelInfo {
  const SkinLevelInfo({required this.uuid, required this.displayName, required this.displayIcon});

  factory SkinLevelInfo.fromJson(Map<String, dynamic> json) {
    return SkinLevelInfo(
      uuid: json['uuid'] as String,
      displayName: json['displayName'] as String? ?? '',
      displayIcon: json['displayIcon'] as String?,
    );
  }

  final String uuid;
  final String displayName;
  final String? displayIcon;
}
