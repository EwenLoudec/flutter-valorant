const _accents = {
  'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a', 'å': 'a', 'ç': 'c', 'é': 'e', 'è': 'e', 'ê': 'e', //
  'ë': 'e', 'í': 'i', 'î': 'i', 'ï': 'i', 'ñ': 'n', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ú': 'u', //
  'ù': 'u', 'û': 'u', 'ü': 'u', 'ÿ': 'y', 'œ': 'oe', 'æ': 'ae',
};

/// [text] the way searches compare it: lower case, without accents, and with
/// the non-breaking spaces of the French catalogue ("Champions 2026") turned
/// into plain ones, so what the player types always finds it.
String foldForSearch(String text) {
  final lower = text.toLowerCase().replaceAll(RegExp('[   ]'), ' ');
  final plain = StringBuffer();
  for (final letter in lower.split('')) {
    plain.write(_accents[letter] ?? letter);
  }
  return plain.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Whether every word of [search] appears in one of [fields]. An empty
/// search matches everything.
bool matchesSearch(String search, Iterable<String?> fields) {
  final words = foldForSearch(search).split(' ').where((word) => word.isNotEmpty);
  if (words.isEmpty) return true;
  final haystack = foldForSearch(fields.whereType<String>().join(' '));
  return words.every(haystack.contains);
}
