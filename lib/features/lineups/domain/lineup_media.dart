/// What a picture or a clip shows, so a spot reads like a real guide rather
/// than a pile of screenshots.
enum LineupMediaRole {
  position('position', 'Se placer', 'Où poser ses pieds'),
  aim('aim', 'Viser', 'Ce que le viseur doit toucher'),
  result('result', 'Résultat', 'Où l\'utilitaire atterrit'),
  demo('demo', 'Démo', 'Le lancer en entier');

  const LineupMediaRole(this.code, this.label, this.hint);

  static LineupMediaRole fromCode(String? code) {
    return LineupMediaRole.values.firstWhere((role) => role.code == code, orElse: () => LineupMediaRole.aim);
  }

  final String code;
  final String label;
  final String hint;
}

enum LineupMediaKind {
  photo('photo'),
  video('video');

  const LineupMediaKind(this.code);

  static LineupMediaKind fromCode(String? code) {
    return LineupMediaKind.values.firstWhere((kind) => kind.code == code, orElse: () => LineupMediaKind.photo);
  }

  final String code;
}

/// A picture or clip stored on the device for one step of a spot.
class LineupMedia {
  const LineupMedia({required this.role, required this.kind, required this.path});

  factory LineupMedia.fromJson(Map<String, dynamic> json) {
    return LineupMedia(
      role: LineupMediaRole.fromCode(json['role'] as String?),
      kind: LineupMediaKind.fromCode(json['kind'] as String?),
      path: json['path'] as String? ?? '',
    );
  }

  final LineupMediaRole role;
  final LineupMediaKind kind;
  final String path;

  bool get isVideo => kind == LineupMediaKind.video;

  Map<String, dynamic> toJson() => {'role': role.code, 'kind': kind.code, 'path': path};
}

/// How the utility leaves the player's hands.
enum LineupThrow {
  unspecified('unspecified', 'À préciser', ''),
  simple('simple', 'Lancer simple', 'Clic gauche, immobile'),
  rightClick('right_click', 'Clic droit', 'Lancer court ou en cloche'),
  jump('jump', 'Saut-lancer', 'Sauter, puis lancer au sommet'),
  jumpThrow('jump_throw', 'Saut + lancer', 'Saut et lancer sur la même frappe'),
  crouch('crouch', 'Accroupi', 'Lancer en position accroupie');

  const LineupThrow(this.code, this.label, this.hint);

  static LineupThrow fromCode(String? code) {
    return LineupThrow.values.firstWhere((style) => style.code == code, orElse: () => LineupThrow.unspecified);
  }

  final String code;
  final String label;
  final String hint;

  bool get isSpecified => this != LineupThrow.unspecified;
}
