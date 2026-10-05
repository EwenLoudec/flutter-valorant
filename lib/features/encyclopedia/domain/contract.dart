/// What a contract is attached to.
enum ContractKind {
  agent('Agents'),
  event('Événements'),
  season('Passes de combat');

  const ContractKind(this.label);

  final String label;

  static ContractKind? fromRelation(String? relationType) => switch (relationType) {
    'Agent' => ContractKind.agent,
    'Event' => ContractKind.event,
    'Season' => ContractKind.season,
    _ => null,
  };
}

/// The kinds of rewards a contract hands out, as valorant-api.com names them.
enum RewardType {
  skinLevel('EquippableSkinLevel', 'Skin'),
  buddyLevel('EquippableCharmLevel', 'Porte-bonheur'),
  card('PlayerCard', 'Carte'),
  spray('Spray', 'Graffiti'),
  title('Title', 'Titre'),
  currency('Currency', 'Monnaie'),
  agent('Character', 'Agent'),
  other('', 'Récompense');

  const RewardType(this.code, this.label);

  static RewardType fromCode(String? code) {
    for (final type in RewardType.values) {
      if (type.code == code) return type;
    }
    return RewardType.other;
  }

  final String code;
  final String label;
}

class ContractReward {
  const ContractReward({
    required this.type,
    required this.uuid,
    required this.amount,
    required this.isHighlighted,
    required this.isFree,
    this.xp = 0,
    this.level,
  });

  factory ContractReward.fromJson(Map<String, dynamic> json, {required bool isFree, int xp = 0, int? level}) {
    return ContractReward(
      type: RewardType.fromCode(json['type'] as String?),
      uuid: json['uuid'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 1,
      isHighlighted: json['isHighlighted'] as bool? ?? false,
      isFree: isFree,
      xp: xp,
      level: level,
    );
  }

  final RewardType type;
  final String uuid;
  final int amount;
  final bool isHighlighted;

  /// Free rewards come with the chapter, without buying the pass.
  final bool isFree;

  /// XP needed to unlock it, for the levels.
  final int xp;

  /// 1-based position across the whole contract, for the levels.
  final int? level;
}

/// An agent's gear contract, an event pass or a season's battle pass.
class Contract {
  const Contract({
    required this.uuid,
    required this.displayName,
    required this.kind,
    required this.relationUuid,
    required this.rewards,
  });

  static Contract? fromJson(Map<String, dynamic> json) {
    final content = json['content'];
    if (content is! Map<String, dynamic>) return null;
    final kind = ContractKind.fromRelation(content['relationType'] as String?);
    if (kind == null) return null;

    final rewards = <ContractReward>[];
    var level = 0;
    for (final chapter in content['chapters'] as List<dynamic>? ?? const []) {
      if (chapter is! Map<String, dynamic>) continue;
      for (final entry in chapter['levels'] as List<dynamic>? ?? const []) {
        if (entry is! Map<String, dynamic>) continue;
        final reward = entry['reward'];
        if (reward is! Map<String, dynamic>) continue;
        level++;
        rewards.add(
          ContractReward.fromJson(reward, isFree: false, xp: (entry['xp'] as num?)?.toInt() ?? 0, level: level),
        );
      }
      for (final reward in chapter['freeRewards'] as List<dynamic>? ?? const []) {
        if (reward is Map<String, dynamic>) rewards.add(ContractReward.fromJson(reward, isFree: true));
      }
    }

    return Contract(
      uuid: json['uuid'] as String,
      displayName: json['displayName'] as String? ?? '',
      kind: kind,
      relationUuid: content['relationUuid'] as String?,
      rewards: rewards,
    );
  }

  final String uuid;
  final String displayName;
  final ContractKind kind;

  /// The agent, event or season the contract belongs to.
  final String? relationUuid;
  final List<ContractReward> rewards;

  int get levelCount => rewards.where((reward) => !reward.isFree).length;
  int get totalXp => rewards.fold(0, (sum, reward) => sum + reward.xp);
}
