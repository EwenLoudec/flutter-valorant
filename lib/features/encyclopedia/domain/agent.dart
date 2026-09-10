class AgentAbility {
  const AgentAbility({required this.slot, required this.displayName, required this.description, this.displayIcon});

  final String slot;
  final String displayName;
  final String description;
  final String? displayIcon;
}

class Agent {
  const Agent({
    required this.uuid,
    required this.displayName,
    required this.description,
    required this.roleName,
    required this.displayIcon,
    required this.fullPortrait,
    required this.backgroundGradientColors,
    required this.abilities,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      uuid: json['uuid'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String? ?? '',
      roleName: (json['role'] as Map<String, dynamic>?)?['displayName'] as String? ?? 'Inconnu',
      displayIcon: json['displayIcon'] as String?,
      fullPortrait: json['fullPortrait'] as String? ?? json['bustPortrait'] as String?,
      backgroundGradientColors: (json['backgroundGradientColors'] as List<dynamic>? ?? [])
          .map((c) => c as String)
          .toList(),
      abilities: (json['abilities'] as List<dynamic>? ?? [])
          .map((a) => a as Map<String, dynamic>)
          .where((a) => (a['displayName'] as String?)?.isNotEmpty ?? false)
          .map(
            (a) => AgentAbility(
              slot: a['slot'] as String? ?? '',
              displayName: a['displayName'] as String,
              description: a['description'] as String? ?? '',
              displayIcon: a['displayIcon'] as String?,
            ),
          )
          .toList(),
    );
  }

  final String uuid;
  final String displayName;
  final String description;
  final String roleName;
  final String? displayIcon;
  final String? fullPortrait;
  final List<String> backgroundGradientColors;
  final List<AgentAbility> abilities;
}
