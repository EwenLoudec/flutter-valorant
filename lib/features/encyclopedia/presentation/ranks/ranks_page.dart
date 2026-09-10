import 'package:flutter/material.dart';

import 'ranks_tab.dart';

class RanksPage extends StatelessWidget {
  const RanksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RANGS')),
      body: const RanksTab(),
    );
  }
}
