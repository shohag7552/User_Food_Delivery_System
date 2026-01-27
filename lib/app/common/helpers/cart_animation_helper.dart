import 'package:appwrite_user_app/app/controllers/cart_animation_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Helper class for cart animations
class CartAnimationHelper {
  /// Trigger add to cart animation
  /// 
  /// Call this after successfully adding an item to cart
  /// [context] - BuildContext from the widget
  /// [productImageUrl] - URL or ID of the product image
  /// [buttonKey] - GlobalKey of the add button (optional, will use tap position if null)
  static void triggerAnimation({
    required BuildContext context,
    required String productImageUrl,
    GlobalKey? buttonKey,
  }) {
   try {
      final controller = Get.find<CartAnimationController>();
      
      // Get button position
      Offset buttonPosition;
      if (buttonKey != null) {
        final  RenderBox? renderBox =
            buttonKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final position = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;
          buttonPosition = Offset(
            position.dx + size.width / 2,
            position.dy + size.height / 2,
          );
        } else {
          // Fallback to screen center if can't get position
          buttonPosition = Offset(
            MediaQuery.of(context).size.width / 2,
            MediaQuery.of(context).size.height / 2,
          );
        }
      } else {
        // Use screen center as fallback
        buttonPosition = Offset(
          MediaQuery.of(context).size.width / 2,
          MediaQuery.of(context).size.height / 2,
        );
      }

      // Trigger animation
      controller.animateAddToCart(
        context: context,
        productImageUrl: productImageUrl,
        buttonPosition: buttonPosition,
      );
    } catch (e) {
      // Silently fail if controller not found or animation fails
      debugPrint('Cart animation error: $e');
    }
  }
}
