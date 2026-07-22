import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:flutter/material.dart';

/// Shared visibility of the floating bottom navigation bar.
///
/// The dashboard flips this as the user scrolls (hidden on scroll-down, shown
/// on scroll-up, and always shown on a tab change). Scroll views read it
/// through [NavClearance] so their bottom clearance collapses when the bar
/// hides — leaving no empty space behind.
class NavBarVisibility {
  NavBarVisibility._();

  static final ValueNotifier<bool> visible = ValueNotifier<bool>(true);
}

/// Rebuilds [builder] with a bottom clearance that eases between
/// [Constants.bottomNavSpace] (bar visible) and `0` (bar hidden), in step with
/// the bar's own hide/show animation. Use it wherever a scroll view reserved
/// space for the floating nav bar, e.g.:
///
/// ```dart
/// NavClearance(
///   builder: (context, bottom) => ListView(
///     padding: EdgeInsets.only(bottom: bottom),
///     ...
///   ),
/// )
/// ```
class NavClearance extends StatelessWidget {
  final Widget Function(BuildContext context, double bottom) builder;

  const NavClearance({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NavBarVisibility.visible,
      builder: (context, visible, _) => TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
        tween: Tween<double>(end: visible ? Constants.bottomNavSpace : 0),
        builder: (context, bottom, _) => builder(context, bottom),
      ),
    );
  }
}
