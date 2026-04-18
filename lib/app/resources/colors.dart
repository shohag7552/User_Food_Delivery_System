import 'package:flutter/material.dart';

class ColorResource {
  // Primary Brand Colors
  // static const Color primaryDark = Color(0xFF003B55);
    // static const Color primaryMedium = Color(0xFF006B8F);
  // static const Color primaryLight = Color(0xFF0099CC);
  static const Color primaryDark = Color(0xFFC92A2A);
  static const Color primaryMedium = Color(0xFFC92A2A);
  static const Color primaryLight = Color(0xFFC92A2A);
  static const Color primary = primaryDark;
  static const Color appBarColor = primaryDark;
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primaryMedium, primaryLight],
  );
  static const MaterialColor primarySwatch = MaterialColor(
    0xFF003B55,
    <int, Color>{
      50: Color(0xFFE0EBEF),
      100: Color(0xFFB3C8D3),
      200: Color(0xFF80A1B1),
      300: Color(0xFF4D7A8F),
      400: Color(0xFF265E76),
      500: primaryDark,
      600: Color(0xFF00354E),
      700: Color(0xFF002D44),
      800: Color(0xFF00263B),
      900: Color(0xFF001926),
    },
  );

  // Background Colors
  static const Color scaffoldBackground = Color(0xFFF5F7FA);
  static const Color cardBackground = Colors.white;
  static const Color darkBackground = Color(0xFF1A1A1A);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color textWhite = Colors.white;

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // UI Element Colors
  static const Color ratingStarColor = Color(0xFFFBBF24);
  static const Color favoriteColor = Color(0xFFEF4444);
  static const Color discountBadge = Color(0xFFEF4444);
  static const Color premiumBadge = Color(0xFFFFD700);

  // Shadow Colors
  static Color shadowLight = Colors.black.withValues(alpha: 0.05);
  static Color shadowMedium = Colors.black.withValues(alpha: 0.1);
  static Color shadowDark = Colors.black.withValues(alpha: 0.15);

  // Overlay Colors
  static Color overlayLight = Colors.white.withValues(alpha: 0.1);
  static Color overlayMedium = Colors.white.withValues(alpha: 0.2);
  static Color overlayDark = Colors.black.withValues(alpha: 0.3);

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF8F9FA),
    ],
  );

  static const List<BoxShadow>? customShadow = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];
}
