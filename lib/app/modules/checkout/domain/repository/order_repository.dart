import 'dart:developer';
import 'package:appwrite/models.dart';
import 'package:kikomart_user_app/app/appwrite/appwrite_config.dart';
import 'package:kikomart_user_app/app/appwrite/appwrite_service.dart';
import 'package:kikomart_user_app/app/controllers/module_controller.dart';
import 'package:kikomart_user_app/app/helper/store_time_helper.dart';
import 'package:kikomart_user_app/app/models/order_model.dart';
import 'package:kikomart_user_app/app/modules/checkout/domain/repository/order_repo_interface.dart';
import 'package:appwrite/appwrite.dart';

class OrderRepository implements OrderRepoInterface {
  final AppwriteService appwriteService;

  OrderRepository({required this.appwriteService});

  @override
  Future<Map<String, dynamic>> quoteOrder({
    required String addressId,
    String? couponId,
    String? shippingMethodId,
    String? moduleType,
  }) {
    return appwriteService.callBackend('quote_order', {
      'address_id': addressId,
      'module_type': moduleType ?? ModuleController.current,
      'coupon_id': ?couponId,
      'shipping_method_id': ?shippingMethodId,
    });
  }

  @override
  Future<Map<String, String>> createOrder({
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
    String? deliveryType,
    DateTime? scheduledDate,
    String? scheduledTimeSlot,
    String? moduleType,
  }) async {
    final body = <String, dynamic>{
      'request_id': requestId,
      'address_id': addressId,
      'payment_method': paymentMethod,
      'module_type': moduleType ?? ModuleController.current,
      'expected_total': totalAmount,
      'expected_delivery_fee': deliveryFee,
      'expected_tax': taxAmount,
      'expected_item_discount': discountAmount,
      'expected_coupon_discount': couponDiscount,
      'coupon_id': ?couponId,
      'shipping_method_id': ?shippingMethodId,
      'payment_session_id': ?paymentSessionId,
      'payment_reference': ?paymentReference,
      'delivery_type': ?deliveryType,
      'scheduled_date': ?scheduledDate?.toIso8601String(),
      'scheduled_time_slot': ?scheduledTimeSlot,
    };
    if (deliveryInstructions != null && deliveryInstructions.isNotEmpty) {
      body['delivery_instructions'] = deliveryInstructions;
    }
    // Resolve the chosen slot to absolute UTC start/end instants (computed in
    // the store timezone) — the machine-usable source of truth for scheduled
    // orders. scheduled_date / scheduled_time_slot stay only as human-readable
    // display values.
    if (scheduledDate != null && scheduledTimeSlot != null) {
      final range = StoreTime.slotToUtcRange(scheduledDate, scheduledTimeSlot);
      if (range != null) {
        body['scheduled_start'] = range.start.toIso8601String();
        body['scheduled_end'] = range.end.toIso8601String();
      }
    }

    final result = await appwriteService.callBackend('place_order', body);
    final orderId = result['order_id']?.toString() ?? '';
    final orderNumber = result['order_number']?.toString() ?? '';

    final user = await appwriteService.getCurrentUser();
    if (user != null) {
      await appwriteService.notifyOrderPlaced(user.$id, orderNumber);
    }

    return {'orderId': orderId, 'orderNumber': orderNumber};
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
        Query.equal('module_type', ModuleController.current),
        Query.orderDesc('\$createdAt'),
      ];

      // Add status filter if provided
      if (status != null &&
          status.isNotEmpty &&
          status.toLowerCase() != 'all') {
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

      return response.rows.map((doc) => OrderModel.fromJson(doc.data)).toList();
    } catch (e) {
      log('Error fetching user orders: $e');
      rethrow;
    }
  }

  @override
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final response = await appwriteService.getDocument(
        tableId: AppwriteConfig.ordersCollection,
        rowId: orderId,
      );

      OrderModel order = OrderModel.fromJson(response.data);

      // The order carries the driver's name, phone and photo from the moment
      // they accepted; their position comes from the backend, because the
      // drivers table (every driver's earnings) is not readable by customers.
      if ((order.driverId?.isNotEmpty ?? false) &&
          !(order.deliveryman?.hasLocation ?? false)) {
        try {
          final driver = await appwriteService.callBackend('driver_summary', {
            'driver_id': order.driverId,
          });
          final deliveryman = DeliverymanInfo.fromJson(driver);
          if (deliveryman.hasData) {
            order = order.copyWith(deliveryman: deliveryman);
          }
        } catch (e) {
          log('Error fetching deliveryman info: $e');
        }
      }

      // New orders keep the delivery code in order_codes, out of drivers'
      // sight; older ones still carry it on the order.
      if ((order.deliveryVerificationCode ?? '').isEmpty) {
        try {
          final code = await appwriteService.getDocument(
            tableId: AppwriteConfig.orderCodesCollection,
            rowId: orderId,
          );
          order = order.copyWith(
            deliveryVerificationCode: code.data['code']?.toString(),
          );
        } catch (_) {
          // No code for this order (counter sales, older orders).
        }
      }

      return order;
    } catch (e) {
      log('Error fetching order: $e');
      return null;
    }
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    try {
      // Through the backend, which allows it only while the order is pending.
      await appwriteService.callBackend('cancel_order', {'order_id': orderId});
    } catch (e) {
      log('Error cancelling order: $e');
      rethrow;
    }
  }

  @override
  Future<void> requestRefund(String orderId) async {
    try {
      await appwriteService.callBackend('request_refund', {'order_id': orderId});
    } catch (e) {
      log('Error requesting refund: $e');
      rethrow;
    }
  }
}
