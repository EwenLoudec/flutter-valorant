import 'dart:convert';

/// A skin the player marked as owned. The picture and the name are kept
/// alongside the uuid so the collection renders without re-downloading the
/// whole skin catalogue.
class OwnedSkin {
  const OwnedSkin({
    required this.uuid,
    required this.displayName,
    required this.weaponName,
    required this.displayIcon,
    required this.contentTierUuid,
  });

  static OwnedSkin? tryParse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;

    final uuid = decoded['uuid'] as String?;
    if (uuid == null) return null;

    return OwnedSkin(
      uuid: uuid,
      displayName: decoded['displayName'] as String? ?? '',
      weaponName: decoded['weaponName'] as String? ?? '',
      displayIcon: decoded['displayIcon'] as String?,
      contentTierUuid: decoded['contentTierUuid'] as String?,
    );
  }

  final String uuid;
  final String displayName;
  final String weaponName;
  final String? displayIcon;
  final String? contentTierUuid;

  String toStorage() => jsonEncode({
    'uuid': uuid,
    'displayName': displayName,
    'weaponName': weaponName,
    'displayIcon': displayIcon,
    'contentTierUuid': contentTierUuid,
  });
}
