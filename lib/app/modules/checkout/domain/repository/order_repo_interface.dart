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
  });
  
  Future<List<OrderModel>> getUserOrders();
  Future<OrderModel?> getOrderById(String orderId);
}
