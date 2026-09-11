import 'package:flutter_test/flutter_test.dart';
import 'package:mybmw/features/profile/domain/player_match.dart';
import 'package:mybmw/features/profile/domain/weapon_accuracy.dart';

const _puuid = 'player-1';

/// Shape returned by the v4 match list: players as a list, teams as a list,
/// and per-round shot counts under `stats`.
Map<String, dynamic> _v4Match() => {
  'metadata': {
    'match_id': 'match-v4',
    'map': {'id': 'ascent-id', 'name': 'Ascent'},
    'queue': {'id': 'competitive', 'name': 'Compétitif'},
    'started_at': '2026-09-08T20:15:00.000Z',
  },
  'players': [
    {
      'puuid': _puuid,
      'name': 'Ewen',
      'tag': '0000',
      'team_id': 'Red',
      'agent': {'id': 'jett-id', 'name': 'Jett'},
      'stats': {'kills': 21, 'deaths': 12, 'assists': 4, 'score': 5400},
    },
    {
      'puuid': 'player-2',
      'team_id': 'Blue',
      'agent': {'name': 'Sova'},
      'stats': {'kills': 8, 'deaths': 17, 'assists': 2, 'score': 2100},
    },
  ],
  'teams': [
    {
      'team_id': 'Red',
      'won': true,
      'rounds': {'won': 13, 'lost': 7},
    },
    {
      'team_id': 'Blue',
      'won': false,
      'rounds': {'won': 7, 'lost': 13},
    },
  ],
  'rounds': [
    {
      'player_stats': [
        {
          'puuid': _puuid,
          'economy': {
            'weapon': {'name': 'Vandal'},
          },
          'stats': {'headshots': 2, 'bodyshots': 1, 'legshots': 0},
        },
        {
          'puuid': 'player-2',
          'economy': {
            'weapon': {'name': 'Phantom'},
          },
          'stats': {'headshots': 5, 'bodyshots': 5, 'legshots': 5},
        },
      ],
    },
    {
      'player_stats': [
        {
          'puuid': _puuid,
          'economy': {
            'weapon': {'name': 'Vandal'},
          },
          'stats': {'headshots': 1, 'bodyshots': 3, 'legshots': 1},
        },
        {
          'puuid': _puuid,
          'economy': {
            'weapon': {'name': 'Classic'},
          },
          'stats': {'headshots': 0, 'bodyshots': 0, 'legshots': 0},
        },
      ],
    },
  ],
};

/// Shape returned by the older v2 endpoint, still accepted by the parser.
Map<String, dynamic> _v2Match() => {
  'metadata': {
    'matchid': 'match-v2',
    'map': 'Bind',
    'mode': 'Compétitif',
    'game_start': 1757000000,
  },
  'players': {
    'all_players': [
      {
        'puuid': _puuid,
        'team': 'Blue',
        'character': 'Reyna',
        'stats': {'kills': 9, 'deaths': 15, 'assists': 1, 'score': 2600},
      },
    ],
  },
  'teams': {
    'blue': {'has_won': false, 'rounds_won': 6, 'rounds_lost': 13},
    'red': {'has_won': true, 'rounds_won': 13, 'rounds_lost': 6},
  },
  'rounds': [
    {
      'player_stats': [
        {
          'player': {'puuid': _puuid},
          'economy': {
            'weapon': {'name': 'Sheriff'},
          },
          'damage_events': [
            {'headshots': 1, 'bodyshots': 0, 'legshots': 0},
            {'headshots': 0, 'bodyshots': 2, 'legshots': 1},
          ],
        },
      ],
    },
  ],
};

void main() {
  group('PlayerMatch.fromJson', () {
    test('reads the v4 payload of the requested player', () {
      final match = PlayerMatch.fromJson(_v4Match(), puuid: _puuid);

      expect(match.matchId, 'match-v4');
      expect(match.mapName, 'Ascent');
      expect(match.mode, 'Compétitif');
      expect(match.agentName, 'Jett');
      expect(match.kills, 21);
      expect(match.deaths, 12);
      expect(match.assists, 4);
      expect(match.roundsWon, 13);
      expect(match.roundsLost, 7);
      expect(match.outcome, MatchOutcome.win);
      expect(match.startedAt?.toUtc().hour, 20);
    });

    test('splits the shots per weapon, ignoring the other players', () {
      final match = PlayerMatch.fromJson(_v4Match(), puuid: _puuid);
      final weapons = {for (final shots in match.shotsByWeapon) shots.weaponName: shots};

      expect(weapons.keys, ['Vandal']);
      expect(weapons['Vandal']?.headshots, 3);
      expect(weapons['Vandal']?.bodyshots, 4);
      expect(weapons['Vandal']?.legshots, 1);
      expect(match.headshotPercent, closeTo(37.5, 0.01));
    });

    test('falls back to the v2 field names', () {
      final match = PlayerMatch.fromJson(_v2Match(), puuid: _puuid);

      expect(match.matchId, 'match-v2');
      expect(match.mapName, 'Bind');
      expect(match.agentName, 'Reyna');
      expect(match.outcome, MatchOutcome.loss);
      expect(match.roundsWon, 6);
      expect(match.roundsLost, 13);
      expect(match.shotsByWeapon.single.weaponName, 'Sheriff');
      expect(match.shotsByWeapon.single.headshots, 1);
      expect(match.shotsByWeapon.single.bodyshots, 2);
      expect(match.shotsByWeapon.single.legshots, 1);
    });

    test('survives a payload without the player, teams or rounds', () {
      final match = PlayerMatch.fromJson(const {'metadata': {}}, puuid: _puuid);

      expect(match.kills, 0);
      expect(match.outcome, isNull);
      expect(match.shotsByWeapon, isEmpty);
      expect(match.headshotPercent, isNull);
    });
  });

  group('WeaponAccuracy', () {
    test('sums every match, most used weapon first', () {
      final matches = [
        PlayerMatch.fromJson(_v4Match(), puuid: _puuid),
        PlayerMatch.fromJson(_v2Match(), puuid: _puuid),
      ];

      final weapons = WeaponAccuracy.aggregate(matches);

      expect(weapons.map((weapon) => weapon.weaponName), ['Vandal', 'Sheriff']);
      expect(weapons.first.total, 8);
      expect(weapons.first.matchCount, 1);
      expect(weapons.first.headshotPercent, closeTo(37.5, 0.01));
    });

    test('merges the weapons into a single overall figure', () {
      final matches = [PlayerMatch.fromJson(_v4Match(), puuid: _puuid)];
      final overall = WeaponAccuracy.overall(WeaponAccuracy.aggregate(matches));

      expect(overall?.headshots, 3);
      expect(overall?.total, 8);
      expect(WeaponAccuracy.overall(const []), isNull);
    });
  });
}
