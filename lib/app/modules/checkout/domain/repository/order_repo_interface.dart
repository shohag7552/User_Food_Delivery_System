import 'package:appwrite_user_app/app/models/order_model.dart';

abstract class OrderRepoInterface {
  /// Creates a new order and returns a map with:
  /// - `'orderId'`     — the Appwrite document `$id`
  /// - `'orderNumber'` — the human-readable sequential number (e.g. "10001")
  Future<Map<String, String>> createOrder({
    required String customerId,
    required String deliveryAddress,
    required String orderItems,
    required double totalAmount,
    required double deliveryFee,
    double taxAmount = 0.0,
    required String paymentMethod,
    String paymentStatus = 'unpaid',
    String? deliveryInstructions,
    String? deliveryType, // 'now' or 'scheduled'
    DateTime? scheduledDate,
    String? scheduledTimeSlot,
  });

  /// Updates the payment status of an existing order.
  Future<void> updatePaymentStatus(String orderId, String paymentStatus);

  /// Get user's orders with optional filtering, search, and pagination
  Future<List<OrderModel>> getUserOrders({
    String? status,
    String? searchQuery,
    int limit = 10,
    int offset = 0,
  });
  Future<OrderModel?> getOrderById(String orderId);
  Future<void> cancelOrder(String orderId);
}
