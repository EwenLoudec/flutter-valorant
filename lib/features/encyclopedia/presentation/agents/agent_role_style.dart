import 'package:flutter/material.dart';

class AgentRoleStyle {
  const AgentRoleStyle({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  static AgentRoleStyle of(String roleName) {
    switch (roleName) {
      case 'Duelliste':
        return const AgentRoleStyle(color: Color(0xFFFF4655), icon: Icons.bolt);
      case 'Initiateur':
        return const AgentRoleStyle(color: Color(0xFFF2B90C), icon: Icons.radar);
      case 'Sentinelle':
        return const AgentRoleStyle(color: Color(0xFF39E6E0), icon: Icons.shield);
      case 'Contrôleur':
        return const AgentRoleStyle(color: Color(0xFFB667F1), icon: Icons.blur_on);
      default:
        return const AgentRoleStyle(color: Colors.white70, icon: Icons.person);
    }
  }
}
