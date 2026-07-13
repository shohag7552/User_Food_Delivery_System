import 'package:appwrite_user_app/app/controllers/module_controller.dart';
import 'package:appwrite_user_app/app/helper/module_switch_helper.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A floating handle pinned to the middle-right edge of the screen. Tapping it
/// makes the handle expand *in place* into the Food / Shop selector at that same
/// spot; picking a module switches and auto-collapses back to the handle.
/// Renders nothing unless the store runs both modules.
///
/// Designed to sit inside a full-screen [Stack] (e.g. via `Positioned.fill`).
class FloatingModuleSwitcher extends StatefulWidget {
  const FloatingModuleSwitcher({super.key});

  @override
  State<FloatingModuleSwitcher> createState() => _FloatingModuleSwitcherState();
}

class _FloatingModuleSwitcherState extends State<FloatingModuleSwitcher> {
  bool _expanded = false;

  void _expand() => setState(() => _expanded = true);

  void _collapse() {
    if (!_expanded) return;
    setState(() => _expanded = false);
  }

  Future<void> _select(String target) async {
    _collapse();
    await ModuleSwitchHelper.switchTo(target);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ModuleController>(
      builder: (module) {
        if (!module.bothEnabled) return const SizedBox.shrink();
        return Stack(
          children: [
            // Tap-outside-to-close barrier (only while open).
            if (_expanded)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _collapse,
                ),
              ),
            // The switcher lives at the middle-right edge and expands in place.
            Align(
              alignment: const Alignment(1.0, -0.15), // middle-right
              child: Material(
                color: Colors.transparent,
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 380),
                  reverseDuration: const Duration(milliseconds: 300),
                  // Emphasized easing reads as a deliberate, premium expansion.
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerRight, // grow leftward from edge
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    reverseDuration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    // Keep both children pinned to the right edge mid-morph so
                    // the cross-fade pivots on the handle instead of jumping.
                    layoutBuilder: (currentChild, previousChildren) => Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        ...previousChildren,
                        ?currentChild,
                      ],
                    ),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                          animation,
                        ),
                        alignment: Alignment.centerRight,
                        child: child,
                      ),
                    ),
                    child: _expanded
                        ? _buildPanel(module)
                        : _buildHandle(module),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Collapsed state: a small tab tucked against the right edge.
  Widget _buildHandle(ModuleController module) {
    return GestureDetector(
      key: const ValueKey('handle'),
      onTap: _expand,
      child: Container(
        width: 46,
        height: 50,
        decoration: BoxDecoration(
          gradient: ColorResource.primaryGradient,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            bottomLeft: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: ColorResource.primaryDark.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(-2, 4),
            ),
          ],
        ),
        child: Icon(
          module.isEcommerce
              ? Icons.shopping_bag_outlined
              : Icons.restaurant_menu,
          color: ColorResource.textWhite,
          size: 22,
        ),
      ),
    );
  }

  /// Expanded state: the Food / Shop selector shown right at the handle's spot.
  Widget _buildPanel(ModuleController module) {
    return Container(
      key: const ValueKey('panel'),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(
            module,
            ModuleController.food,
            Icons.restaurant_menu,
            'food'.tr,
            order: 0,
          ),
          const SizedBox(width: 4),
          _segment(
            module,
            ModuleController.ecommerce,
            Icons.shopping_bag_outlined,
            'shop'.tr,
            order: 1,
          ),
        ],
      ),
    );
  }

  Widget _segment(
    ModuleController module,
    String value,
    IconData icon,
    String label, {
    required int order,
  }) {
    final selected = module.activeModule == value;
    // Rebuilt fresh each time the panel opens, so this entrance replays on every
    // expand. The per-order duration makes the second option land a beat later,
    // giving a polished left-to-right cascade.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 260 + order * 130),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(14 * (1 - t), 0),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () => _select(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? ColorResource.primaryDark
                : context.scaffoldBackground,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? ColorResource.textWhite
                    : context.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: selected
                      ? ColorResource.textWhite
                      : context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
