import 'package:flutter/material.dart';

import 'weapons_tab.dart';

class WeaponsPage extends StatelessWidget {
  const WeaponsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ARMES')),
      body: const WeaponsTab(),
    );
  }
}
