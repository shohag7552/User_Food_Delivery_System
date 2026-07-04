import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:flutter/material.dart';

/// Overlays desktop-web hover-revealed scroll arrows on any carousel — the
/// same affordance as the ecommerce home's Top Products strip.
///
/// On mobile/tablet (or whenever [WebTopNav.isEnabled] is false) it renders
/// the bare [child]: no MouseRegion, no arrows, so touch layouts are
/// unaffected. The arrows are positioned overlays, so the stack keeps the
/// child's own size.
class HoverArrows extends StatefulWidget {
  final Widget child;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  const HoverArrows({
    super.key,
    required this.child,
    required this.onLeft,
    required this.onRight,
  });

  @override
  State<HoverArrows> createState() => _HoverArrowsState();
}

class _HoverArrowsState extends State<HoverArrows> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (!WebTopNav.isEnabled(context)) {
      return widget.child;
    }

    return MouseRegion(
      onEnter: (_) {
        if (!_hovered) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (_hovered) setState(() => _hovered = false);
      },
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _animatedArrow(isLeft: true),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: _animatedArrow(isLeft: false),
            ),
          ),
        ],
      ),
    );
  }

  /// Fades + slides the scroll arrow in while the strip is hovered, and out
  /// (non-interactive) otherwise.
  Widget _animatedArrow({required bool isLeft}) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      opacity: _hovered ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        offset: _hovered ? Offset.zero : Offset(isLeft ? -0.4 : 0.4, 0),
        child: IgnorePointer(
          ignoring: !_hovered,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: ColorResource.cardBackground,
              shape: const CircleBorder(),
              elevation: 3,
              shadowColor: Colors.black.withValues(alpha: 0.2),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: isLeft ? widget.onLeft : widget.onRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    isLeft ? Icons.chevron_left : Icons.chevron_right,
                    color: ColorResource.primaryDark,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// [HoverArrows] specialised for plain horizontal scrollables: owns the
/// [ScrollController], hands it to [builder] (wire it to the list), and pages
/// the list by [scrollDelta] per arrow tap.
///
/// ```dart
/// HoverArrowCarousel(
///   height: 250,
///   builder: (context, controller) => ListView.separated(
///     controller: controller,
///     scrollDirection: Axis.horizontal,
///     ...
///   ),
/// )
/// ```
class HoverArrowCarousel extends StatefulWidget {
  final double height;
  final Widget Function(BuildContext context, ScrollController controller)
      builder;

  /// How far one arrow tap scrolls, in pixels.
  final double scrollDelta;

  const HoverArrowCarousel({
    super.key,
    required this.height,
    required this.builder,
    this.scrollDelta = 380,
  });

  @override
  State<HoverArrowCarousel> createState() => _HoverArrowCarouselState();
}

class _HoverArrowCarouselState extends State<HoverArrowCarousel> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scrollBy(double delta) {
    if (!_controller.hasClients) return;
    final target = (_controller.offset + delta)
        .clamp(0.0, _controller.position.maxScrollExtent);
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return HoverArrows(
      onLeft: () => _scrollBy(-widget.scrollDelta),
      onRight: () => _scrollBy(widget.scrollDelta),
      child: SizedBox(
        height: widget.height,
        child: widget.builder(context, _controller),
      ),
    );
  }
}
