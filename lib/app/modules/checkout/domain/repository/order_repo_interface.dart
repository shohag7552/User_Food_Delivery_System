import 'package:appwrite_user_app/app/models/order_model.dart';

abstract class OrderRepoInterface {
  Future<void> createOrder({
    required String customerId,
    required String orderNumber,
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
