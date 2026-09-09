import 'package:appwrite_user_app/app/resources/constants.dart';
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

/// Shifts [base] along the HSL saturation and lightness axes.
///
/// Hue is never touched, which is what keeps a derived step recognisably the
/// same colour as the brand rather than a different one.
Color _brandStep(Color base, {required double lightness, required double saturation}) {
  final HSLColor hsl = HSLColor.fromColor(base);
  return hsl
      .withSaturation((hsl.saturation + saturation).clamp(0.0, 1.0))
      .withLightness((hsl.lightness + lightness).clamp(0.0, 1.0))
      .toColor();
}

class ColorResource {
  // ── Primary brand colours ────────────────────────────────────────────────
  //
  // All of these come from ONE value: `Constants.primaryColor`. Change that and
  // the accent steps, the gradient, the Material swatch and both themes follow.
  // Nothing here should ever be a hand-written hex again.

  /// The brand colour itself. Still `const`, because it is read in hundreds of
  /// `const` widget expressions across the app.
  static const Color primaryDark = Constants.primaryColor;

  /// Two brighter steps of [primaryDark], used for the gradient and as the
  /// scheme's secondary.
  ///
  /// The offsets are not arbitrary: they are fitted so that the shipped brand
  /// (`0xFFC92A2A`) reproduces its previous hand-picked partners `0xFFE03131`
  /// and `0xFFF03E3E` exactly — so this refactor changed no pixel — while any
  /// other brand colour gets the same "brighter and a little richer" ramp.
  static Color get primaryMedium =>
      _brandStep(primaryDark, lightness: 0.060, saturation: 0.085);
  static Color get primaryLight =>
      _brandStep(primaryDark, lightness: 0.115, saturation: 0.200);

  static const Color primary = primaryDark;
  static const Color appBarColor = primaryDark;

  static LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryDark, primaryMedium, primaryLight],
      );

  /// Material swatch for [ThemeData.primarySwatch], stepped from [primaryDark].
  ///
  /// Previously this was hand-written with a base of `0xFF003B55` — a leftover
  /// from an earlier blue brand — so every shade except 500 was still blue
  /// while the app had been red for some time. Deriving it removes the whole
  /// class of mistake.
  static MaterialColor get primarySwatch => MaterialColor(
        primaryDark.toARGB32(),
        <int, Color>{
          50: brandTint(0.90),
          100: brandTint(0.80),
          200: brandTint(0.60),
          300: brandTint(0.40),
          400: brandTint(0.20),
          500: primaryDark,
          600: brandShade(0.10),
          700: brandShade(0.20),
          800: brandShade(0.30),
          900: brandShade(0.40),
        },
      );

  /// [primaryDark] mixed [t] of the way toward white (0 = brand, 1 = white).
  ///
  /// Public so a screen needing its own brand ramp — a hero panel, a reward
  /// card — can step off the brand instead of hard-coding a hex that a rebrand
  /// would silently leave behind.
  static Color brandTint(double t) => Color.lerp(primaryDark, Colors.white, t)!;

  /// [primaryDark] mixed [t] of the way toward black (0 = brand, 1 = black).
  static Color brandShade(double t) => Color.lerp(primaryDark, Colors.black, t)!;


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
