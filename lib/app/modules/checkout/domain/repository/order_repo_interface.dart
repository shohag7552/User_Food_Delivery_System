import 'package:kikomart_user_app/app/models/order_model.dart';

abstract class OrderRepoInterface {
  /// Creates a new order and returns a map with:
  /// - `'orderId'`     — the Appwrite document `$id`
  /// - `'orderNumber'` — the human-readable sequential number (e.g. "10001")
  /// The server's totals for the customer's cart, as [createOrder] would
  /// charge them: subtotal, item_discount, tax, coupon_discount, delivery_fee,
  /// total. `enforced` is false while the store is still rolling the backend
  /// out, when the app's own totals are the ones charged.
  Future<Map<String, dynamic>> quoteOrder({
    required String addressId,
    String? couponId,
    String? shippingMethodId,
    String? moduleType,
  });

  /// Places the order through the backend function, which prices it from the
  /// customer's own cart rows, charges the wallet or checks the gateway
  /// payment, and numbers it. The expected amounts are what this app showed;
  /// the server refuses with `price_changed` when its own differ.
  ///
  /// [requestId] identifies one checkout attempt: repeating it returns the
  /// order already placed instead of a second one. Throws [BackendException]
  /// on refusal. Returns `orderId` and `orderNumber`.
  ///
  /// With [pendingOrderId] (a paid [startOnlineOrder]) the server writes the
  /// order from that stored checkout and ignores the other amounts sent.
  Future<Map<String, String>> createOrder({
    String? pendingOrderId,
    required String requestId,
    required String addressId,
    required String paymentMethod,
    required double totalAmount,
    required double deliveryFee,
    double taxAmount = 0.0,
    double discountAmount = 0.0,
    double couponDiscount = 0.0,
    String? couponId,
    String? shippingMethodId,
    String? paymentSessionId,
    String? paymentReference,
    String? deliveryInstructions,
    String? deliveryType, // 'now' or 'scheduled'
    DateTime? scheduledDate,
    String? scheduledTimeSlot,
    String? moduleType,
  });

  /// Card checkout, step 1: the server prices the cart and stores it as a
  /// pending order; the payment gateway then charges that stored total. The
  /// expected amounts are what this app showed (`price_changed` when they
  /// differ). Throws [BackendException] on refusal. Returns
  /// `pending_order_id`, `total_amount` and `currency_code`.
  Future<Map<String, dynamic>> startOnlineOrder({
    required String addressId,
    required double totalAmount,
    required double deliveryFee,
    double taxAmount = 0.0,
    double discountAmount = 0.0,
    double couponDiscount = 0.0,
    String? couponId,
    String? shippingMethodId,
    String? deliveryInstructions,
    String? deliveryType,
    DateTime? scheduledDate,
    String? scheduledTimeSlot,
    String? moduleType,
  });

  Future<List<OrderModel>> getUserOrders({
    String? status,
    String? searchQuery,
    int limit = 10,
    int offset = 0,
  });
  Future<OrderModel?> getOrderById(String orderId);
  Future<void> cancelOrder(String orderId);

  /// Asks the store to refund a cancelled order paid by wallet or card. The
  /// store approves it; the amount then lands in the customer's wallet.
  Future<void> requestRefund(String orderId);
}
