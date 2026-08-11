import 'dart:math' as math;

import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:flutter/material.dart';

/// The order-confirmation success mark, drawn rather than faded in.
///
/// Four beats, choreographed from a single [progress] animation so the caller
/// only has to hand over one interval:
///
/// 1. the disc scales up with a slight overshoot — it lands like a stamp
/// 2. a ring sweeps around it clockwise, closing the loop
/// 3. the tick draws itself stroke-by-stroke along its own path
/// 4. two ripples expand outward and fade
///
/// Drawing the tick is what separates this from a static icon: the eye follows
/// the stroke and reads it as *something completing*, which is exactly the
/// message of the page.
class AnimatedSuccessMark extends StatelessWidget {
  /// 0 → 1 across the whole four-beat sequence.
  final Animation<double> progress;

  /// Diameter of the filled disc.
  final double size;

  final Color color;

  const AnimatedSuccessMark({
    super.key,
    required this.progress,
    required this.size,
    this.color = ColorResource.success,
  });

  // Sub-beats, as fractions of [progress]. They overlap on purpose — each beat
  // starts before the previous finishes, which is what makes the sequence read
  // as one gesture instead of four queued steps.
  static const Interval _disc = Interval(0, 0.38, curve: Curves.easeOutBack);
  static const Interval _ring = Interval(0.16, 0.68, curve: Curves.easeOutCubic);
  static const Interval _tick = Interval(0.44, 1, curve: Curves.easeOutCubic);
  static const Interval _ripple = Interval(0.68, 1, curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    // Ripples need room to travel beyond the disc without being clipped.
    final canvasSize = size * 2.1;

    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final t = progress.value;
        final disc = _disc.transform(t);

        return SizedBox(
          width: canvasSize,
          height: canvasSize,
          child: CustomPaint(
            painter: _SuccessMarkPainter(
              // easeOutBack overshoots past 1 and settles back — clamping the
              // low end keeps a negative early value from mirroring the disc.
              discScale: disc.clamp(0.0, 2.0),
              ringSweep: _ring.transform(t),
              tickProgress: _tick.transform(t),
              rippleProgress: _ripple.transform(t),
              discSize: size,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

class _SuccessMarkPainter extends CustomPainter {
  final double discScale;
  final double ringSweep;
  final double tickProgress;
  final double rippleProgress;
  final double discSize;
  final Color color;

  const _SuccessMarkPainter({
    required this.discScale,
    required this.ringSweep,
    required this.tickProgress,
    required this.rippleProgress,
    required this.discSize,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = discSize / 2;

    _paintRipples(canvas, centre, radius);
    _paintGlow(canvas, centre, radius);
    _paintDisc(canvas, centre, radius);
    _paintRing(canvas, centre, radius);
    _paintTick(canvas, centre, radius);
  }

  /// Expanding rings, drawn first so the disc always sits on top of them.
  /// Staggered by 18% so they read as a pulse rather than one thick band.
  void _paintRipples(Canvas canvas, Offset centre, double radius) {
    if (rippleProgress <= 0) return;

    for (final delay in const [0.0, 0.18]) {
      final t = ((rippleProgress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * (1 - t)
        ..color = color.withValues(alpha: 0.35 * (1 - t));

      canvas.drawCircle(centre, radius * (1 + t * 0.55), paint);
    }
  }

  /// Soft halo under the disc. Scales with the disc so it doesn't hang in the
  /// air before the mark arrives.
  void _paintGlow(Canvas canvas, Offset centre, double radius) {
    if (discScale <= 0) return;

    final glowRadius = radius * 1.9 * discScale.clamp(0.0, 1.0);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.20),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: centre, radius: glowRadius));

    canvas.drawCircle(centre, glowRadius, paint);
  }

  void _paintDisc(Canvas canvas, Offset centre, double radius) {
    if (discScale <= 0) return;
    canvas.drawCircle(centre, radius * discScale, Paint()..color = color);
  }

  /// Ring sweeping clockwise from 12 o'clock, drawn just outside the disc.
  void _paintRing(Canvas canvas, Offset centre, double radius) {
    if (ringSweep <= 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.45);

    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius * 1.22),
      -math.pi / 2,
      2 * math.pi * ringSweep,
      false,
      paint,
    );
  }

  /// The tick, extracted progressively from its own path so it appears to be
  /// drawn by hand rather than revealed by a mask.
  void _paintTick(Canvas canvas, Offset centre, double radius) {
    if (tickProgress <= 0) return;

    final d = radius * 2;
    final left = centre.dx - radius;
    final top = centre.dy - radius;

    final path = Path()
      ..moveTo(left + d * 0.28, top + d * 0.52)
      ..lineTo(left + d * 0.43, top + d * 0.67)
      ..lineTo(left + d * 0.73, top + d * 0.36);

    final metrics = path.computeMetrics().toList();
    final drawn = Path();
    var remaining = tickProgress;

    // The tick is two segments; walk them in order so the stroke turns the
    // corner instead of both halves growing at once.
    final totalLength = metrics.fold<double>(0, (sum, m) => sum + m.length);
    var consumed = 0.0;
    for (final metric in metrics) {
      final share = metric.length / totalLength;
      final localT = ((remaining - consumed) / share).clamp(0.0, 1.0);
      if (localT <= 0) break;
      drawn.addPath(metric.extractPath(0, metric.length * localT), Offset.zero);
      consumed += share;
    }

    canvas.drawPath(
      drawn,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.19
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = ColorResource.textWhite,
    );
  }

  @override
  bool shouldRepaint(_SuccessMarkPainter old) =>
      old.discScale != discScale ||
      old.ringSweep != ringSweep ||
      old.tickProgress != tickProgress ||
      old.rippleProgress != rippleProgress ||
      old.color != color;
}
