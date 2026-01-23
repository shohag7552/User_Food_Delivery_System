import 'dart:convert';
import 'dart:developer';
import 'package:appwrite_user_app/app/models/address_model.dart';
import 'package:appwrite_user_app/app/models/cart_item_model.dart';
import 'package:appwrite_user_app/app/models/order_model.dart';
import 'package:appwrite_user_app/app/modules/checkout/domain/repository/order_repo_interface.dart';
import 'package:get/get.dart';

class OrderController extends GetxController implements GetxService {
  final OrderRepoInterface orderRepoInterface;

  OrderController({required this.orderRepoInterface});

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  bool _isPlacingOrder = false;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  bool get isPlacingOrder => _isPlacingOrder;

  /// Place a new order
  Future<Map<String, dynamic>> placeOrder({
    required String customerId,
    required AddressModel address,
    required List<CartItemModel> cartItems,
    required double totalAmount,
    required double deliveryFee,
    required String paymentMethod,
    String? deliveryInstructions,
    String? deliveryType,
    DateTime? scheduledDate,
    String? scheduledTimeSlot,
  }) async {
    try {
      _isPlacingOrder = true;
      update();

      // Convert address to JSON
      final addressJson = jsonEncode({
        'name': address.name,
        'phone': address.phone,
        'address': address.fullAddress,
        'lat': 0.0, // TODO: Add lat/lng to AddressModel if needed
        'lng': 0.0,
      });

      // Convert cart items to order items JSON
      final orderItems = cartItems.map((item) {
        return {
          'product_name': item.productName,
          'price': item.finalPrice,
          'quantity': item.quantity,
          'selected_variants': item.selectedVariants
              .expand((v) => v.selections)
              .map((s) => s.optionName)
              .toList(),
        };
      }).toList();

      final orderItemsJson = jsonEncode(orderItems);

      // Generate readable order number: ORD-YYYYMMDD-XXX
      final now = DateTime.now();
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final timeStr = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final orderNumber = 'ORD-$dateStr-$timeStr';

      await orderRepoInterface.createOrder(
        customerId: customerId,
        orderNumber: orderNumber,
        deliveryAddress: addressJson,
        orderItems: orderItemsJson,
        totalAmount: totalAmount,
        deliveryFee: deliveryFee,
        paymentMethod: paymentMethod,
        deliveryInstructions: deliveryInstructions,
        deliveryType: deliveryType,
        scheduledDate: scheduledDate,
        scheduledTimeSlot: scheduledTimeSlot,
      );

      _isPlacingOrder = false;
      update();
      return {'success': true, 'orderNumber': orderNumber};
    } catch (e) {
      _isPlacingOrder = false;
      update();
      log('Error placing order: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Fetch user's orders
  Future<void> fetchUserOrders() async {
    try {
      _isLoading = true;
      update();

      _orders = await orderRepoInterface.getUserOrders();

      _isLoading = false;
      update();
    } catch (e) {
      _isLoading = false;
      update();
      log('Error fetching orders: $e');
    }
  }
}
