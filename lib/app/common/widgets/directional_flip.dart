import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Mirrors [child] horizontally when the ambient text direction is RTL.
///
/// Use it for direction-dependent glyphs — back arrows, "see all" chevrons,
/// forward arrows — that don't auto-mirror. In LTR it returns the child as-is;
/// in RTL it flips it on the Y axis so an arrow that points left now points
/// right (and vice-versa).
///
/// ```dart
/// DirectionalFlip(child: Icon(Icons.arrow_back))
/// ```
class DirectionalFlip extends StatelessWidget {
  final Widget child;

  const DirectionalFlip({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;
    if (!isRtl) return child;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(math.pi),
      child: child,
    );
  }
}
