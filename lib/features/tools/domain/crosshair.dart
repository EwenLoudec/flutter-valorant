import 'dart:ui';

/// One set of crosshair lines (inner or outer), in the game's own units:
/// pixels at 1080p.
class CrosshairLines {
  const CrosshairLines({
    required this.isVisible,
    required this.thickness,
    required this.length,
    required this.verticalLength,
    required this.offset,
    required this.opacity,
  });

  final bool isVisible;
  final double thickness;
  final double length;

  /// Equal to [length] unless the code separates the vertical lines.
  final double verticalLength;
  final double offset;
  final double opacity;
}

/// The primary crosshair described by a Valorant crosshair profile code,
/// e.g. `0;P;c;5;h;0;0l;4;0o;2;0a;1;0f;0;1b;0`.
///
/// Any setting missing from the code keeps the game's default, as the
/// client does when importing it.
class Crosshair {
  const Crosshair({
    required this.color,
    required this.hasOutlines,
    required this.outlineThickness,
    required this.outlineOpacity,
    required this.hasCenterDot,
    required this.centerDotThickness,
    required this.centerDotOpacity,
    required this.inner,
    required this.outer,
  });

  /// The eight preset colors of the settings menu, by index.
  static const presetColors = [
    Color(0xFFFFFFFF),
    Color(0xFF00FF00),
    Color(0xFF7FFF00),
    Color(0xFFDFFF00),
    Color(0xFFFFFF00),
    Color(0xFF00FFFF),
    Color(0xFFFF00FF),
    Color(0xFFFF0000),
  ];

  static const presetColorNames = [
    'Blanc',
    'Vert',
    'Vert-jaune',
    'Jaune-vert',
    'Jaune',
    'Cyan',
    'Rose',
    'Rouge',
  ];

  static const defaults = Crosshair(
    color: Color(0xFF00FFFF),
    hasOutlines: true,
    outlineThickness: 1,
    outlineOpacity: 0.5,
    hasCenterDot: false,
    centerDotThickness: 2,
    centerDotOpacity: 1,
    inner: CrosshairLines(isVisible: true, thickness: 2, length: 6, verticalLength: 6, offset: 3, opacity: 0.8),
    outer: CrosshairLines(isVisible: true, thickness: 2, length: 2, verticalLength: 2, offset: 10, opacity: 0.35),
  );

  /// Returns null when [code] is not a crosshair profile code.
  static Crosshair? tryParse(String code) {
    final tokens = code.trim().split(';').map((token) => token.trim()).toList();
    if (tokens.length < 2 || tokens.first != '0') return null;

    final primary = <String, String>{};
    var section = '';
    var index = 1;
    while (index < tokens.length) {
      final token = tokens[index];
      if (token == 'P' || token == 'A' || token == 'S') {
        section = token;
        index++;
        continue;
      }
      if (token.isEmpty || index + 1 >= tokens.length) break;
      // Settings before the first section apply to the primary crosshair.
      if (section == 'P' || section.isEmpty) primary[token] = tokens[index + 1];
      index += 2;
    }

    double number(String key, double fallback) => double.tryParse(primary[key] ?? '') ?? fallback;
    bool flag(String key, bool fallback) {
      final value = primary[key];
      if (value == null) return fallback;
      return value != '0';
    }

    final colorIndex = int.tryParse(primary['c'] ?? '');
    var color = defaults.color;
    if (colorIndex != null && colorIndex >= 0 && colorIndex < presetColors.length) {
      color = presetColors[colorIndex];
    } else if (colorIndex == 8) {
      color = _parseHex(primary['u']) ?? color;
    }

    CrosshairLines lines(String prefix, CrosshairLines fallback) {
      final length = number('${prefix}l', fallback.length);
      final isVerticalSeparate = flag('${prefix}g', false);
      return CrosshairLines(
        isVisible: flag('${prefix}b', fallback.isVisible),
        thickness: number('${prefix}t', fallback.thickness),
        length: length,
        verticalLength: isVerticalSeparate ? number('${prefix}v', length) : length,
        offset: number('${prefix}o', fallback.offset),
        opacity: number('${prefix}a', fallback.opacity).clamp(0, 1).toDouble(),
      );
    }

    return Crosshair(
      color: color,
      hasOutlines: flag('h', defaults.hasOutlines),
      outlineThickness: number('t', defaults.outlineThickness),
      outlineOpacity: number('o', defaults.outlineOpacity).clamp(0, 1).toDouble(),
      hasCenterDot: flag('d', defaults.hasCenterDot),
      centerDotThickness: number('z', defaults.centerDotThickness),
      centerDotOpacity: number('a', defaults.centerDotOpacity).clamp(0, 1).toDouble(),
      inner: lines('0', defaults.inner),
      outer: lines('1', defaults.outer),
    );
  }

  /// `RRGGBB` or `RRGGBBAA`.
  static Color? _parseHex(String? hex) {
    if (hex == null) return null;
    final clean = hex.replaceAll('#', '');
    if (clean.length != 6 && clean.length != 8) return null;
    final value = int.tryParse(clean.substring(0, 6), radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }

  final Color color;
  final bool hasOutlines;
  final double outlineThickness;
  final double outlineOpacity;
  final bool hasCenterDot;
  final double centerDotThickness;
  final double centerDotOpacity;
  final CrosshairLines inner;
  final CrosshairLines outer;

  /// Half the size of the whole crosshair, outlines included, to fit it in a
  /// preview.
  double get extent {
    var extent = hasCenterDot ? centerDotThickness / 2 : 0.0;
    for (final lines in [inner, outer]) {
      if (!lines.isVisible) continue;
      final reach = lines.offset + (lines.length > lines.verticalLength ? lines.length : lines.verticalLength);
      if (reach > extent) extent = reach;
    }
    return extent + (hasOutlines ? outlineThickness : 0);
  }
}

/// A crosshair the player saved under a name.
class SavedCrosshair {
  const SavedCrosshair({required this.name, required this.code});

  static SavedCrosshair? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final name = json['name'];
    final code = json['code'];
    if (name is! String || code is! String) return null;
    return SavedCrosshair(name: name, code: code);
  }

  final String name;
  final String code;

  Map<String, dynamic> toJson() => {'name': name, 'code': code};
}
