import 'package:flutter/material.dart';

class ColorResource {
  // Primary Brand Colors
  static const Color appBarColor = Color(0xFF003B55);
  static const Color primaryDark = Color(0xFF003B55);
  static const Color primaryMedium = Color(0xFF006B8F);
  static const Color primaryLight = Color(0xFF0099CC);

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

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF003B55),
      Color(0xFF006B8F),
      Color(0xFF0099CC),
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF8F9FA),
    ],
  );

  static const List<BoxShadow>?  customShadow = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];
}