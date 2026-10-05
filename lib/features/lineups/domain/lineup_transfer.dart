import 'dart:convert';

import '../../../core/text/search_text.dart';
import 'lineup.dart';

/// Why an import was refused, in words for the player.
class LineupImportException implements Exception {
  const LineupImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// What came out of an import.
class LineupImportResult {
  const LineupImportResult({required this.lineups, required this.skipped});

  final List<Lineup> lineups;

  /// Entries that could not be read.
  final int skipped;
}

/// Turns spots into a text that can be pasted to a teammate, and back.
///
/// Pictures and clips stay out: they are files on the sender's device. The
/// pinned video link, being a URL, travels with the spot.
abstract final class LineupTransfer {
  static const format = 'valorant-companion-lineups';
  static const version = 1;

  static String export(List<Lineup> lineups) {
    return const JsonEncoder.withIndent('  ').convert({
      'format': format,
      'version': version,
      'lineups': [
        for (final lineup in lineups) {...lineup.toJson()}..remove('media'),
      ],
    });
  }

  /// Reads an export. Every spot comes back as the player's own, under a
  /// fresh id when [existingIds] already has it, so nothing gets overwritten.
  static LineupImportResult import(String raw, {required Set<String> existingIds, DateTime? now}) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw.trim());
    } on FormatException {
      throw const LineupImportException('Ce texte n\'est pas un export de lineups (JSON illisible).');
    }

    final List<dynamic> entries;
    if (decoded is Map<String, dynamic> && decoded['lineups'] is List<dynamic>) {
      if (decoded['format'] != null && decoded['format'] != format) {
        throw const LineupImportException('Ce texte vient d\'une autre application.');
      }
      entries = decoded['lineups'] as List<dynamic>;
    } else if (decoded is List<dynamic>) {
      entries = decoded;
    } else {
      throw const LineupImportException('Aucune lineup trouvée dans ce texte.');
    }

    final stamp = (now ?? DateTime.now()).microsecondsSinceEpoch;
    final taken = {...existingIds};
    final lineups = <Lineup>[];
    var skipped = 0;

    for (final (index, entry) in entries.indexed) {
      if (entry is! Map<String, dynamic> || entry['map'] is! String || entry['agent'] is! String) {
        skipped++;
        continue;
      }

      final Lineup parsed;
      try {
        parsed = Lineup.fromJson({...entry, 'id': entry['id'] ?? 'import-$stamp-$index'}, isBundled: false);
      } on Object {
        skipped++;
        continue;
      }

      var id = parsed.id;
      if (taken.contains(id)) id = 'import-$stamp-$index';
      taken.add(id);
      lineups.add(parsed.copyWith(id: id, media: const [], isBundled: false));
    }

    if (lineups.isEmpty) {
      throw LineupImportException(
        skipped == 0 ? 'Aucune lineup trouvée dans ce texte.' : 'Aucune des $skipped lineups n\'a pu être lue.',
      );
    }
    return LineupImportResult(lineups: lineups, skipped: skipped);
  }
}

/// Text search over the spots of every map.
extension LineupSearch on Lineup {
  bool matches(String search) => matchesSearch(search, [
    title,
    agentName,
    mapName,
    abilityName,
    abilityKey,
    from.label,
    to?.label,
    side.label,
    description,
  ]);
}
