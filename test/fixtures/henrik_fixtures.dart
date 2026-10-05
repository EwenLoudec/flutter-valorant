/// The puuid of the profile owner in [v4CompetitiveMatch].
const fixturePuuid = 'me';
const _puuid = fixturePuuid;

Map<String, dynamic> _player(String puuid, String team, {int score = 3000, String agent = 'Jett'}) => {
  'puuid': puuid,
  'name': 'Joueur $puuid',
  'tag': 'EUW',
  'team_id': team,
  'agent': {'id': '$agent-id', 'name': agent},
  'tier': {'id': 18, 'name': 'Diamond 1'},
  'stats': {
    'kills': 10,
    'deaths': 8,
    'assists': 3,
    'score': score,
    'headshots': 5,
    'bodyshots': 15,
    'legshots': 0,
    'damage': {'dealt': 2600, 'received': 2000},
  },
};

Map<String, dynamic> _roundStats(String puuid, String team, int loadout, {String weapon = 'Vandal', int head = 1}) => {
  'player': {'puuid': puuid, 'name': 'Joueur $puuid', 'tag': 'EUW', 'team': team},
  'economy': {
    'loadout_value': loadout,
    'remaining': 200,
    'weapon': {'id': 'w', 'name': weapon, 'type': 'Weapon'},
  },
  'stats': {'headshots': head, 'bodyshots': 2, 'legshots': 0, 'kills': 1, 'score': 200},
};

Map<String, dynamic> _round({
  required String winner,
  required int ownLoadout,
  required int enemyLoadout,
  String result = 'Elimination',
  String? planterTeam,
}) => {
  'id': 0,
  'result': result,
  'ceremony': 'CeremonyDefault',
  'winning_team': winner,
  'plant': planterTeam == null
      ? null
      : {
          'site': 'A',
          'round_time_in_ms': 40000,
          'location': {'x': 1, 'y': 1},
          'player': {'puuid': 'x', 'name': 'x', 'tag': 'x', 'team': planterTeam},
          'player_locations': [],
        },
  'defuse': null,
  'stats': [_roundStats(_puuid, 'Blue', ownLoadout), _roundStats('enemy', 'Red', enemyLoadout)],
};

/// A competitive match in the v4 shape: rounds list their players under
/// `stats`, with the player under `player`.
Map<String, dynamic> v4CompetitiveMatch() => {
  'metadata': {
    'match_id': 'match-1',
    'map': {'id': 'MAP-UUID', 'name': 'Ascent'},
    'queue': {'id': 'competitive', 'name': 'Competitive', 'mode_type': 'Standard'},
    'started_at': '2026-10-01T20:00:00.000Z',
    'game_length_in_ms': 2100000,
  },
  'players': [
    _player(_puuid, 'Blue', score: 4800),
    _player('mate', 'Blue', score: 2000, agent: 'Sova'),
    _player('enemy', 'Red', score: 3900, agent: 'Omen'),
  ],
  'teams': [
    {
      'team_id': 'Blue',
      'won': true,
      'rounds': {'won': 13, 'lost': 11},
    },
    {
      'team_id': 'Red',
      'won': false,
      'rounds': {'won': 11, 'lost': 13},
    },
  ],
  'rounds': [
    // Round 1: red plants, so red attacks the first half.
    _round(winner: 'Red', ownLoadout: 800, enemyLoadout: 800, result: 'Bomb detonated', planterTeam: 'Red'),
    _round(winner: 'Blue', ownLoadout: 1000, enemyLoadout: 3000),
    _round(winner: 'Blue', ownLoadout: 4200, enemyLoadout: 1200, result: 'Bomb defused', planterTeam: 'Red'),
    for (var index = 3; index < 12; index++) _round(winner: 'Blue', ownLoadout: 4000, enemyLoadout: 4000),
    // Round 13: second half, blue attacks.
    _round(winner: 'Red', ownLoadout: 800, enemyLoadout: 800),
    for (var index = 13; index < 24; index++) _round(winner: 'Red', ownLoadout: 4100, enemyLoadout: 4100),
  ],
  'kills': [
    {
      'round': 0,
      'time_in_round_in_ms': 12000,
      'killer': {'puuid': _puuid, 'name': 'Joueur me', 'tag': 'EUW', 'team': 'Blue'},
      'victim': {'puuid': 'enemy', 'name': 'Joueur enemy', 'tag': 'EUW', 'team': 'Red'},
      'location': {'x': 1200, 'y': -3400},
      'weapon': {'id': 'w', 'name': 'Sheriff', 'type': 'Weapon'},
      'assistants': [],
      'player_locations': [],
    },
    {
      'round': 1,
      'killer': {'puuid': 'enemy', 'name': 'Joueur enemy', 'tag': 'EUW', 'team': 'Red'},
      'victim': {'puuid': _puuid, 'name': 'Joueur me', 'tag': 'EUW', 'team': 'Blue'},
      'location': {'x': 100, 'y': 200},
      'weapon': {'name': 'Vandal'},
    },
  ],
};

