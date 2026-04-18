import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
  primarySwatch: ColorResource.primarySwatch,
  primaryColor: ColorResource.primary,
  disabledColor: const Color(0xFFBABFC4),
  shadowColor: Colors.black.withValues(alpha: 0.03),
  brightness: Brightness.light,
  hintColor: const Color(0xFF9F9F9F),
  cardColor: Colors.white,
  colorScheme: const ColorScheme.light(
    primary: ColorResource.primary,
    tertiary: Color(0xff102F9C),
    tertiaryContainer: Color(0xff8195DB),
    secondary: ColorResource.primaryLight,
  ).copyWith(
    surface: const Color(0xFFF5F6F8),
    error: const Color(0xFFE84D4F),
  ),
  bottomAppBarTheme: const BottomAppBarThemeData(
    surfaceTintColor: Colors.white,
    height: 65,
    padding: EdgeInsets.symmetric(vertical: 5),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: const Color(0xFFAFAFAF)),
  ),
);

ThemeData darkTheme = ThemeData(
  primarySwatch: ColorResource.primarySwatch,
  primaryColor: ColorResource.primary,
  disabledColor: const Color(0xFFBABFC4),
  shadowColor: Colors.white.withValues(alpha: 0.03),
  brightness: Brightness.dark,
  hintColor: const Color(0xFF9F9F9F),
  cardColor: Colors.black,
  colorScheme: const ColorScheme.dark(
    primary: ColorResource.primary,
    secondary: ColorResource.primaryLight,
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: const Color(0xFFAFAFAF)),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(500)),
  ),
  bottomAppBarTheme: const BottomAppBarThemeData(
    surfaceTintColor: Colors.black,
    height: 65,
    padding: EdgeInsets.symmetric(vertical: 5),
  ),
  dividerTheme: DividerThemeData(
    color: const Color(0xffa2a7ad).withValues(alpha: 0.25),
    thickness: 0.5,
  ),
);
