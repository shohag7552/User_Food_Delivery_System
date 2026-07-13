import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Theme-dependent color values, defined once so the reactive [AppColorsX]
// extension and the static [ColorResource] fallbacks can never diverge.
const Color _cScaffoldBgDark = Color(0xFF0B1220);
const Color _cScaffoldBgLight = Color(0xFFF5F7FA);
const Color _cCardBgDark = Color(0xFF111827);
const Color _cCardBgLight = Colors.white;
const Color _cTextPrimaryDark = Color(0xFFF8FAFC);
const Color _cTextPrimaryLight = Color(0xFF1A1A1A);
const Color _cTextSecondaryDark = Color(0xFFCBD5E1);
const Color _cTextSecondaryLight = Color(0xFF6B7280);
const Color _cTextLightDark = Color(0xFF94A3B8);
const Color _cTextLightLight = Color(0xFF9CA3AF);

class ColorResource {
  // Primary Brand Colors
  // static const Color primaryDark = Color(0xFF003B55);
    // static const Color primaryMedium = Color(0xFF006B8F);
  // static const Color primaryLight = Color(0xFF0099CC);
  static const Color primaryDark = Color(0xFFC92A2A);
  static const Color primaryMedium = Color(0xFFE03131);
  static const Color primaryLight = Color(0xFFF03E3E);
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
  //
  // The theme-dependent colors below have two access paths that resolve to the
  // SAME values (defined once in the `_c*` constants):
  //   • `context.scaffoldBackground` — the reactive [AppColorsX] extension.
  //     PREFER THIS in widgets: reading it registers a [Theme] dependency, so
  //     the widget rebuilds/recolors automatically on a theme change.
  //   • `ColorResource.scaffoldBackground` — a static fallback resolving via
  //     `Get.isDarkMode`. It is correct but NOT reactive (establishes no Theme
  //     dependency), so use it only where no `BuildContext` is available.
  static Color get scaffoldBackground =>
      Get.isDarkMode ? _cScaffoldBgDark : _cScaffoldBgLight;
  static Color get cardBackground =>
      Get.isDarkMode ? _cCardBgDark : _cCardBgLight;
  static const Color darkBackground = Color(0xFF1A1A1A);

  // Text Colors
  static Color get textPrimary =>
      Get.isDarkMode ? _cTextPrimaryDark : _cTextPrimaryLight;
  static Color get textSecondary =>
      Get.isDarkMode ? _cTextSecondaryDark : _cTextSecondaryLight;
  static Color get textLight =>
      Get.isDarkMode ? _cTextLightDark : _cTextLightLight;
  static const Color textWhite = Colors.white;

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // UI Element Colors
  static const Color ratingStarColor = Color(0xFFFBBF24);
  static const Color favoriteColor = Color(0xFFEF4444);
  static const Color discountBadge = primaryDark;
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

/// Reactive, theme-aware colors.
///
/// Reading one of these inside a widget's `build` calls [Theme.of], which
/// registers the widget as a dependent of the ambient [Theme]. The widget then
/// rebuilds and recolors automatically whenever the theme changes — no manual
/// rebuild needed. Prefer `context.<color>` over the static
/// `ColorResource.<color>` getters everywhere a [BuildContext] is available.
extension AppColorsX on BuildContext {
  // Private to avoid colliding with GetX's own `BuildContext.isDarkMode`.
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  Color get scaffoldBackground =>
      _isDark ? _cScaffoldBgDark : _cScaffoldBgLight;
  Color get cardBackground => _isDark ? _cCardBgDark : _cCardBgLight;
  Color get textPrimary => _isDark ? _cTextPrimaryDark : _cTextPrimaryLight;
  Color get textSecondary =>
      _isDark ? _cTextSecondaryDark : _cTextSecondaryLight;
  Color get textLight => _isDark ? _cTextLightDark : _cTextLightLight;
}
