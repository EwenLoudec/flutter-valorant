import 'lineup_media.dart';

/// Which half of the round a spot is meant for.
enum LineupSide {
  attack('attack', 'Attaque'),
  defense('defense', 'Défense'),
  both('both', 'Les deux');

  const LineupSide(this.code, this.label);

  static LineupSide fromCode(String? code) {
    return LineupSide.values.firstWhere((side) => side.code == code, orElse: () => LineupSide.both);
  }

  final String code;
  final String label;
}

enum LineupDifficulty {
  easy('easy', 'Facile'),
  medium('medium', 'Moyen'),
  hard('hard', 'Difficile');

  const LineupDifficulty(this.code, this.label);

  static LineupDifficulty fromCode(String? code) {
    return LineupDifficulty.values.firstWhere(
      (difficulty) => difficulty.code == code,
      orElse: () => LineupDifficulty.medium,
    );
  }

  final String code;
  final String label;
}

/// A point on a map, either as exact minimap coordinates (0-1, placed by
/// hand in the editor) or as a callout to look up in Riot's map data.
class LineupAnchor {
  const LineupAnchor({this.x, this.y, this.calloutName, this.calloutRegion});

  factory LineupAnchor.fromJson(Map<String, dynamic> json) {
    return LineupAnchor(
      x: (json['x'] as num?)?.toDouble(),
      y: (json['y'] as num?)?.toDouble(),
      calloutName: json['callout'] as String?,
      calloutRegion: json['region'] as String?,
    );
  }

  final double? x;
  final double? y;
  final String? calloutName;
  final String? calloutRegion;

  bool get hasCoordinates => x != null && y != null;

  /// What to show as the origin/target of a spot, e.g. "A Main".
  String get label {
    final name = calloutName;
    if (name == null) return 'Point libre';
    final region = calloutRegion;
    return region == null || region.isEmpty || region == name ? name : '$region $name';
  }

  Map<String, dynamic> toJson() => {
    if (x != null) 'x': x,
    if (y != null) 'y': y,
    if (calloutName != null) 'callout': calloutName,
    if (calloutRegion != null) 'region': calloutRegion,
  };
}

/// A throw (from → to) or a placement (from only) for one agent ability on
/// one map, written like a guide: where to stand, what to aim at, how to
/// throw, and the pictures that go with each step.
class Lineup {
  const Lineup({
    required this.id,
    required this.mapName,
    required this.agentName,
    required this.abilitySlot,
    required this.abilityName,
    required this.side,
    required this.from,
    required this.to,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.isVerified,
    required this.isBundled,
    this.position = '',
    this.aim = '',
    this.throwStyle = LineupThrow.unspecified,
    this.media = const [],
    this.demoUrl,
    this.demoTitle,
  });

  factory Lineup.fromJson(Map<String, dynamic> json, {required bool isBundled}) {
    final target = json['to'];

    return Lineup(
      id: json['id'] as String,
      mapName: json['map'] as String? ?? '',
      agentName: json['agent'] as String? ?? '',
      abilitySlot: json['ability'] as String? ?? '',
      abilityName: json['abilityName'] as String? ?? '',
      side: LineupSide.fromCode(json['side'] as String?),
      from: LineupAnchor.fromJson(json['from'] as Map<String, dynamic>? ?? const {}),
      to: target is Map<String, dynamic> ? LineupAnchor.fromJson(target) : null,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      difficulty: LineupDifficulty.fromCode(json['difficulty'] as String?),
      isVerified: json['verified'] as bool? ?? false,
      position: json['position'] as String? ?? '',
      aim: json['aim'] as String? ?? '',
      throwStyle: LineupThrow.fromCode(json['throw'] as String?),
      media: _mediaFromJson(json),
      demoUrl: json['demoUrl'] as String?,
      demoTitle: json['demoTitle'] as String?,
      isBundled: isBundled,
    );
  }

  /// Spots saved before the guide fields existed kept a single picture under
  /// `image`; it becomes the aiming shot.
  static List<LineupMedia> _mediaFromJson(Map<String, dynamic> json) {
    final stored = json['media'];
    if (stored is List<dynamic>) {
      return [
        for (final entry in stored) LineupMedia.fromJson(entry as Map<String, dynamic>),
      ];
    }

    final legacyImage = json['image'] as String?;
    if (legacyImage == null) return const [];
    return [LineupMedia(role: LineupMediaRole.aim, kind: LineupMediaKind.photo, path: legacyImage)];
  }

  final String id;
  final String mapName;
  final String agentName;

  /// Riot's ability slot: Ability1, Ability2, Grenade or Ultimate.
  final String abilitySlot;

