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
  });

  factory PlayerAccount.fromJson(Map<String, dynamic> json) {
    final card = json['card'];
    final cardImages = card is Map<String, dynamic> ? card : const <String, dynamic>{};

    return PlayerAccount(
      puuid: json['puuid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
      accountLevel: json['account_level'] as int? ?? 0,
      cardWide: cardImages['wide'] as String?,
      cardSmall: cardImages['small'] as String?,
      title: json['title'] as String?,
    );
  }

  final String puuid;
  final String name;
  final String tag;
  final int accountLevel;
  final String? cardWide;
  final String? cardSmall;
  final String? title;

  String get label => '$name#$tag';
}
