import 'dart:math' as math;

import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:flutter/material.dart';

/// A single, one-shot confetti burst — no package, no asset.
///
/// Particles fire upward and outward from [origin], arc over under gravity,
/// tumble on their own axis, and fade out. Once [progress] reaches 1 the
/// painter is removed from the tree entirely, so nothing keeps repainting
/// behind a finished celebration.
///
/// Meant to be dropped into a [Stack] as a `Positioned.fill`; it never takes
/// pointer events.
class ConfettiBurst extends StatefulWidget {
  /// 0 → 1 across the burst.
  final Animation<double> progress;

  /// Where the burst fires from, as a fraction of the available box —
  /// `Offset(0.5, 0.3)` is centred horizontally, a third of the way down.
  final Offset origin;

  final int particleCount;

  const ConfettiBurst({
    super.key,
    required this.progress,
    this.origin = const Offset(0.5, 0.3),
    this.particleCount = 44,
  });

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> {
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    // Generated once, here — never in paint(), which runs every frame and
    // would otherwise reshuffle the whole burst 60 times a second.
    //
    // Fixed seed: the spread only has to look scattered, and a stable one
    // keeps the animation identical between runs, which makes it reviewable.
    _particles = _buildParticles(math.Random(7), widget.particleCount);
  }

  static List<_Particle> _buildParticles(math.Random random, int count) {
    // Brand plus the celebratory accents. Enough variety to feel scattered,
    // few enough to still read as one palette.
    final palette = [
      ColorResource.primaryDark,
      ColorResource.primaryMedium,
      ColorResource.primaryLight,
      ColorResource.success,
      ColorResource.warning,
    ];

    return List.generate(count, (i) {
      // Fire in a fan centred on straight up (-pi/2), roughly 150° wide, so
      // the burst opens outward instead of shooting a column at the ceiling.
      final angle = -math.pi / 2 + (random.nextDouble() - 0.5) * 2.6;
      final speed = 0.55 + random.nextDouble() * 0.75;

      return _Particle(
        velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
        color: palette[i % palette.length],
        size: 5 + random.nextDouble() * 6,
        // Half the pieces are round, half are rectangles — mixed shapes read
        // as confetti; a field of identical dots reads as a loading spinner.
        isRound: random.nextBool(),
        spin: (random.nextDouble() - 0.5) * 10,
        phase: random.nextDouble() * math.pi * 2,
        // Staggered so they don't all leave in the same frame.
        delay: random.nextDouble() * 0.12,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.progress,
      builder: (context, _) {
        final t = widget.progress.value;
        // Finished: drop the painter so it stops consuming frames.
        if (t <= 0 || t >= 1) return const SizedBox.shrink();

        return RepaintBoundary(
          child: CustomPaint(
            painter: _ConfettiPainter(
              particles: _particles,
              progress: t,
              origin: widget.origin,
            ),
          ),
        );
      },
    );
  }
}

class _Particle {
  /// Launch velocity, in fractions of the canvas's short side per unit time.
  final Offset velocity;
  final Color color;
  final double size;
  final bool isRound;

  /// Radians per unit time.
  final double spin;

  /// Starting rotation, so pieces don't all begin flat.
  final double phase;

  /// Fraction of the burst to wait before launching.
  final double delay;

  const _Particle({
    required this.velocity,
    required this.color,
    required this.size,
    required this.isRound,
    required this.spin,
    required this.phase,
    required this.delay,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Offset origin;

  const _ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.origin,
  });

  /// Downward pull. Tuned against [_Particle.velocity] so pieces peak around a
  /// third of the way through and are clearly falling by the end.
  static const double _gravity = 1.9;

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(size.width * origin.dx, size.height * origin.dy);
    // Velocities are expressed against the short side so the burst covers the
    // same visual area on a phone and on a wide desktop window.
    final scale = math.min(size.width, size.height);

    for (final particle in particles) {
      final t = ((progress - particle.delay) / (1 - particle.delay))
          .clamp(0.0, 1.0);
      if (t <= 0) continue;

      final dx = particle.velocity.dx * t * scale;
      final dy = (particle.velocity.dy * t + 0.5 * _gravity * t * t) * scale;
      final position = start + Offset(dx, dy);

      // Hold full opacity for the first 55%, then fade — a piece that starts
      // fading immediately never looks like it was thrown.
      final opacity = t < 0.55 ? 1.0 : (1 - (t - 0.55) / 0.45).clamp(0.0, 1.0);
      if (opacity <= 0) continue;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity * 0.92);

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(particle.phase + particle.spin * t);

      if (particle.isRound) {
        canvas.drawCircle(Offset.zero, particle.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              // Rectangles are taller than wide so the spin is legible.
              height: particle.size * 1.6,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.progress != progress || old.origin != origin;
}
