import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/responsive_app_frame.dart';
import 'features/encyclopedia/presentation/encyclopedia_home_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Valorant Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      builder: (context, child) => ResponsiveAppFrame(child: child!),
      home: const EncyclopediaHomeScreen(),
    );
  }
}
