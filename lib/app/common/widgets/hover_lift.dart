import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:flutter/material.dart';

/// Subtle web/desktop hover: lifts a card with a scale + elevated shadow.
/// Pointer-only, so touch/mobile is unaffected.
class HoverLift extends StatefulWidget {
  final Widget child;
  final double? borderRadius;
  final bool showShadow;

  const HoverLift({super.key, required this.child, this.borderRadius, this.showShadow = true});

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? Constants.radiusLarge;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!_hovered) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (_hovered) setState(() => _hovered = false);
      },
      child: AnimatedScale(
        scale: _hovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: _hovered && widget.showShadow
                ? [
                    BoxShadow(
                      color: ColorResource.primaryDark.withValues(alpha: 0.18),
                      blurRadius: 22,
                      spreadRadius: 1,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : const [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
