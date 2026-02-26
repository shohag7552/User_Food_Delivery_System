import 'package:appwrite_user_app/app/models/cart_item_model.dart';

abstract class CartRepoInterface {
  Future<List<CartItemModel>> getCartItems();
  Future<CartItemModel> addCartItem(CartItemModel item);
  Future<CartItemModel> updateCartItem(String itemId, int quantity);
  Future<CartItemModel> updateCartItemDetails(CartItemModel item);
  Future<void> removeCartItem(String itemId);
  Future<void> clearCart();
}
