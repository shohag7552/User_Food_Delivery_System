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
    String? deliveryType,
    DateTime? scheduledDate,
    String? scheduledTimeSlot,
  }) async {
    try {
      final orderData = {
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
      };

      // Add delivery schedule information if provided
      if (deliveryType != null) {
        orderData['delivery_type'] = deliveryType;
      }
      if (scheduledDate != null) {
        orderData['scheduled_date'] = scheduledDate.toIso8601String();
      }
      if (scheduledTimeSlot != null) {
        orderData['scheduled_time_slot'] = scheduledTimeSlot;
      }
      if (deliveryInstructions != null && deliveryInstructions.isNotEmpty) {
        orderData['delivery_instructions'] = deliveryInstructions;
      }

      await appwriteService.createRow(
        collectionId: AppwriteConfig.ordersCollection,
        data: orderData,
      );
    } catch (e) {
      log('Error creating order: $e');
      rethrow;
    }
  }

  @override
  Future<List<OrderModel>> getUserOrders({
    String? status,
    String? searchQuery,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      User? user = await appwriteService.getCurrentUser();

      if (user == null) {
        throw Exception('User not logged in');
      }

      // Build queries dynamically
      List<String> queries = [
        Query.equal('customer_id', user.$id),
        Query.orderDesc('\$createdAt'),
      ];

      // Add status filter if provided
      if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
        queries.add(Query.equal('status', status.toLowerCase()));
      }

      // Add search query if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queries.add(Query.search('order_number', searchQuery));
      }

      // Add pagination
      queries.add(Query.limit(limit));
      queries.add(Query.offset(offset));

      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.ordersCollection,
        queries: queries,
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
