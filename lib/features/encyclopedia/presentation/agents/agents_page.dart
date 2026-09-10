import 'package:flutter/material.dart';

import 'agents_tab.dart';

class AgentsPage extends StatelessWidget {
  const AgentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AGENTS')),
      body: const AgentsTab(),
    );
  }
}
