import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/controllers/cart_animation_controller.dart';
import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/models/cart_item_model.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/modules/cart/screens/cart_page.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/product_detail_bottomsheet.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Centralized helper function for handling add to cart functionality
/// 
/// Intelligently handles products with and without variants:
/// - Products **without variants** → Added directly to cart with visual feedback
/// - Products **with variants** → Opens customization bottom sheet
class CartHelper {
  /// Handle adding a product to cart with smart variant detection
  /// 
  /// [product] - The product to add to cart
  /// [context] - Build context for showing dialogs and snackbars
  static Future<void> handleAddToCart(
    ProductModel product,
    BuildContext context,
  ) async {
    // Check if product has variants
    if (product.variants.isNotEmpty) {
      // Has variants - open bottom sheet for customization
      ProductDetailBottomSheet.show(context, product);
      return;
    }

    // No variants - add directly to cart
    try {
      final userId = await Get.find<AuthController>().getUserId();
      final cartItem = CartItemModel(
        id: '',
        userId: userId ?? '',
        productId: product.id,
        productName: product.name,
        productImage: product.imageId,
        basePrice: product.price,
        discountType: product.discountType,
        discountValue: product.discountValue,
        finalPrice: product.finalPrice,
        selectedVariants: [],
        quantity: 1,
        itemTotal: product.finalPrice,
      );

      await Get.find<CartController>().addToCart(cartItem);

      // Trigger cart animation and show success feedback
      if (context.mounted) {
        _showCartAnimation(context, product);
        _showSuccessSnackbar(context, product);
      }
    } catch (e) {
      // Show error feedback
      if (context.mounted) {
        _showErrorSnackbar(context);
      }
    }
  }

  /// Show cart animation
  static void _showCartAnimation(BuildContext context, ProductModel product) {
    Get.find<CartAnimationController>().animateAddToCart(
      context: context,
      productImageUrl: product.imageId,
      buttonPosition: Offset(
        MediaQuery.of(context).size.width - 100,
        MediaQuery.of(context).size.height / 2,
      ),
    );
  }

  /// Show success snackbar with "View Cart" action
  static void _showSuccessSnackbar(BuildContext context, ProductModel product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${product.name} added to cart!',
          style: poppinsMedium.copyWith(
            color: ColorResource.textWhite,
          ),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: ColorResource.textWhite,
          onPressed: () => Get.to(() => const CartPage()),
        ),
      ),
    );
  }

  /// Show error snackbar
  static void _showErrorSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Failed to add to cart',
          style: poppinsMedium.copyWith(
            color: ColorResource.textWhite,
          ),
        ),
        backgroundColor: ColorResource.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Get the quantity of a product in the cart (for products without variants)
  /// Returns null if product is not in cart
  static int? getProductCartQuantity(String productId) {
    try {
      final cartController = Get.find<CartController>();
      final cartItem = cartController.cartItems.firstWhereOrNull(
        (item) => item.productId == productId && item.selectedVariants.isEmpty,
      );
      return cartItem?.quantity;
    } catch (e) {
      return null;
    }
  }

  /// Get cart item ID for a product (for products without variants)
  static String? _getCartItemId(String productId) {
    try {
      final cartController = Get.find<CartController>();
      final cartItem = cartController.cartItems.firstWhereOrNull(
        (item) => item.productId == productId && item.selectedVariants.isEmpty,
      );
      return cartItem?.id;
    } catch (e) {
      return null;
    }
  }

  /// Increment quantity of a product in cart
  static Future<void> incrementQuantity(
    ProductModel product,
    BuildContext context,
  ) async {
    try {
      final cartItemId = _getCartItemId(product.id);
      if (cartItemId == null) {
        // Product not in cart, add it
        await handleAddToCart(product, context);
        return;
      }

      final currentQuantity = getProductCartQuantity(product.id) ?? 0;
      await Get.find<CartController>().updateQuantity(
        cartItemId,
        currentQuantity + 1,
      );
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context);
      }
    }
  }

  /// Decrement quantity of a product in cart
  /// Removes item if quantity becomes 0
  static Future<void> decrementQuantity(
    ProductModel product,
    BuildContext context,
  ) async {
    try {
      final cartItemId = _getCartItemId(product.id);
      if (cartItemId == null) return;

      final currentQuantity = getProductCartQuantity(product.id) ?? 0;
      
      if (currentQuantity <= 1) {
        // Remove from cart
        await Get.find<CartController>().removeItem(cartItemId);
      } else {
        // Decrease quantity
        await Get.find<CartController>().updateQuantity(
          cartItemId,
          currentQuantity - 1,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context);
      }
    }
  }
}

