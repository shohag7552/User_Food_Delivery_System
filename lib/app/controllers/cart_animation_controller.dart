import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:appwrite_user_app/app/common/widgets/add_to_cart_animation.dart';

class CartAnimationController extends GetxController {
  // GlobalKey to track cart icon position
  final GlobalKey cartIconKey = GlobalKey();
  
  // Overlay entry for animation
  OverlayEntry? _overlayEntry;

  /// Trigger flying animation from button to cart
  void animateAddToCart({
    required BuildContext context,
    required String productImageUrl,
    required Offset buttonPosition,
  }) {
    // Get cart icon position
    final cartPosition = _getCartIconPosition();
    if (cartPosition == null) {
      // Cart icon not rendered yet, skip animation
      return;
    }

    // Create overlay entry
    _overlayEntry = OverlayEntry(
      builder: (context) => AddToCartAnimation(
        productImageUrl: productImageUrl,
        startPosition: buttonPosition,
        endPosition: cartPosition,
        onComplete: () {
          _removeOverlay();
          _triggerCartBadgePulse();
        },
      ),
    );

    // Insert overlay
    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Get cart icon position from GlobalKey
  Offset? _getCartIconPosition() {
    final RenderBox? renderBox =
        cartIconKey.currentContext?.findRenderObject() as RenderBox?;
    
    if (renderBox == null) return null;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    
    // Return center of cart icon
    return Offset(
      position.dx + size.width / 2,
      position.dy + size.height / 2,
    );
  }

  /// Remove overlay after animation completes
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Trigger cart badge pulse animation
  void _triggerCartBadgePulse() {
    // This will be handled by GetBuilder in the cart icon widget
    update();
  }

  @override
  void onClose() {
    _removeOverlay();
    super.onClose();
  }
}
