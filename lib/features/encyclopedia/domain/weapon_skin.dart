class WeaponSkinLevel {
  const WeaponSkinLevel({
    required this.uuid,
    required this.levelLabel,
    required this.displayIcon,
    required this.streamedVideo,
  });

  factory WeaponSkinLevel.fromJson(Map<String, dynamic> json, int index) {
    final levelItem = json['levelItem'] as String?;
    return WeaponSkinLevel(
      uuid: json['uuid'] as String,
      levelLabel: _labelFor(index, levelItem),
      displayIcon: json['displayIcon'] as String?,
      streamedVideo: json['streamedVideo'] as String?,
    );
  }

  final String uuid;
  final String levelLabel;
  final String? displayIcon;
  final String? streamedVideo;

  static String _labelFor(int index, String? levelItem) {
    if (levelItem == null) return 'Niveau ${index + 1}';
    final kind = levelItem.split('::').last;
    return switch (kind) {
      'VFX' => 'Effets',
      'Animation' => 'Animation',
      'Finisher' => 'Finish',
      'KillCounter' => 'Compteur',
      _ => 'Niveau ${index + 1}',
    };
  }
}

class WeaponSkinChroma {
  const WeaponSkinChroma({
    required this.uuid,
    required this.swatch,
    required this.fullRender,
    required this.streamedVideo,
  });

  factory WeaponSkinChroma.fromJson(Map<String, dynamic> json) {
    return WeaponSkinChroma(
      uuid: json['uuid'] as String,
      swatch: json['swatch'] as String?,
      fullRender: json['fullRender'] as String?,
      streamedVideo: json['streamedVideo'] as String?,
    );
  }

  final String uuid;
  final String? swatch;
  final String? fullRender;
  final String? streamedVideo;
}

class WeaponSkin {
  const WeaponSkin({
    required this.uuid,
    required this.displayName,
    required this.contentTierUuid,
    required this.displayIcon,
    required this.chromas,
    required this.levels,
  });

  factory WeaponSkin.fromJson(Map<String, dynamic> json) {
    final levelsJson = json['levels'] as List<dynamic>? ?? [];
    return WeaponSkin(
      uuid: json['uuid'] as String,
      displayName: json['displayName'] as String,
      contentTierUuid: json['contentTierUuid'] as String?,
      displayIcon: json['displayIcon'] as String?,
      chromas: (json['chromas'] as List<dynamic>? ?? [])
          .map((c) => WeaponSkinChroma.fromJson(c as Map<String, dynamic>))
          .toList(),
      levels: [
        for (final (index, level) in levelsJson.indexed)
          WeaponSkinLevel.fromJson(level as Map<String, dynamic>, index),
      ],
    );
  }

  final String uuid;
  final String displayName;
  final String? contentTierUuid;
  final String? displayIcon;
  final List<WeaponSkinChroma> chromas;
  final List<WeaponSkinLevel> levels;
}
