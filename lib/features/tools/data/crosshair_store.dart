import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/crosshair.dart';

/// The crosshair codes the player kept, on the device.
class CrosshairStore {
  static const _key = 'tools.crosshairs';

  Future<List<SavedCrosshair>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getStringList(_key) ?? const <String>[];
    return [for (final raw in stored) ?_tryParse(raw)];
  }

  Future<void> save(List<SavedCrosshair> crosshairs) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_key, [for (final crosshair in crosshairs) jsonEncode(crosshair.toJson())]);
  }

  SavedCrosshair? _tryParse(String raw) {
    try {
      return SavedCrosshair.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }
}
