import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
  primarySwatch: Colors.blue,
  primaryColor: const Color(0xFF003B55),
  disabledColor: const Color(0xFFBABFC4),
  shadowColor: Colors.black.withValues(alpha: 0.03),
  brightness: Brightness.light,
  hintColor: const Color(0xFF9F9F9F),
  cardColor: Colors.white,
  // colorScheme: const ColorScheme.light(primary: Color(0xFF2C9503), secondary: Color(0xFF272622)),
  colorScheme: const ColorScheme.light(primary: Color(0xFF003B55),
      tertiary: Color(0xff102F9C),
      tertiaryContainer: Color(0xff8195DB),
      secondary: Color(0xFF0099CC)).copyWith(surface: const Color(0xFFF5F6F8)).copyWith(error: const Color(0xFFE84D4F),
  ),
  bottomAppBarTheme: const BottomAppBarThemeData(
    surfaceTintColor: Colors.white, height: 65,
    padding: EdgeInsets.symmetric(vertical: 5),
  ),
  textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: const Color(0xFFAFAFAF))),
);

ThemeData darkTheme = ThemeData(
  primarySwatch: Colors.blue,
  primaryColor: const Color(0xFF2C9503),
  disabledColor: const Color(0xFFBABFC4),
  shadowColor: Colors.white.withValues(alpha: 0.03),
  brightness: Brightness.dark,
  hintColor: const Color(0xFF9F9F9F),
  cardColor: Colors.black,
  colorScheme: const ColorScheme.dark(primary: Color(0xFF2C9503), secondary: Color(0xFF272622)),
  textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: const Color(0xFFAFAFAF))),
  floatingActionButtonTheme: FloatingActionButtonThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(500))),
  bottomAppBarTheme: const BottomAppBarThemeData(
    surfaceTintColor: Colors.black, height: 65,
    padding: EdgeInsets.symmetric(vertical: 5),
  ),
  dividerTheme: DividerThemeData(color: const Color(0xffa2a7ad).withValues(alpha: 0.25), thickness: 0.5),
);