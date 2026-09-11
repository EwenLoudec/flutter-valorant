import 'package:flutter_test/flutter_test.dart';
import 'package:mybmw/features/encyclopedia/data/ability_video_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AbilityVideoRepository', () {
    test('parses the bundled clips, BOM or not', () async {
      final videosByAgent = await AbilityVideoRepository().getVideosByAgent();

      expect(videosByAgent.length, greaterThanOrEqualTo(25));

      for (final entry in videosByAgent.entries) {
        expect(entry.key.length, 36, reason: '${entry.key} n\'est pas un uuid d\'agent');
        expect(entry.value, isNotEmpty, reason: '${entry.key} sans clip');

        for (final ability in entry.value.entries) {
          expect(
            ability.key,
            ability.key.toUpperCase(),
            reason: 'la clé "${ability.key}" doit être en majuscules, comme la recherche de l\'écran agent',
          );
          expect(ability.value, startsWith('https://'), reason: '${ability.key} : url invalide');
        }
      }
    });
  });
}
