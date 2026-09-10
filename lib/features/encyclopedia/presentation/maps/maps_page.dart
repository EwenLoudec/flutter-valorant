import 'package:flutter/material.dart';

import 'maps_tab.dart';

class MapsPage extends StatelessWidget {
  const MapsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MAPS')),
      body: const MapsTab(),
    );
  }
}
