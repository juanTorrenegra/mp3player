import 'package:flutter/material.dart';

class AppThemes {
  static final futuristic = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Color(0xFF00FFCC), // neon cyan
    secondaryHeaderColor: Color(0xFF4444FF), // deep purple-blue
    fontFamily: 'Orbitron',
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontFamily: 'Orbitron'),
      bodyMedium: TextStyle(fontFamily: 'Orbitron'),
    ),
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Color(0xFF00FFCC),
    ),
  );

  static final retroXP = ThemeData(
    brightness: Brightness.light,
    primaryColor: Color(0xFF0033CC), // classic XP blue
    secondaryHeaderColor: Color(0xFFCCCCCC), // light gray
    fontFamily: 'SegoeUI', // or another retro-looking font
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontFamily: 'SegoeUI'),
      bodyMedium: TextStyle(fontFamily: 'SegoeUI'),
    ),
    scaffoldBackgroundColor: Color(0xFFEFEFEF),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFCCCCCC),
      foregroundColor: Color(0xFF0033CC),
    ),
  );
}
