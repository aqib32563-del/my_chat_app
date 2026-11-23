import 'package:flutter/material.dart';

final themeNotifier = ValueNotifier<String>('light');

int planRank(String? p) => p == 'vip' ? 2 : (p == 'pro' ? 1 : 0);
int themeRank(String t) => t == 'golden' ? 2 : (t == 'black' ? 1 : 0);

String effectiveTheme(Map<String, dynamic> data) {
  final t = '${data['theme'] ?? 'light'}';
  return planRank(data['plan'] as String?) >= themeRank(t) ? t : 'light';
}

ThemeData themeFor(String name) {
  switch (name) {
    case 'black':
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF1B8A3A),
        scaffoldBackgroundColor: const Color(0xFF0B141A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F2C34),
          foregroundColor: Colors.white,
        ),
      );
    case 'golden':
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFFFFC107),
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1405),
          foregroundColor: Color(0xFFFFD54F),
        ),
      );
    default:
      return ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1B8A3A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B8A3A),
          foregroundColor: Colors.white,
        ),
      );
  }
}

Color bubbleMine(BuildContext context) {
  switch (themeNotifier.value) {
    case 'black':
      return const Color(0xFF005C4B);
    case 'golden':
      return const Color(0xFF6B5200);
    default:
      return const Color(0xFFCDEFC8);
  }
}

Color bubbleOther(BuildContext context) {
  switch (themeNotifier.value) {
    case 'black':
      return const Color(0xFF202C33);
    case 'golden':
      return const Color(0xFF262626);
    default:
      return Colors.grey.shade200;
  }
}