  /// Kept alongside the slot so a spot still reads correctly before the
  /// agent catalogue has loaded.
  final String abilityName;

  final LineupSide side;
  final LineupAnchor from;
  final LineupAnchor? to;
  final String title;
  final String description;
  final LineupDifficulty difficulty;
  final bool isVerified;

  /// Step 1: where to stand, in the player's own words.
  final String position;

  /// Step 2: what the crosshair has to be on.
  final String aim;

  /// Step 3: how the utility leaves the hands.
  final LineupThrow throwStyle;

  /// Pictures and clips stored on the device, one or more per step.
  final List<LineupMedia> media;

  /// A pinned video (YouTube and friends) demonstrating the spot.
  final String? demoUrl;

  /// The video's own title, so it is obvious what the clip actually covers.
  final String? demoTitle;

  /// Bundled spots ship with the app and cannot be edited, only duplicated.
  final bool isBundled;

  bool get isThrow => to != null;

  LineupMedia? mediaFor(LineupMediaRole role) {
    for (final entry in media) {
      if (entry.role == role) return entry;
    }
    return null;
  }

  /// A spot is only usable once someone has written down where to stand and
  /// what to aim at.
  bool get isDocumented => position.isNotEmpty && aim.isNotEmpty;

  /// How much of the guide is filled in, for the progress shown in the app.
  int get completedSteps {
    var steps = 0;
    if (position.isNotEmpty) steps++;
    // A placement has nothing to aim at: that step counts as done.
    if (!isThrow || aim.isNotEmpty) steps++;
    if (throwStyle.isSpecified) steps++;
    if (media.isNotEmpty || demoUrl != null) steps++;
    return steps;
  }

  static const totalSteps = 4;

  /// The in-game key of the ability, as players call it.
  String get abilityKey => switch (abilitySlot) {
    'Ability1' => 'Q',
    'Ability2' => 'E',
    'Grenade' => 'C',
    'Ultimate' => 'X',
    _ => '',
  };

  Lineup copyWith({
    String? mapName,
    String? agentName,
    String? abilitySlot,
    String? abilityName,
    LineupSide? side,
    LineupAnchor? from,
    LineupAnchor? to,
    bool clearTarget = false,
    String? title,
    String? description,
    LineupDifficulty? difficulty,
    bool? isVerified,
    String? position,
    String? aim,
    LineupThrow? throwStyle,
    List<LineupMedia>? media,
    String? demoUrl,
    String? demoTitle,
    bool clearDemoUrl = false,
    bool? isBundled,
    String? id,
  }) {
    return Lineup(
      id: id ?? this.id,
      mapName: mapName ?? this.mapName,
      agentName: agentName ?? this.agentName,
      abilitySlot: abilitySlot ?? this.abilitySlot,
      abilityName: abilityName ?? this.abilityName,
      side: side ?? this.side,
      from: from ?? this.from,
      to: clearTarget ? null : (to ?? this.to),
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      isVerified: isVerified ?? this.isVerified,
      position: position ?? this.position,
      aim: aim ?? this.aim,
      throwStyle: throwStyle ?? this.throwStyle,
      media: media ?? this.media,
      demoUrl: clearDemoUrl ? null : (demoUrl ?? this.demoUrl),
      demoTitle: clearDemoUrl ? null : (demoTitle ?? this.demoTitle),
      isBundled: isBundled ?? this.isBundled,
    );
  }

  /// A ready-made query to find community demos of this exact spot.
  Uri get demoSearchUri {
    final target = to;
    final query = [
      agentName,
      mapName,
      'lineup',
      from.label,
      if (target != null) target.label,
    ].join(' ');

    return Uri.https('www.youtube.com', '/results', {'search_query': query});
  }

  /// The community lineup browser, filtered on this map — the place to go
  /// for the pictures the app cannot ship itself.
  Uri get mapLineupsUri {
    return Uri.https('op.gg', '/valorant/lineups', {'map': mapName.toLowerCase()});
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'map': mapName,
    'agent': agentName,
    'ability': abilitySlot,
    'abilityName': abilityName,
    'side': side.code,
    'from': from.toJson(),
    if (to != null) 'to': to!.toJson(),
    'title': title,
    'description': description,
    'difficulty': difficulty.code,
    'verified': isVerified,
    if (position.isNotEmpty) 'position': position,
    if (aim.isNotEmpty) 'aim': aim,
    if (throwStyle.isSpecified) 'throw': throwStyle.code,
    if (media.isNotEmpty) 'media': [for (final entry in media) entry.toJson()],
    'demoUrl': ?demoUrl,
    'demoTitle': ?demoTitle,
  };
}
