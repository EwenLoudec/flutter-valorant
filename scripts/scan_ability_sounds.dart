// Tous les clips de compétences de playvalorant.com n'ont pas de piste
// audio : environ la moitié sont muets. Ce script les télécharge, garde ceux
// qui ont vraiment du son et écrit assets/data/ability_sounds.json, utilisé
// par la question « quelle compétence entends-tu ? ».
//
//   dart run scripts/scan_ability_sounds.dart
import 'dart:convert';
import 'dart:io';

const _videosPath = 'assets/data/ability_videos.json';
const _soundsPath = 'assets/data/ability_sounds.json';

/// Les boîtes MP4 qui trahissent une piste audio.
bool _looksLikeAudio(String chunk) => chunk.contains('mp4a') || chunk.contains('soun');

Future<bool> _hasAudioTrack(HttpClient client, String url) async {
  final request = await client.getUrl(Uri.parse(url));
  final response = await request.close();

  // On s'arrête dès que le marqueur apparaît : inutile de tout tirer.
  final window = StringBuffer();
  await for (final chunk in response) {
    window.write(latin1.decode(chunk, allowInvalid: true));
    if (_looksLikeAudio(window.toString())) return true;

    // Fenêtre glissante : un marqueur peut tomber à cheval sur deux chunks.
    final text = window.toString();
    if (text.length > 1 << 16) {
      window
        ..clear()
        ..write(text.substring(text.length - 16));
    }
  }
  return false;
}

Future<void> main() async {
  final videos = jsonDecode(File(_videosPath).readAsStringSync()) as Map<String, dynamic>;
  final client = HttpClient();
  final sounds = <String, Map<String, String>>{};

  var total = 0;
  var kept = 0;

  for (final agent in videos.entries) {
    final clips = agent.value as Map<String, dynamic>;

    for (final clip in clips.entries) {
      total++;
      final url = clip.value as String;

      try {
        if (!await _hasAudioTrack(client, url)) continue;
      } on Object catch (error) {
        stderr.writeln('${clip.key} : $error');
        continue;
      }

      kept++;
      sounds.putIfAbsent(agent.key, () => {})[clip.key] = url;
      stdout.writeln('son  ${clip.key}');
    }
  }

  client.close();
  File(_soundsPath).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(sounds)}\n');

  stdout.writeln('--- $kept clips sonores sur $total, ${sounds.length} agents');
}
