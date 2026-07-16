import 'dart:developer';
import 'package:appwrite/models.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/controllers/module_controller.dart';
import 'package:appwrite_user_app/app/helper/store_time_helper.dart';
import 'package:appwrite_user_app/app/models/order_model.dart';
import 'package:appwrite_user_app/app/modules/checkout/domain/repository/order_repo_interface.dart';
import 'package:dart_appwrite/dart_appwrite.dart';

class OrderRepository implements OrderRepoInterface {
  final AppwriteService appwriteService;

  OrderRepository({required this.appwriteService});

  /// Generates the next sequential order number (e.g. 10001, 10002, …)
  Future<String> _getNextOrderNumber() async {
    try {
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.ordersCollection,
        queries: [Query.limit(1)], // only need the total count
      );
      // response.total is the total number of documents in the collection
      final nextNumber = 10001 + response.total;
      return nextNumber.toString();
    } catch (e) {
      // Fallback: use timestamp-based if count query fails
      final now = DateTime.now();
      return '${now.millisecondsSinceEpoch}';
    }
  }

  @override
  Future<Map<String, String>> createOrder({
    required String customerId,
    required String deliveryAddress,
    required String orderItems,
    required double totalAmount,
    required double deliveryFee,
    double taxAmount = 0.0,
    double discountAmount = 0.0,
    double couponDiscount = 0.0,
    required String paymentMethod,
    String paymentStatus = 'unpaid',
    String? deliveryInstructions,
    String? deliveryType,
    DateTime? scheduledDate,
    String? scheduledTimeSlot,
    double? shippingCost,
    String? shippingMethod,
  }) async {
    try {
      // Generate sequential readable order number
      final orderNumber = await _getNextOrderNumber();

      final orderData = {
        'customer_id': customerId,
        'order_number': orderNumber,
        'status': 'pending',
        'payment_method': paymentMethod,
        'payment_status': paymentStatus,
        'total_amount': totalAmount,
        'delivery_fee': deliveryFee,
        'tax_amount': taxAmount,
        'discount_amount': discountAmount,
        'coupon_discount': couponDiscount,
        'delivery_address': deliveryAddress,
        'order_items': orderItems,
        // Store as an absolute UTC instant (the customer app is the writer, so
        // the trailing 'Z' keeps it unambiguous across devices/timezones).
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'module_type': ModuleController.current,
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
      // Resolve the chosen slot to absolute UTC start/end instants (computed in
      // the store timezone) — the machine-usable source of truth for scheduled
      // orders. scheduled_date / scheduled_time_slot above stay only as
      // human-readable display values.
      if (scheduledDate != null && scheduledTimeSlot != null) {
        final range = StoreTime.slotToUtcRange(scheduledDate, scheduledTimeSlot);
        if (range != null) {
          orderData['scheduled_start'] = range.start.toIso8601String();
          orderData['scheduled_end'] = range.end.toIso8601String();
        }
      }
      if (deliveryInstructions != null && deliveryInstructions.isNotEmpty) {
        orderData['delivery_instructions'] = deliveryInstructions;
      }
      // Ecommerce shipping snapshot.
      if (shippingCost != null) {
        orderData['shipping_cost'] = shippingCost;
      }
      if (shippingMethod != null && shippingMethod.isNotEmpty) {
        orderData['shipping_method'] = shippingMethod;
      }

      final row = await appwriteService.createRow(
        collectionId: AppwriteConfig.ordersCollection,
        data: orderData,
      );

      await appwriteService.notifyOrderPlaced(customerId, orderNumber);

      return {
        'orderId': row.$id,
        'orderNumber': orderNumber,
      };
    } catch (e) {
      log('Error creating order: $e');
      rethrow;
    }
  }

  @override
  Future<void> updatePaymentStatus(String orderId, String paymentStatus) async {
    try {
      await appwriteService.updateTable(
        tableId: AppwriteConfig.ordersCollection,
        rowId: orderId,
        data: {'payment_status': paymentStatus},
      );
    } catch (e) {
      log('Error updating payment status: $e');
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

      if ((order.driverId?.isNotEmpty ?? false) && order.deliveryman == null) {
        try {
          final driverResponse = await appwriteService.getDocument(
            tableId: AppwriteConfig.driversCollection,
            rowId: order.driverId!,
          );

          final deliveryman = DeliverymanInfo.fromJson(driverResponse.data);
          if (deliveryman.hasData) {
            order = order.copyWith(deliveryman: deliveryman);
          }
        } catch (e) {
          log('Error fetching deliveryman info: $e');
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
      await appwriteService.updateTable(
        tableId: AppwriteConfig.ordersCollection,
        rowId: orderId,
        data: {'status': 'cancelled'},
      );
    } catch (e) {
      log('Error cancelling order: $e');
      rethrow;
    }
  }
}
