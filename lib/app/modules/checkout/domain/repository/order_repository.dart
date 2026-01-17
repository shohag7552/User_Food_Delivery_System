import 'dart:convert';
import 'dart:developer';
import 'package:appwrite/models.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/models/order_model.dart';
import 'package:appwrite_user_app/app/modules/checkout/domain/repository/order_repo_interface.dart';
import 'package:dart_appwrite/dart_appwrite.dart';

class OrderRepository implements OrderRepoInterface {
  final AppwriteService appwriteService;

  OrderRepository({required this.appwriteService});

  @override
  Future<void> createOrder({
    required String customerId,
    required String orderNumber,
    required String deliveryAddress,
    required String orderItems,
    required double totalAmount,
    required double deliveryFee,
    required String paymentMethod,
    String? deliveryInstructions,
  }) async {
    try {
      await appwriteService.createRow(
        collectionId: AppwriteConfig.ordersCollection,
        data: {
          'customer_id': customerId,
          'order_number': orderNumber,
          'status': 'pending',
          'payment_method': paymentMethod,
          'payment_status': paymentMethod == 'cod' ? 'unpaid' : 'paid',
          'total_amount': totalAmount,
          'delivery_fee': deliveryFee,
          'delivery_address': deliveryAddress,
          'order_items': orderItems,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      log('Error creating order: $e');
      rethrow;
    }
  }

  @override
  Future<List<OrderModel>> getUserOrders() async {
    try {

      User? user = await appwriteService.getCurrentUser();

      if (user == null) {
        throw Exception('User not logged in');
      }

      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.ordersCollection,
        queries: [
          Query.equal('customer_id', user.$id),
          Query.orderDesc('\$createdAt'),
        ],
      );

      return response.rows
          .map((doc) => OrderModel.fromJson(doc.data))
          .toList();
    } catch (e) {
      log('Error fetching user orders: $e');
      rethrow;
    }
  }

  @override
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final response = await appwriteService.getDocument(
        collectionId: AppwriteConfig.ordersCollection,
        documentId: orderId,
      );

      return OrderModel.fromJson(response.data);
    } catch (e) {
      log('Error fetching order: $e');
      return null;
    }
  }
}
