import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/lineup.dart';

/// The spots shipped inside the app, in assets/data/lineups.json.
class BundledLineupsSource {
  static const assetPath = 'assets/data/lineups.json';

  Future<List<Lineup>> load() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    return [
      for (final entry in decoded['lineups'] as List<dynamic>? ?? const [])
        Lineup.fromJson(entry as Map<String, dynamic>, isBundled: true),
    ];
  }
}

/// The spots the player created or duplicated, kept on the device.
class UserLineupsStore {
  static const _key = 'lineups.user';

  Future<List<Lineup>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getStringList(_key) ?? const <String>[];

    return [for (final raw in stored) ?_tryParse(raw)];
  }

  Future<void> save(List<Lineup> lineups) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_key, [
      for (final lineup in lineups) jsonEncode(lineup.toJson()),
    ]);
  }

  Lineup? _tryParse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return Lineup.fromJson(decoded, isBundled: false);
  }
}