/// The v2 featured store, as HenrikDev serves it: one bundle on sale.
List<Map<String, dynamic>> featuredStoreFixture() => [
  {
    'bundle_uuid': 'bundle-1',
    'bundle_price': 4615,
    'whole_sale_only': false,
    'expires_at': '2099-10-21T05:01:26.082Z',
    'seconds_remaining': 1355427,
    'items': [
      {
        'uuid': 'skin-1',
        'name': 'Champions Phantom',
        'image': 'https://img/skin-1.png',
        'type': 'skin_level',
        'amount': 1,
        'discount_percent': 0.34,
        'base_price': 5350,
        'discounted_price': 3531,
        'promo_item': false,
      },
      {
        'uuid': 'card-1',
        'name': 'Champions Dragon Card',
        'image': 'https://img/card-1.png',
        'type': 'player_card',
        'amount': 1,
        'discount_percent': 0.3,
        'base_price': 375,
        'discounted_price': 263,
        'promo_item': false,
      },
      {
        'uuid': 'buddy-1',
        'name': 'Champions Buddy',
        'image': null,
        'type': 'buddy',
        'amount': 2,
        'discount_percent': 0,
        'base_price': 475,
        'discounted_price': 475,
        'promo_item': false,
      },
      {'name': 'sans uuid'},
    ],
  },
  {'bundle_uuid': ''},
];

Map<String, dynamic> _storedMatch(
  String id, {
  required String map,
  required String agent,
  required int us,
  required int them,
  String season = 'act-now',
  String team = 'Red',
  int kills = 20,
  int deaths = 15,
  int tier = 15,
}) => {
  'meta': {
    'id': id,
    'map': {'id': 'map-$map', 'name': map},
    'mode': 'Competitive',
    'started_at': '2026-09-28T19:47:39.774Z',
    'season': {'id': season, 'short': season == 'act-now' ? 'e11a5' : 'e11a4'},
  },
  'stats': {
    'team': team,
    'character': {'id': 'agent-$agent', 'name': agent},
    'tier': tier,
    'score': 5000,
    'kills': kills,
    'deaths': deaths,
    'assists': 4,
    'shots': {'head': 20, 'body': 70, 'leg': 10},
    'damage': {'made': 3000, 'received': 2800},
  },
  'teams': team == 'Red' ? {'red': us, 'blue': them} : {'red': them, 'blue': us},
};

/// The v1 stored matches of one act, newest first, and one game of the
/// previous act that must not be counted.
List<Map<String, dynamic>> storedMatchesFixture() => [
  _storedMatch('s1', map: 'Ascent', agent: 'Jett', us: 13, them: 7, tier: 16),
  _storedMatch('s2', map: 'Ascent', agent: 'Jett', us: 9, them: 13, team: 'Blue'),
  _storedMatch('s3', map: 'Haven', agent: 'Omen', us: 13, them: 11, kills: 10, deaths: 20),
  _storedMatch('s4', map: 'Ascent', agent: 'Jett', us: 12, them: 12),
  _storedMatch('old', map: 'Split', agent: 'Raze', us: 13, them: 0, season: 'act-before', tier: 20),
  {'meta': {}},
];
