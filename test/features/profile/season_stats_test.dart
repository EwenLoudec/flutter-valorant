import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_companion/features/profile/domain/stored_match.dart';

import '../../fixtures/henrik_fixtures.dart';

void main() {
  final matches = StoredMatch.listFromJson(storedMatchesFixture());

  test('reads the light history and skips the broken entries', () {
    expect(matches.map((match) => match.id), ['s1', 's2', 's3', 's4', 'old']);
    final first = matches.first;
    expect(first.mapName, 'Ascent');
    expect(first.agentName, 'Jett');
    expect(first.seasonId, 'act-now');
    expect(first.isWin, isTrue);
    expect(first.rounds, 20);
  });

  test('the side of the player decides who won', () {
    final blue = matches[1];
    expect(blue.teamRounds, 9);
    expect(blue.enemyRounds, 13);
    expect(blue.isWin, isFalse);
    expect(matches[3].isDraw, isTrue);
  });

  test('sums up the act and leaves the previous one out', () {
    final season = SeasonStats.from(matches, seasonId: 'act-now');
    final totals = season.totals;

    expect(totals.matches, 4);
    expect(totals.record.wins, 2);
    expect(totals.record.losses, 1);
    expect(totals.record.draws, 1);
    expect(totals.rounds, 20 + 22 + 24 + 24);
    expect(totals.kills, 20 + 20 + 10 + 20);
    expect(totals.killDeathRatio, closeTo(70 / 65, 1e-9));
    expect(totals.headshotPercent, closeTo(20, 1e-9));
    expect(totals.averageDamage, closeTo(12000 / 90, 1e-9));
    expect(totals.averageCombatScore, closeTo(20000 / 90, 1e-9));
    expect(season.peakTier, 16, reason: 'le Split de l\'acte précédent, en tier 20, ne compte pas');
    expect(season.seasonLabel, 'Épisode 11 · Acte 5');
  });

  test('per map and per agent, most played first', () {
    final season = SeasonStats.from(matches, seasonId: 'act-now');

    expect(season.maps.map((map) => map.name), ['Ascent', 'Haven']);
    expect(season.maps.first.totals.matches, 3);
    expect(season.maps.first.totals.record.winRate, closeTo(100 / 3, 1e-9));
    expect(season.agents.map((agent) => agent.name), ['Jett', 'Omen']);
    expect(season.agents.first.id, 'agent-Jett');
    expect(season.agents.last.totals.killDeathRatio, 0.5);
  });

  test('without the act, the latest game\'s act is the current one', () {
    expect(SeasonStats.from(matches).totals.matches, 4);
    expect(SeasonStats.from(matches, seasonId: 'act-before').totals.matches, 1);
  });

  test('an account without competitive games has an empty act', () {
    final season = SeasonStats.from(const []);
    expect(season.isEmpty, isTrue);
    expect(season.totals.killDeathRatio, isNull);
    expect(season.maps, isEmpty);
  });
}
