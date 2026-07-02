import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:flutter/material.dart';

ThemeData lightTheme = _buildTheme(brightness: Brightness.light);
ThemeData darkTheme = _buildTheme(brightness: Brightness.dark);

ThemeData _buildTheme({required Brightness brightness}) {
  final isDark = brightness == Brightness.dark;

  final colorScheme = isDark
      ? const ColorScheme.dark(
          primary: ColorResource.primary,
          secondary: ColorResource.primaryLight,
          surface: Color(0xFF111827),
          error: Color(0xFFE84D4F),
        )
      : const ColorScheme.light(
          primary: ColorResource.primary,
          secondary: ColorResource.primaryLight,
          tertiary: Color(0xFF102F9C),
          tertiaryContainer: Color(0xFF8195DB),
          surface: Color(0xFFFFFFFF),
          error: Color(0xFFE84D4F),
        );

  final scaffoldBackground = isDark
      ? const Color(0xFF0B1220)
      : const Color(0xFFF5F7FA);
  final cardColor = isDark ? const Color(0xFF111827) : Colors.white;
  final dividerColor = isDark
      ? Colors.white.withValues(alpha: 0.08)
      : const Color(0xFFCAD5E2);
  final hintColor = isDark
      ? const Color(0xFF94A3B8)
      : const Color(0xFF9F9F9F);
  final shadowColor = isDark
      ? Colors.black.withValues(alpha: 0.25)
      : Colors.black.withValues(alpha: 0.03);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    primarySwatch: ColorResource.primarySwatch,
    primaryColor: ColorResource.primary,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: scaffoldBackground,
    canvasColor: scaffoldBackground,
    cardColor: cardColor,
    dividerColor: dividerColor,
    disabledColor: const Color(0xFFBABFC4),
    hintColor: hintColor,
    shadowColor: shadowColor,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    bottomAppBarTheme: BottomAppBarThemeData(
      surfaceTintColor: isDark ? cardColor : Colors.white,
      height: 65,
      padding: const EdgeInsets.symmetric(vertical: 5),
    ),
    dividerTheme: DividerThemeData(
      color: dividerColor.withValues(alpha: isDark ? 1 : 0.4),
      thickness: 0.8,
      space: 1,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: isDark ? Colors.white : ColorResource.primaryDark,
      textColor: isDark ? Colors.white : ColorResource.textPrimary,
      tileColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF182235) : Colors.grey[100],
      hintStyle: TextStyle(color: hintColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ColorResource.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 1.6),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: isDark ? Colors.white70 : const Color(0xFFAFAFAF),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: ColorResource.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF9CA3AF),
        disabledForegroundColor: Colors.white70,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return isDark ? const Color(0xFFCBD5E1) : Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return ColorResource.primaryLight;
        }
        return isDark
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.12);
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF1F2937),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: ColorResource.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(500)),
    ),
  );
}

/// Page transition used on web/desktop only.
///
/// A quick fade with a subtle upward slide — the default Material push
/// (bottom-up slide) feels heavy in a browser. Applied via `Theme`'s
/// `pageTransitionsTheme`, which go_router's `MaterialPage` respects, so every
/// route animates the same way without per-route wiring. Mobile builds keep
/// their native transitions (this is only wired in on `kIsWeb`).
const PageTransitionsTheme webPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: _WebFadePageTransitionsBuilder(),
    TargetPlatform.iOS: _WebFadePageTransitionsBuilder(),
    TargetPlatform.macOS: _WebFadePageTransitionsBuilder(),
    TargetPlatform.windows: _WebFadePageTransitionsBuilder(),
    TargetPlatform.linux: _WebFadePageTransitionsBuilder(),
    TargetPlatform.fuchsia: _WebFadePageTransitionsBuilder(),
  },
);

class _WebFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _WebFadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final Animation<double> curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.015),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
