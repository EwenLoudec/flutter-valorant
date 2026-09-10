import 'dart:ui';

class MapCallout {
  const MapCallout({
    required this.regionName,
    required this.superRegionName,
    required this.gameX,
    required this.gameY,
  });

  factory MapCallout.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    return MapCallout(
      regionName: json['regionName'] as String? ?? '',
      superRegionName: json['superRegionName'] as String? ?? '',
      gameX: (location?['x'] as num?)?.toDouble() ?? 0,
      gameY: (location?['y'] as num?)?.toDouble() ?? 0,
    );
  }

  final String regionName;
  final String superRegionName;
  final double gameX;
  final double gameY;
}

class GameMap {
  const GameMap({
    required this.uuid,
    required this.displayName,
    required this.tacticalDescription,
    required this.splash,
    required this.displayIcon,
    required this.xMultiplier,
    required this.yMultiplier,
    required this.xScalarToAdd,
    required this.yScalarToAdd,
    required this.callouts,
  });

  factory GameMap.fromJson(Map<String, dynamic> json) {
    return GameMap(
      uuid: json['uuid'] as String,
      displayName: json['displayName'] as String,
      tacticalDescription: json['tacticalDescription'] as String?,
      splash: json['splash'] as String?,
      displayIcon: json['displayIcon'] as String?,
      xMultiplier: (json['xMultiplier'] as num?)?.toDouble() ?? 0,
      yMultiplier: (json['yMultiplier'] as num?)?.toDouble() ?? 0,
      xScalarToAdd: (json['xScalarToAdd'] as num?)?.toDouble() ?? 0,
      yScalarToAdd: (json['yScalarToAdd'] as num?)?.toDouble() ?? 0,
      callouts: (json['callouts'] as List<dynamic>? ?? [])
          .map((c) => MapCallout.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  final String uuid;
  final String displayName;
  final String? tacticalDescription;
  final String? splash;
  final String? displayIcon;
  final double xMultiplier;
  final double yMultiplier;
  final double xScalarToAdd;
  final double yScalarToAdd;
  final List<MapCallout> callouts;

  /// Fractional (0-1) position of [callout] on the [displayIcon] tactical
  /// minimap image — valorant-api.com's documented world-to-minimap transform
  /// (note x/y are swapped between game space and minimap space).
  Offset normalizedPosition(MapCallout callout) {
    return Offset(
      callout.gameY * xMultiplier + xScalarToAdd,
      callout.gameX * yMultiplier + yScalarToAdd,
    );
  }
}
