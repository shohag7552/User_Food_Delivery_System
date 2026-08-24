import 'package:appwrite_user_app/app/controllers/module_controller.dart';
import 'package:appwrite_user_app/app/helper/module_switch_helper.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Persistent Food / Shop control for the desktop-web storefront.
///
/// The mobile switcher is a draggable handle that has to be opened before it
/// says anything, which on a pointer device costs a click and hides the
/// storefront you are in behind a single icon. This states both storefronts
/// outright, marks the active one, and switches on one click.
///
/// Nothing about it moves: no drag, no expand, no collapse. It is in the same
/// place on every visit, which is what makes it findable a second time.
///
/// Shaped as a rail tucked against the side of the window rather than a pill
/// floating in front of it: stacked, it is narrow enough to sit in the gutter
/// beside the capped content column instead of over the top of it, and being
/// flush to the edge is what makes it read as part of the window's furniture
/// rather than as something dropped on the page.
///
/// Which side is resolved by direction, not by geometry — [AlignmentDirectional]
/// and [BorderRadiusDirectional] put it on the right in English and on the left
/// in Arabic, rounding whichever corners face inward, with no branch to keep in
/// step.
///
/// Renders nothing unless the store actually runs both modules.
class WebModuleSwitcher extends StatefulWidget {
  const WebModuleSwitcher({super.key, this.onSwitch});

  /// Performs the switch. Defaults to [ModuleSwitchHelper.switchTo].
  ///
  /// Injectable so the control can be driven in a test without standing up
  /// the six controllers the real helper reaches for.
  final Future<void> Function(String target)? onSwitch;

  @override
  State<WebModuleSwitcher> createState() => _WebModuleSwitcherState();
}

class _WebModuleSwitcherState extends State<WebModuleSwitcher> {
  /// A segment is a stacked icon and label, sized past the 44px minimum on
  /// both axes so it is a comfortable target rather than a precise one.
  static const double _segmentWidth = 58;
  static const double _segmentHeight = 62;

  /// Rounding on the two corners facing into the page. The edge the rail is
  /// tucked against stays square, which is what sells it as attached.
  static const double _innerRadius = 22;
  static const double _thumbRadius = 18;

  /// Where the rail sits: hard against the trailing edge — right in English,
  /// left in Arabic — a little above centre. The same spot the mobile handle
  /// rests at, so a customer who knows one knows the other.
  static const AlignmentDirectional _anchor = AlignmentDirectional(1, -0.15);

  static const Duration _slide = Duration(milliseconds: 260);

  /// The module being switched to while the swap is in flight, or null.
  ///
  /// Switching drops every cached list and refetches, so it is not instant.
  /// Holding the target here lets the control say which one it is working on
  /// and refuse further clicks until it lands — without it, an impatient
  /// double-click queues two full reloads.
  String? _switchingTo;

  Future<void> _select(ModuleController module, String target) async {
    if (_switchingTo != null || module.activeModule == target) return;

    setState(() => _switchingTo = target);
    try {
      await (widget.onSwitch ?? ModuleSwitchHelper.switchTo)(target);
    } finally {
      if (mounted) setState(() => _switchingTo = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ModuleController>(
      builder: (module) {
        if (!module.bothEnabled) return const SizedBox.shrink();

        return Align(alignment: _anchor, child: _buildRail(context, module));
      },
    );
  }

  Widget _buildRail(BuildContext context, ModuleController module) {
    // Rounded on the two corners facing into the page; square where it meets
    // the window edge. Directional, so Arabic gets the mirror image for free.
    const BorderRadiusDirectional shape = BorderRadiusDirectional.horizontal(
      start: Radius.circular(_innerRadius),
    );

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: shape,
        // A hairline as well as a shadow: the rail sits over the storefront,
        // and against a pale section a shadow alone leaves it without an edge.
        border: BorderDirectional(
          top: BorderSide(color: context.textLight.withValues(alpha: 0.18)),
          bottom: BorderSide(color: context.textLight.withValues(alpha: 0.18)),
          start: BorderSide(color: context.textLight.withValues(alpha: 0.18)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        width: _segmentWidth,
        height: _segmentHeight * 2,
        child: Stack(
          children: [
            // The selection itself, sliding between the two halves rather than
            // blinking out of one and into the other — the movement is what
            // says the two are one control with one answer.
            AnimatedAlign(
              duration: _slide,
              curve: Curves.easeOutCubic,
              alignment: module.isEcommerce
                  ? Alignment.bottomCenter
                  : Alignment.topCenter,
              child: Container(
                width: _segmentWidth,
                height: _segmentHeight,
                decoration: BoxDecoration(
                  gradient: ColorResource.primaryGradient,
                  borderRadius: BorderRadius.circular(_thumbRadius),
                  boxShadow: [
                    BoxShadow(
                      color: ColorResource.primaryDark.withValues(alpha: 0.32),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                _buildSegment(
                  context,
                  module: module,
                  value: ModuleController.food,
                  icon: Icons.restaurant_menu,
                  label: 'food'.tr,
                ),
                _buildSegment(
                  context,
                  module: module,
                  value: ModuleController.ecommerce,
                  icon: Icons.shopping_bag_outlined,
                  label: 'shop'.tr,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(
    BuildContext context, {
    required ModuleController module,
    required String value,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = module.activeModule == value;
    final bool isBusy = _switchingTo == value;
    final bool isLocked = _switchingTo != null;

    return SizedBox(
      width: _segmentWidth,
      height: _segmentHeight,
      child: Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 500),
        child: Semantics(
          button: true,
          selected: isSelected,
          label: label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              // Null while a switch is in flight, which also greys the hover and
              // ripple — the control looks as unavailable as it is.
              onTap: isLocked || isSelected
                  ? null
                  : () => _select(module, value),
              borderRadius: BorderRadius.circular(_thumbRadius),
              // Only the inactive half is a target; hovering the one you are
              // already on should not suggest anything will happen.
              hoverColor: isSelected
                  ? Colors.transparent
                  : ColorResource.primaryDark.withValues(alpha: 0.06),
              child: TweenAnimationBuilder<double>(
                // Drives icon and label together off one value, so their colour
                // crosses at the same rate the selection slides under them.
                tween: Tween<double>(begin: 0, end: isSelected ? 1 : 0),
                duration: _slide,
                curve: Curves.easeOut,
                builder: (context, t, _) {
                  final Color color = Color.lerp(
                    context.textSecondary,
                    ColorResource.textWhite,
                    t,
                  )!;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isBusy)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        )
                      else
                        Icon(icon, size: 20, color: color),
                      const SizedBox(height: 5),
                      // Scaled down rather than clipped: 'Shop' and 'المتجر' are
                      // not the same width, and a rail this narrow has no room
                      // to absorb the difference.
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            maxLines: 1,
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeExtraSmall,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
