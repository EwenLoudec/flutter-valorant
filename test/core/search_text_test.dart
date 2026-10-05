import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_companion/core/text/search_text.dart';

void main() {
  test('ignores case, accents and non-breaking spaces', () {
    expect(foldForSearch('Phantom (Champions 2026)'), 'phantom (champions 2026)');
    expect(foldForSearch('  Zèbre   Été  Œuvre '), 'zebre ete oeuvre');
  });

  test('every word of the search must appear, in any field', () {
    expect(matchesSearch('champions 2026', ['Phantom (Champions 2026)']), isTrue);
    expect(matchesSearch('zebre vandal', ['Vandal (Zèbre)']), isTrue);
    expect(matchesSearch('phantom ultra', ['Phantom (Aube)', 'Ultra']), isTrue);
    expect(matchesSearch('phantom select', ['Phantom (Aube)', 'Ultra']), isFalse);
    expect(matchesSearch('', ['quoi que ce soit']), isTrue);
    expect(matchesSearch('a', [null]), isFalse);
  });
}
