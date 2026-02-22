import 'package:appwrite_user_app/app/models/order_model.dart';

abstract class OrderRepoInterface {
  /// Creates a new order and returns the generated readable order number (e.g. "10001").
  Future<String> createOrder({
    required String customerId,
    required String deliveryAddress,
    required String orderItems,
    required double totalAmount,
    required double deliveryFee,
    required String paymentMethod,
    String? deliveryInstructions,
    String? deliveryType, // 'now' or 'scheduled'
    DateTime? scheduledDate,
    String? scheduledTimeSlot,
  });
  
  /// Get user's orders with optional filtering, search, and pagination
  Future<List<OrderModel>> getUserOrders({
    String? status,
    String? searchQuery,
    int limit = 10,
    int offset = 0,
  });
  Future<OrderModel?> getOrderById(String orderId);
}
