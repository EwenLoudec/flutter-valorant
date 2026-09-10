import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Official Valorant palette.
  static const Color valorantRed = Color(0xFFFF4655);
  static const Color valorantDark = Color(0xFF0F1923);
  static const Color valorantSurface = Color(0xFF1C242C);
  static const Color valorantMuted = Color(0xFF768079);

  static ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: valorantRed,
      brightness: Brightness.dark,
    ).copyWith(
      primary: valorantRed,
      surface: valorantSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: valorantDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: valorantDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: valorantMuted,
        indicatorColor: valorantRed,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: valorantSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      dividerColor: const Color(0xFF2B343C),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }
}
