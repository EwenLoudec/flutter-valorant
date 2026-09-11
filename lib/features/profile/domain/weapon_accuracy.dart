import 'player_match.dart';

/// Where a player's shots land with one weapon, across several matches.
class WeaponAccuracy {
  const WeaponAccuracy({
    required this.weaponName,
    required this.headshots,
    required this.bodyshots,
    required this.legshots,
    required this.matchCount,
  });

  /// Sums every match of the history, weapon by weapon, most used first.
  static List<WeaponAccuracy> aggregate(List<PlayerMatch> matches) {
    final headshots = <String, int>{};
    final bodyshots = <String, int>{};
    final legshots = <String, int>{};
    final matchCount = <String, int>{};

    for (final match in matches) {
      for (final shots in match.shotsByWeapon) {
        final weapon = shots.weaponName;
        headshots[weapon] = (headshots[weapon] ?? 0) + shots.headshots;
        bodyshots[weapon] = (bodyshots[weapon] ?? 0) + shots.bodyshots;
        legshots[weapon] = (legshots[weapon] ?? 0) + shots.legshots;
        matchCount[weapon] = (matchCount[weapon] ?? 0) + 1;
      }
    }

    final weapons = [
      for (final weapon in headshots.keys)
        WeaponAccuracy(
          weaponName: weapon,
          headshots: headshots[weapon] ?? 0,
          bodyshots: bodyshots[weapon] ?? 0,
          legshots: legshots[weapon] ?? 0,
          matchCount: matchCount[weapon] ?? 0,
        ),
    ];
    weapons.sort((a, b) => b.total.compareTo(a.total));
    return weapons;
  }

  /// The same figures, all weapons merged.
  static WeaponAccuracy? overall(List<WeaponAccuracy> weapons) {
    if (weapons.isEmpty) return null;

    return WeaponAccuracy(
      weaponName: 'Toutes armes',
      headshots: weapons.fold(0, (sum, weapon) => sum + weapon.headshots),
      bodyshots: weapons.fold(0, (sum, weapon) => sum + weapon.bodyshots),
      legshots: weapons.fold(0, (sum, weapon) => sum + weapon.legshots),
      matchCount: weapons.fold(0, (best, weapon) => weapon.matchCount > best ? weapon.matchCount : best),
    );
  }

  final String weaponName;
  final int headshots;
  final int bodyshots;
  final int legshots;
  final int matchCount;

  int get total => headshots + bodyshots + legshots;
  double get headshotPercent => _percentOf(headshots);
  double get bodyshotPercent => _percentOf(bodyshots);
  double get legshotPercent => _percentOf(legshots);

  double _percentOf(int shots) => total == 0 ? 0 : shots * 100 / total;
}
