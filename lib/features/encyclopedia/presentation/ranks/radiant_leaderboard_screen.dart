import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Placeholder until a player-data source (Riot API key or HenrikDev key) is
/// configured — valorant-api.com only has static game data, no live players.
class RadiantLeaderboardScreen extends StatelessWidget {
  const RadiantLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CLASSEMENT RADIANT')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.leaderboard_outlined, size: 48, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'Classement bientôt disponible',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Les vrais joueurs et leurs points nécessitent une clé API '
              '(Riot ou HenrikDev) — valorant-api.com ne fournit que des données de jeu statiques.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
      backgroundColor: AppTheme.valorantDark,
    );
  }
}
