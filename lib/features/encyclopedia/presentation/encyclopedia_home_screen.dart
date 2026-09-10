import 'package:flutter/material.dart';

import '../../../core/widgets/valorant_bottom_nav.dart';
import 'agents/agents_page.dart';
import 'maps/maps_page.dart';
import 'weapons/weapons_page.dart';

/// The app's home: a bottom-nav shell switching between the encyclopedia
/// sections. Ranks will be added back as its own tab later.
class EncyclopediaHomeScreen extends StatefulWidget {
  const EncyclopediaHomeScreen({super.key});

  @override
  State<EncyclopediaHomeScreen> createState() => _EncyclopediaHomeScreenState();
}

class _EncyclopediaHomeScreenState extends State<EncyclopediaHomeScreen> {
  int _index = 0;

  static const _pages = [AgentsPage(), WeaponsPage(), MapsPage()];

  static const _items = [
    ValorantNavItem(label: 'AGENTS', icon: Icons.groups_rounded),
    ValorantNavItem(label: 'ARMES', icon: Icons.gps_fixed),
    ValorantNavItem(label: 'MAPS', icon: Icons.map_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: ValorantBottomNav(
        items: _items,
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
      ),
    );
  }
}
