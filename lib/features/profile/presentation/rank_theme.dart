import 'package:flutter/material.dart';

import '../../../core/widgets/flame_backdrop.dart';

/// The rank families of the ladder, from Iron to Radiant.
enum RankFamily { unranked, iron, bronze, silver, gold, platinum, diamond, ascendant, immortal, radiant }

/// The colours and the energy a rank's emblem burns with: grey embers for
/// Iron, red fire for Immortal, a golden blaze for Radiant.
class RankTheme {
  const RankTheme({
    required this.family,
    required this.core,
    required this.main,
    required this.deep,
    required this.energy,
  });

  /// The theme of a competitive tier id, as the API numbers them: 3 to 5 is
  /// Iron, three tiers per family, 27 is Radiant. Anything else is unranked.
  factory RankTheme.ofTier(int? tierId) {
    final tier = tierId ?? 0;
    if (tier >= 27) return _themes[RankFamily.radiant]!;
    if (tier < 3) return _themes[RankFamily.unranked]!;
    final family = RankFamily.values[1 + ((tier - 3) ~/ 3).clamp(0, 7)];
    return _themes[family]!;
  }

  static const _themes = {
    RankFamily.unranked: RankTheme(
      family: RankFamily.unranked,
      core: Color(0xFFFFD27A),
      main: Color(0xFFFF7A2F),
      deep: Color(0xFFFF4655),
      energy: 0.6,
    ),
    RankFamily.iron: RankTheme(
      family: RankFamily.iron,
      core: Color(0xFFD5D8DD),
      main: Color(0xFF8E949D),
      deep: Color(0xFF4B5058),
      energy: 0.35,
    ),
    RankFamily.bronze: RankTheme(
      family: RankFamily.bronze,
      core: Color(0xFFF5C995),
      main: Color(0xFFC9844C),
      deep: Color(0xFF7A4A24),
      energy: 0.45,
    ),
    RankFamily.silver: RankTheme(
      family: RankFamily.silver,
      core: Color(0xFFFFFFFF),
      main: Color(0xFFC7D2DB),
      deep: Color(0xFF7F8C99),
      energy: 0.5,
    ),
    RankFamily.gold: RankTheme(
      family: RankFamily.gold,
      core: Color(0xFFFFF0A8),
      main: Color(0xFFF2C14E),
      deep: Color(0xFFB07A16),
      energy: 0.6,
    ),
    RankFamily.platinum: RankTheme(
      family: RankFamily.platinum,
      core: Color(0xFFB8FBFF),
      main: Color(0xFF3FC1CF),
      deep: Color(0xFF1D6F86),
      energy: 0.68,
    ),
    RankFamily.diamond: RankTheme(
      family: RankFamily.diamond,
      core: Color(0xFFF7C9FF),
      main: Color(0xFFC77DFF),
      deep: Color(0xFF7B3FC4),
      energy: 0.76,
    ),
    RankFamily.ascendant: RankTheme(
      family: RankFamily.ascendant,
      core: Color(0xFFB9FFD6),
      main: Color(0xFF2FD38A),
      deep: Color(0xFF0E7A4C),
      energy: 0.84,
    ),
    RankFamily.immortal: RankTheme(
      family: RankFamily.immortal,
      core: Color(0xFFFFB3BE),
      main: Color(0xFFFF3B5C),
      deep: Color(0xFF9E1030),
      energy: 0.92,
    ),
    RankFamily.radiant: RankTheme(
      family: RankFamily.radiant,
      core: Color(0xFFFFFDE8),
      main: Color(0xFFFFE27A),
      deep: Color(0xFFFFAE34),
      energy: 1,
    ),
  };

  final RankFamily family;

  /// The hottest colour, at the heart of the glow.
  final Color core;

  /// The rank's own colour, for text and borders.
  final Color main;

  /// The colour the glow fades into.
  final Color deep;

  /// 0 to 1: how lively the aura is. Higher ranks burn brighter.
  final double energy;

  FlamePalette get palette => FlamePalette(core: core, flame: main, ember: deep);

  LinearGradient get gradient =>
      LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [core, main, deep]);
}
