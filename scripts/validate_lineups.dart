// Vérifie assets/data/lineups.json contre les données vivantes de
// valorant-api.com : chaque spot doit viser une carte, un agent, un slot de
// compétence et des callouts qui existent réellement.
//
//   dart run scripts/validate_lineups.dart
import 'dart:convert';
import 'dart:io';

const _mapsUrl = 'https://valorant-api.com/v1/maps?language=fr-FR';
const _agentsUrl = 'https://valorant-api.com/v1/agents?language=fr-FR&isPlayableCharacter=true';

Future<List<dynamic>> _fetch(String url) async {
  final client = HttpClient();
  try {
    final response = await (await client.getUrl(Uri.parse(url))).close();
    final body = await response.transform(utf8.decoder).join();
    return (jsonDecode(body) as Map<String, dynamic>)['data'] as List<dynamic>;
  } finally {
    client.close();
  }
}

Future<void> main() async {
  final maps = await _fetch(_mapsUrl);
  final agents = await _fetch(_agentsUrl);
  final seed =
      jsonDecode(File('assets/data/lineups.json').readAsStringSync()) as Map<String, dynamic>;

  // Carte -> "superRegion|callout" existants.
  final calloutsByMap = <String, Set<String>>{
    for (final entry in maps)
      (entry as Map<String, dynamic>)['displayName'] as String: {
        for (final callout in entry['callouts'] as List<dynamic>? ?? const [])
          '${(callout as Map<String, dynamic>)['superRegionName']}|${callout['regionName']}',
      },
  };

  // Agent -> slot -> nom officiel de la compétence.
  final abilitiesByAgent = <String, Map<String, String>>{
    for (final entry in agents)
      (entry as Map<String, dynamic>)['displayName'] as String: {
        for (final ability in entry['abilities'] as List<dynamic>)
          (ability as Map<String, dynamic>)['slot'] as String: ability['displayName'] as String,
      },
  };

  final lineups = seed['lineups'] as List<dynamic>;
  final problems = <String>[];
  final ids = <String>{};
  final coveredAgents = <String>{};

  for (final entry in lineups) {
    final lineup = entry as Map<String, dynamic>;
    final id = lineup['id'] as String;
    if (!ids.add(id)) problems.add('$id : identifiant en double');

    final mapName = lineup['map'] as String;
    final callouts = calloutsByMap[mapName];
    if (callouts == null) {
      problems.add('$id : carte inconnue "$mapName"');
      continue;
    }

    final agentName = lineup['agent'] as String;
    coveredAgents.add(agentName);
    final abilities = abilitiesByAgent[agentName];
    final slot = lineup['ability'] as String;

    if (abilities == null) {
      problems.add('$id : agent inconnu "$agentName"');
    } else if (abilities[slot] == null) {
      problems.add('$id : $agentName n\'a pas de slot "$slot"');
    } else if (abilities[slot] != lineup['abilityName']) {
      problems.add('$id : compétence "${lineup['abilityName']}" au lieu de "${abilities[slot]}"');
    }

    final demoUrl = lineup['demoUrl'] as String?;
    if (demoUrl == null) {
      problems.add('$id : aucune vidéo de démo');
    } else if (!RegExp(r'^https://www\.youtube\.com/watch\?v=[\w-]{11}$').hasMatch(demoUrl)) {
      problems.add('$id : lien vidéo inattendu "$demoUrl"');
    } else if ((lineup['demoTitle'] as String? ?? '').isEmpty) {
      problems.add('$id : vidéo sans titre');
    }

    for (final key in ['from', 'to']) {
      final anchor = lineup[key];
      if (anchor is! Map<String, dynamic>) continue;
      final name = anchor['callout'];
      if (name == null) continue;

      final lookup = '${anchor['region']}|$name';
      if (!callouts.contains(lookup)) problems.add('$id : callout "$lookup" absent de $mapName');
    }
  }

  final missing = abilitiesByAgent.keys.where((agent) => !coveredAgents.contains(agent));

  stdout.writeln('${lineups.length} spots · ${coveredAgents.length}/${abilitiesByAgent.length} agents couverts');
  if (missing.isNotEmpty) stdout.writeln('agents sans spot : ${missing.join(', ')}');

  if (problems.isEmpty) {
    stdout.writeln('aucune erreur');
    return;
  }
  for (final problem in problems) {
    stdout.writeln('KO $problem');
  }
  exitCode = 1;
}
