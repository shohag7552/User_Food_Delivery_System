import 'dart:developer';
import 'package:appwrite/models.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/models/cart_item_model.dart';
import 'package:appwrite_user_app/app/modules/cart/domain/repository/cart_repo_interface.dart';
// import 'package:dart_appwrite/models.dart' hide User;
import 'package:dart_appwrite/dart_appwrite.dart';

class CartRepository implements CartRepoInterface {
  final AppwriteService appwriteService;

  CartRepository({required this.appwriteService});

  @override
  Future<List<CartItemModel>> getCartItems() async {
    try {
      User? user = await appwriteService.getCurrentUser();

      if (user == null) {
        throw Exception('User not logged in');
      }

      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.cartCollection,
        queries: [
          Query.equal('user_id', user.$id),
          Query.orderDesc('\$createdAt'),
        ],
      );

      return response.rows.map((row) {
        return CartItemModel.fromJson(row.data);
      }).toList();
    } catch (e) {
      log('Error fetching cart items: $e');
      throw Exception('Failed to load cart items');
    }
  }

  @override
  Future<CartItemModel> addCartItem(CartItemModel item) async {
    try {
      final doc = await appwriteService.createRow(
        collectionId: AppwriteConfig.cartCollection,
        data: item.toJson(),
      );

      return CartItemModel.fromJson(doc.data);
    } catch (e) {
      log('Error adding cart item: $e');
      throw Exception('Failed to add item to cart');
    }
  }

  @override
  Future<CartItemModel> updateCartItem(String itemId, int quantity) async {
    try {
      // First get the item to recalculate total
      final item = await appwriteService.getDocument(
        collectionId: AppwriteConfig.cartCollection,
        documentId: itemId,
      );

      final cartItem = CartItemModel.fromJson(item.data);
      
      // Recalculate item total
      final newItemTotal = cartItem.unitPrice * quantity;

      final updatedDoc = await appwriteService.updateTable(
        tableId: AppwriteConfig.cartCollection,
        rowId: itemId,
        data: {
          'quantity': quantity,
          'item_total': newItemTotal,
        },
      );

      return CartItemModel.fromJson(updatedDoc.data);
    } catch (e) {
      log('Error updating cart item: $e');
      throw Exception('Failed to update cart item');
    }
  }

  @override
  Future<CartItemModel> updateCartItemDetails(CartItemModel item) async {
    try {
      final updatedDoc = await appwriteService.updateTable(
        tableId: AppwriteConfig.cartCollection,
        rowId: item.id,
        data: item.toJson(),
      );

      return CartItemModel.fromJson(updatedDoc.data);
    } catch (e) {
      log('Error updating cart item details: $e');
      throw Exception('Failed to update cart item details');
    }
  }

  @override
  Future<void> removeCartItem(String itemId) async {
    try {
      await appwriteService.deleteRow(
        collectionId: AppwriteConfig.cartCollection,
        rowId: itemId,
      );
    } catch (e) {
      log('Error removing cart item: $e');
      throw Exception('Failed to remove cart item');
    }
  }

  @override
  Future<void> clearCart() async {
    try {
      final items = await getCartItems();
      
      for (var item in items) {
        await removeCartItem(item.id);
      }
    } catch (e) {
      log('Error clearing cart: $e');
      throw Exception('Failed to clear cart');
    }
  }
}
