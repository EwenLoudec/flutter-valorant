import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/encyclopedia/presentation/encyclopedia_home_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Valorant Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const EncyclopediaHomeScreen(),
    );
  }
}
