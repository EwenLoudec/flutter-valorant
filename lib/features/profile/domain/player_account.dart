/// Public identity of a Valorant account, from the HenrikDev account endpoint.
class PlayerAccount {
  const PlayerAccount({
    required this.puuid,
    required this.name,
    required this.tag,
    required this.accountLevel,
    required this.cardWide,
    required this.cardSmall,
    required this.title,
    this.cardUuid,
  });

  /// v1 of the endpoint sends the card's pictures, v2 only its uuid and the
  /// title's uuid: both are read.
  factory PlayerAccount.fromJson(Map<String, dynamic> json) {
    final card = json['card'];
    final cardImages = card is Map<String, dynamic> ? card : const <String, dynamic>{};
    final cardUuid = card is String && card.isNotEmpty ? card : cardImages['id'] as String?;
    final title = json['title'];

    return PlayerAccount(
      puuid: json['puuid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
      accountLevel: (json['account_level'] as num?)?.toInt() ?? 0,
      cardWide: cardImages['wide'] as String? ?? _cardArt(cardUuid, 'wideart'),
      cardSmall: cardImages['small'] as String? ?? _cardArt(cardUuid, 'smallart'),
      title: title is String && title.isNotEmpty ? title : null,
      cardUuid: cardUuid,
    );
  }

  static String? _cardArt(String? uuid, String art) =>
      uuid == null ? null : 'https://media.valorant-api.com/playercards/$uuid/$art.png';

  final String puuid;
  final String name;
  final String tag;
  final int accountLevel;
  final String? cardWide;
  final String? cardSmall;

  /// The equipped title: its uuid with v2, which the title catalogue turns
  /// into text.
  final String? title;
  final String? cardUuid;

  String get label => '$name#$tag';
}
