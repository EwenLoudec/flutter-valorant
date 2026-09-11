/// A Riot ID, i.e. the `Pseudo#TAG` pair identifying a Valorant account.
class RiotId {
  const RiotId({required this.name, required this.tag});

  /// Accepts `Pseudo#TAG`, tolerating spaces around the separator.
  static RiotId? tryParse(String raw) {
    final parts = raw.trim().split('#');
    if (parts.length != 2) return null;

    final name = parts.first.trim();
    final tag = parts.last.trim();
    if (name.isEmpty || tag.isEmpty) return null;

    return RiotId(name: name, tag: tag);
  }

  final String name;
  final String tag;

  String get label => '$name#$tag';

  @override
  bool operator ==(Object other) => other is RiotId && other.name == name && other.tag == tag;

  @override
  int get hashCode => Object.hash(name, tag);

  @override
  String toString() => label;
}

/// The regions (affinities) HenrikDev accepts, with a French label.
class ValorantRegion {
  const ValorantRegion({required this.code, required this.label});

  static const eu = ValorantRegion(code: 'eu', label: 'Europe');
  static const na = ValorantRegion(code: 'na', label: 'Amérique du Nord');
  static const ap = ValorantRegion(code: 'ap', label: 'Asie-Pacifique');
  static const kr = ValorantRegion(code: 'kr', label: 'Corée');
  static const latam = ValorantRegion(code: 'latam', label: 'Amérique latine');
  static const br = ValorantRegion(code: 'br', label: 'Brésil');

  static const all = [eu, na, ap, kr, latam, br];

  static ValorantRegion fromCode(String? code) {
    return all.firstWhere((region) => region.code == code, orElse: () => eu);
  }

  final String code;
  final String label;
}

/// Everything needed to address a player on the API: who, and where they play.
class PlayerQuery {
  const PlayerQuery({required this.riotId, required this.region});

  final RiotId riotId;
  final ValorantRegion region;

  @override
  bool operator ==(Object other) =>
      other is PlayerQuery && other.riotId == riotId && other.region.code == region.code;

  @override
  int get hashCode => Object.hash(riotId, region.code);
}
