/// The spots the player starred, and the named lists they sorted spots into
/// (« Mes lineups Viper sur Ascent »…). Only ids are kept: a spot deleted
/// since simply stops showing.
class LineupCollections {
  const LineupCollections({this.favorites = const {}, this.collections = const {}});

  factory LineupCollections.fromJson(Object? favorites, Object? collections) {
    return LineupCollections(
      favorites: {
        if (favorites is List<dynamic>)
          for (final id in favorites)
            if (id is String) id,
      },
      collections: {
        if (collections is Map<String, dynamic>)
          for (final entry in collections.entries)
            if (entry.value is List<dynamic>)
              entry.key: [
                for (final id in entry.value as List<dynamic>)
                  if (id is String) id,
              ],
      },
    );
  }

  final Set<String> favorites;

  /// Collection name -> spot ids, in the order they were added.
  final Map<String, List<String>> collections;

  bool isFavorite(String lineupId) => favorites.contains(lineupId);

  List<String> collectionsOf(String lineupId) => [
    for (final entry in collections.entries)
      if (entry.value.contains(lineupId)) entry.key,
  ];

  LineupCollections toggleFavorite(String lineupId) {
    final updated = {...favorites};
    if (!updated.remove(lineupId)) updated.add(lineupId);
    return LineupCollections(favorites: updated, collections: collections);
  }

  /// Creates [name] if needed; a blank name changes nothing.
  LineupCollections create(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || collections.containsKey(trimmed)) return this;
    return LineupCollections(favorites: favorites, collections: {...collections, trimmed: const []});
  }

  LineupCollections delete(String name) {
    return LineupCollections(favorites: favorites, collections: {...collections}..remove(name));
  }

  /// Adds the spot to [name], creating the collection on the way.
  LineupCollections toggleIn(String name, String lineupId) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return this;
    final ids = [...?collections[trimmed]];
    if (!ids.remove(lineupId)) ids.add(lineupId);
    return LineupCollections(favorites: favorites, collections: {...collections, trimmed: ids});
  }

  Map<String, dynamic> collectionsToJson() => {for (final entry in collections.entries) entry.key: entry.value};
}
