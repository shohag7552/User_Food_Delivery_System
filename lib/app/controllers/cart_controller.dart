import 'dart:developer';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/models/cart_item_model.dart';
import 'package:appwrite_user_app/app/models/coupon_model.dart';
import 'package:appwrite_user_app/app/modules/cart/domain/repository/cart_repo_interface.dart';
import 'package:get/get.dart';

class CartController extends GetxController implements GetxService {
  final CartRepoInterface cartRepoInterface;

  CartController({required this.cartRepoInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<CartItemModel> _cartItems = [];
  List<CartItemModel> get cartItems => _cartItems;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Coupon management
  CouponModel? _appliedCoupon;
  CouponModel? get appliedCoupon => _appliedCoupon;

  // Cart totals
  int get itemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _cartItems.fold(0.0, (sum, item) => sum + item.itemTotal);

  double get tax => subtotal * 0.10; // 10% tax

  // Calculate discount from applied coupon
  double get discountAmount {
    if (_appliedCoupon == null) return 0.0;
    return _appliedCoupon!.calculateDiscount(subtotal);
  }

  double get total => subtotal + tax - discountAmount;

  /// Fetch cart items for user
  Future<void> getCartItems() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      update();

      _cartItems = await cartRepoInterface.getCartItems();
      
      _isLoading = false;
      update();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load cart: $e';
      log('Error loading cart: $e');
      update();
    }
  }

  /// Add item to cart
  Future<void> addToCart(CartItemModel item) async {
    try {
      await cartRepoInterface.addCartItem(item);
      
      // Refresh cart
      await getCartItems();
      
      log('Item added to cart successfully');
    } catch (e) {
      _errorMessage = 'Failed to add item: $e';
      log('Error adding to cart: $e');
      update();
      rethrow;
    }
  }

  /// Update item quantity
  Future<void> updateQuantity(String itemId, int quantity) async {
    try {
      if (quantity < 1) return;

      await cartRepoInterface.updateCartItem(itemId, quantity);
      
      // Update local state
      final index = _cartItems.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        final item = _cartItems[index];
        final newItemTotal = item.unitPrice * quantity;
        _cartItems[index] = item.copyWith(
          quantity: quantity,
          itemTotal: newItemTotal,
        );
        update();
      }
    } catch (e) {
      _errorMessage = 'Failed to update quantity: $e';
      log('Error updating quantity: $e');
      update();
    }
  }

  /// Update cart item details (variants and quantity)
  Future<void> updateCartItemDetails(CartItemModel updatedItem) async {
    try {
      await cartRepoInterface.updateCartItemDetails(updatedItem);
      
      // Update local state
      final index = _cartItems.indexWhere((item) => item.id == updatedItem.id);
      if (index != -1) {
        _cartItems[index] = updatedItem;
        update();
      }
      log('Item details updated successfully');
    } catch (e) {
      _errorMessage = 'Failed to update item details: $e';
      log('Error updating item details: $e');
      update();
      rethrow;
    }
  }

  /// Increment quantity
  void incrementQuantity(String itemId) {
    final item = _cartItems.firstWhere((item) => item.id == itemId);
    updateQuantity(itemId, item.quantity + 1);
  }

  /// Decrement quantity
  void decrementQuantity(String itemId) {
    final item = _cartItems.firstWhere((item) => item.id == itemId);
    if (item.quantity > 1) {
      updateQuantity(itemId, item.quantity - 1);
    }
  }

  /// Remove item from cart
  Future<void> removeItem(String itemId) async {
    try {
      await cartRepoInterface.removeCartItem(itemId);
      
      // Update local state
      _cartItems.removeWhere((item) => item.id == itemId);
      update();
      
      log('Item removed from cart');
    } catch (e) {
      _errorMessage = 'Failed to remove item: $e';
      log('Error removing item: $e');
      update();
    }
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    try {
      await cartRepoInterface.clearCart();
      _cartItems.clear();
      update();
      
      log('Cart cleared successfully');
    } catch (e) {
      _errorMessage = 'Failed to clear cart: $e';
      log('Error clearing cart: $e');
      update();
    }
  }

  /// Apply coupon
  void applyCoupon(CouponModel coupon) {
    log('Attempting to apply coupon: ${coupon.code}');
    log('Current subtotal: $subtotal');
    log('Coupon min order: ${coupon.minOrderAmount}');
    log('Coupon is active: ${coupon.isActive}');
    log('Coupon valid from: ${coupon.validFrom}');
    log('Coupon valid until: ${coupon.validUntil}');
    
    // Check if coupon is active
    if (!coupon.isActive) {
      customToster('This coupon is not currently active');
      return;
    }

    // Check validity period
    final now = DateTime.now();
    if (now.isBefore(coupon.validFrom)) {
      customToster('This coupon is not yet valid, will be valid from ${_formatDate(coupon.validFrom)}');
      return;
    }

    if (now.isAfter(coupon.validUntil)) {
      customToster('This coupon expired on ${_formatDate(coupon.validUntil)}');
      return;
    }

    // Check usage limit
    if (coupon.usageLimit != null && coupon.usedCount >= coupon.usageLimit!) {
      customToster('This coupon has reached its maximum usage limit');
      return;
    }

    // Check minimum order amount
    if (coupon.minOrderAmount != null && subtotal < coupon.minOrderAmount!) {
      customToster('Minimum Order Not Met, add \$${(coupon.minOrderAmount! - subtotal).toStringAsFixed(2)} more to use this coupon');
      return;
    }

    // Coupon is valid, apply it
    _appliedCoupon = coupon;
    _errorMessage = null;
    update();
    
    final discount = coupon.calculateDiscount(subtotal);
    log('Coupon applied successfully: ${coupon.code}, discount: $discount');

    customToster('Coupon Applied! You saved \$${discount.toStringAsFixed(2)} with ${coupon.code}');
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Remove applied coupon
  void removeCoupon() {
    final removedCode = _appliedCoupon?.code;
    _appliedCoupon = null;
    update();
    log('Coupon removed');
    
    if (removedCode != null) {
      customToster('Coupon $removedCode has been removed');
    }
  }

  /// Clear coupon when cart is cleared
  // @override
  // Future<void> clearCart() async {
  //   try {
  //     await cartRepoInterface.clearCart();
  //     _cartItems.clear();
  //     _appliedCoupon = null; // Clear coupon as well
  //     update();
  //
  //     log('Cart cleared successfully');
  //   } catch (e) {
  //     _errorMessage = 'Failed to clear cart: $e';
  //     log('Error clearing cart: $e');
  //     update();
  //   }
  // }
}
