import '../../encyclopedia/domain/agent.dart';
import '../../encyclopedia/domain/contract.dart';
import '../../encyclopedia/domain/cosmetic.dart';
import '../../encyclopedia/domain/store_content.dart';

/// What a contract reward actually is, once looked up in the catalogues.
class ResolvedReward {
  const ResolvedReward({required this.name, required this.imageUrl});

  final String name;
  final String? imageUrl;
}

/// Turns the bare uuids of contract rewards into names and pictures. Every
/// source is optional: a catalogue that failed to load only costs its own
/// rewards their name.
class RewardCatalog {
  RewardCatalog({
    List<Cosmetic> cards = const [],
    List<Cosmetic> sprays = const [],
    List<Cosmetic> buddies = const [],
    List<Cosmetic> titles = const [],
    List<Currency> currencies = const [],
    this.skinLevels = const {},
    List<Agent> agents = const [],
  }) : _cards = {for (final card in cards) card.uuid: card},
       _sprays = {
         for (final spray in sprays) ...{
           spray.uuid: spray,
           for (final level in spray.levelUuids) level: spray,
         },
       },
       _buddyLevels = {
         for (final buddy in buddies) ...{
           buddy.uuid: buddy,
           for (final level in buddy.levelUuids) level: buddy,
         },
       },
       _titles = {for (final title in titles) title.uuid: title},
       _currencies = {for (final currency in currencies) currency.uuid: currency},
       _agents = {for (final agent in agents) agent.uuid: agent};

  final Map<String, Cosmetic> _cards;
  final Map<String, Cosmetic> _sprays;
  final Map<String, Cosmetic> _buddyLevels;
  final Map<String, Cosmetic> _titles;
  final Map<String, Currency> _currencies;
  final Map<String, SkinLevelInfo> skinLevels;
  final Map<String, Agent> _agents;

  Agent? agent(String? uuid) => uuid == null ? null : _agents[uuid];

  ResolvedReward resolve(ContractReward reward) {
    final fallback = ResolvedReward(name: reward.type.label, imageUrl: null);

    switch (reward.type) {
      case RewardType.card:
        final card = _cards[reward.uuid];
        return card == null ? fallback : ResolvedReward(name: card.displayName, imageUrl: card.imageUrl);
      case RewardType.spray:
        final spray = _sprays[reward.uuid];
        return spray == null ? fallback : ResolvedReward(name: spray.displayName, imageUrl: spray.imageUrl);
      case RewardType.buddyLevel:
        final buddy = _buddyLevels[reward.uuid];
        return buddy == null ? fallback : ResolvedReward(name: buddy.displayName, imageUrl: buddy.imageUrl);
      case RewardType.title:
        final title = _titles[reward.uuid];
        return title == null
            ? fallback
            : ResolvedReward(name: 'Titre « ${title.titleText ?? title.displayName} »', imageUrl: null);
      case RewardType.currency:
        final currency = _currencies[reward.uuid];
        if (currency == null) return fallback;
        return ResolvedReward(
          name: reward.amount > 1 ? '${reward.amount} × ${currency.displayName}' : currency.displayName,
          imageUrl: currency.displayIcon,
        );
      case RewardType.skinLevel:
        final skin = skinLevels[reward.uuid];
        return skin == null ? fallback : ResolvedReward(name: skin.displayName, imageUrl: skin.displayIcon);
      case RewardType.agent:
        final agent = _agents[reward.uuid];
        return agent == null
            ? fallback
            : ResolvedReward(name: 'Agent ${agent.displayName}', imageUrl: agent.displayIcon);
      case RewardType.other:
        return fallback;
    }
  }
}
