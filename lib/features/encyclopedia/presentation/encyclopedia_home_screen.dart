import 'package:flutter/material.dart';

import 'agents/agents_tab.dart';

/// The app's home. Only the agents encyclopedia is wired up for now;
/// weapons, maps and ranks tabs will be added back incrementally.
class EncyclopediaHomeScreen extends StatelessWidget {
  const EncyclopediaHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AGENTS')),
      body: const AgentsTab(),
    );
  }
}
