import 'package:flutter/material.dart';

class RankTier {
  const RankTier({
    required this.tier,
    required this.tierName,
    required this.divisionName,
    required this.color,
    required this.backgroundColor,
    required this.largeIcon,
  });

  factory RankTier.fromJson(Map<String, dynamic> json) {
    return RankTier(
      tier: json['tier'] as int,
      tierName: json['tierName'] as String? ?? '',
      divisionName: json['divisionName'] as String? ?? '',
      color: _parseColor(json['color'] as String?),
      backgroundColor: _parseColor(json['backgroundColor'] as String?),
      largeIcon: json['largeIcon'] as String?,
    );
  }

  final int tier;
  final String tierName;
  final String divisionName;
  final Color color;
  final Color backgroundColor;
  final String? largeIcon;

  static Color _parseColor(String? hex) {
    if (hex == null || hex.length < 6) return Colors.grey;
    final value = int.tryParse(hex.substring(0, 6), radix: 16) ?? 0x999999;
    return Color(0xFF000000 | value);
  }
}
