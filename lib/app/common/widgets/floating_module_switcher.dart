import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/module_controller.dart';
import 'package:appwrite_user_app/app/helper/module_switch_helper.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A floating Food / Shop switcher handle. On mobile it can be **dragged
/// anywhere** on the screen and, when released, **snaps to the nearest side**
/// (left or right edge) while keeping its vertical position. Tapping the handle
/// expands it *in place* into the selector; picking a module switches and
/// collapses back to the handle. Renders nothing unless the store runs both
/// modules.
///
/// Designed to sit inside a full-screen [Stack] (e.g. via `Positioned.fill`).
class FloatingModuleSwitcher extends StatefulWidget {
  const FloatingModuleSwitcher({super.key});

  @override
  State<FloatingModuleSwitcher> createState() => _FloatingModuleSwitcherState();
}

class _FloatingModuleSwitcherState extends State<FloatingModuleSwitcher> {
  // The full-screen area the switcher lives in — used to convert drag
  // coordinates into an alignment.
  final GlobalKey _areaKey = GlobalKey();

  static const double _handleW = 46;
  static const double _handleH = 50;

  /// Position within the screen, expressed as an [Alignment] (-1..1 on each
  /// axis). Starts at the middle-right edge.
  Alignment _align = const Alignment(1.0, -0.15);
  bool _dragging = false;
  bool _expanded = false;

  // Drag bookkeeping (delta-based, so the grab point stays under the finger).
  Offset _dragStartLocal = Offset.zero;
  double _handleStartLeft = 0;
  double _handleStartTop = 0;

  /// Which edge the handle is anchored to — drives corner rounding and the
  /// direction the panel expands.
  bool get _isRight => _align.x >= 0;

  void _expand() => setState(() => _expanded = true);

  void _collapse() {
    if (!_expanded) return;
    setState(() => _expanded = false);
  }

  Future<void> _select(String target) async {
    _collapse();
    await ModuleSwitchHelper.switchTo(target);
  }

  RenderBox? get _areaBox =>
      _areaKey.currentContext?.findRenderObject() as RenderBox?;

  void _onPanStart(DragStartDetails d) {
    final box = _areaBox;
    if (box == null) return;
    final Size size = box.size;
    _dragStartLocal = box.globalToLocal(d.globalPosition);
    _handleStartLeft = (_align.x + 1) / 2 * (size.width - _handleW);
    _handleStartTop = (_align.y + 1) / 2 * (size.height - _handleH);
    setState(() {
      _dragging = true;
      _expanded = false; // dragging always happens from the collapsed handle
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final box = _areaBox;
    if (box == null) return;
    final Size size = box.size;
    final Offset delta = box.globalToLocal(d.globalPosition) - _dragStartLocal;
    final double maxLeft = size.width - _handleW;
    final double maxTop = size.height - _handleH;
    final double left = (_handleStartLeft + delta.dx).clamp(0.0, maxLeft);
    final double top = (_handleStartTop + delta.dy).clamp(0.0, maxTop);
    final double ax = maxLeft <= 0 ? 0.0 : (left / maxLeft) * 2 - 1;
    final double ay = maxTop <= 0 ? 0.0 : (top / maxTop) * 2 - 1;
    setState(() {
      _align = Alignment(ax.clamp(-1.0, 1.0), ay.clamp(-1.0, 1.0));
    });
  }

  void _onPanEnd(DragEndDetails d) {
    setState(() {
      _dragging = false;
      // Snap horizontally to whichever side the handle is nearer; keep the
      // vertical position. The AnimatedAlign animates the glide to the edge.
      _align = Alignment(_align.x >= 0 ? 1.0 : -1.0, _align.y);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ModuleController>(
      builder: (module) {
        if (!module.bothEnabled) return const SizedBox.shrink();

        // Dragging is a mobile-only affordance; the desktop-web shell keeps the
        // handle pinned at the middle-right edge.
        final bool draggable = !WebTopNav.isEnabled(context);

        return Stack(
          key: _areaKey,
          children: [
            // Tap-outside-to-close barrier (only while open).
            if (_expanded)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _collapse,
                ),
              ),
            AnimatedAlign(
              // Instant while dragging (follows the finger), animated glide on
              // release so the snap to the edge reads as deliberate.
              duration: _dragging
                  ? Duration.zero
                  : const Duration(milliseconds: 340),
              curve: Curves.easeOutCubic,
              alignment: _align,
              child: Material(
                color: Colors.transparent,
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 380),
                  reverseDuration: const Duration(milliseconds: 300),
                  // Emphasized easing reads as a deliberate, premium expansion.
                  curve: Curves.easeOutCubic,
                  // Grow inward from whichever edge the handle sits on.
                  alignment:
                      _isRight ? Alignment.centerRight : Alignment.centerLeft,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    reverseDuration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    // Keep both children pinned to the anchored edge mid-morph so
                    // the cross-fade pivots on the handle instead of jumping.
                    layoutBuilder: (currentChild, previousChildren) => Stack(
                      alignment: _isRight
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
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
                        alignment: _isRight
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: child,
                      ),
                    ),
                    child: _expanded
                        ? _buildPanel(module)
                        : _buildHandle(module, draggable),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Collapsed state: a small tab tucked against the anchored edge. Draggable on
  /// mobile; tapping expands it.
  Widget _buildHandle(ModuleController module, bool draggable) {
    final bool right = _isRight;
    return GestureDetector(
      key: const ValueKey('handle'),
      onTap: _expand,
      onPanStart: draggable ? _onPanStart : null,
      onPanUpdate: draggable ? _onPanUpdate : null,
      onPanEnd: draggable ? _onPanEnd : null,
      child: Container(
        width: _handleW,
        height: _handleH,
        decoration: BoxDecoration(
          gradient: ColorResource.primaryGradient,
          // Round the two corners facing inward from the anchored edge.
          borderRadius: right
              ? const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  bottomLeft: Radius.circular(25),
                )
              : const BorderRadius.only(
                  topRight: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
          boxShadow: [
            BoxShadow(
              color: ColorResource.primaryDark.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: Offset(right ? -2 : 2, 4),
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
      // Nudge away from the anchored edge.
      margin: EdgeInsets.only(right: _isRight ? 8 : 0, left: _isRight ? 0 : 8),
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
