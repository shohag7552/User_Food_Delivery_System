import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class AddToCartAnimation extends StatefulWidget {
  final String productImageUrl;
  final Offset startPosition;
  final Offset endPosition;
  final VoidCallback onComplete;
  final Duration duration;

  const AddToCartAnimation({
    super.key,
    required this.productImageUrl,
    required this.startPosition,
    required this.endPosition,
    required this.onComplete,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<AddToCartAnimation> createState() => _AddToCartAnimationState();
}

class _AddToCartAnimationState extends State<AddToCartAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pathAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Path animation (curved movement)
    _pathAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // Scale animation (shrink as it flies)
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Opacity animation (fade out at the end)
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));

    // Start animation
    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _calculatePosition(double t) {
    // Calculate curved path using quadratic Bezier curve
    final start = widget.startPosition;
    final end = widget.endPosition;

    // Control point for the curve (above the straight line)
    final controlX = (start.dx + end.dx) / 2;
    final controlY = math.min(start.dy, end.dy) - 100; // Arc upward
    final control = Offset(controlX, controlY);

    // Quadratic Bezier formula
    final x = math.pow(1 - t, 2) * start.dx +
        2 * (1 - t) * t * control.dx +
        math.pow(t, 2) * end.dx;
    final y = math.pow(1 - t, 2) * start.dy +
        2 * (1 - t) * t * control.dy +
        math.pow(t, 2) * end.dy;

    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final position = _calculatePosition(_pathAnimation.value);
        
        return Positioned(
          left: position.dx - 30, // Center the image (60/2)
          top: position.dy - 30,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomNetworkImage(
                    image: widget.productImageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
