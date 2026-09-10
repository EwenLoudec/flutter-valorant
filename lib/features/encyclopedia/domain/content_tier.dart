import 'package:flutter/material.dart';

/// Skin rarity tier (Select, Deluxe, Premium, Exclusive, Ultra).
class ContentTier {
  const ContentTier({required this.uuid, required this.rank, required this.color, required this.displayIcon});

  factory ContentTier.fromJson(Map<String, dynamic> json) {
    return ContentTier(
      uuid: json['uuid'] as String,
      rank: json['rank'] as int,
      color: _parseColor(json['highlightColor'] as String?),
      displayIcon: json['displayIcon'] as String?,
    );
  }

  final String uuid;
  final int rank;
  final Color color;
  final String? displayIcon;

  static Color _parseColor(String? hex) {
    if (hex == null || hex.length < 6) return Colors.white70;
    final value = int.tryParse(hex.substring(0, 6), radix: 16) ?? 0xAAAAAA;
    return Color(0xFF000000 | value);
  }
}
