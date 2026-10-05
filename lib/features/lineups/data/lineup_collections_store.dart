import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/lineup_collections.dart';

/// Favourites and named collections of spots, on the device.
class LineupCollectionsStore {
  static const _favoritesKey = 'lineups.favorites';
  static const _collectionsKey = 'lineups.collections';

  Future<LineupCollections> load() async {
    final preferences = await SharedPreferences.getInstance();
    Object? collections;
    final raw = preferences.getString(_collectionsKey);
    if (raw != null) {
      try {
        collections = jsonDecode(raw);
      } on FormatException {
        collections = null;
      }
    }
    return LineupCollections.fromJson(preferences.getStringList(_favoritesKey), collections);
  }

  Future<void> save(LineupCollections value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_favoritesKey, value.favorites.toList()..sort());
    await preferences.setString(_collectionsKey, jsonEncode(value.collectionsToJson()));
  }
}
