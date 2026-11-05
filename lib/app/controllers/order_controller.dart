import 'dart:async';
import 'dart:developer';
import 'package:kikomart_user_app/app/appwrite/backend_exception.dart';
import 'package:kikomart_user_app/app/controllers/cart_controller.dart';
import 'package:kikomart_user_app/app/controllers/flash_sale_controller.dart';
import 'package:kikomart_user_app/app/controllers/product_controller.dart';
import 'package:kikomart_user_app/app/helper/session_manager.dart';
import 'package:kikomart_user_app/app/models/address_model.dart';
import 'package:kikomart_user_app/app/models/cart_item_model.dart';
import 'package:kikomart_user_app/app/models/order_model.dart';
import 'package:kikomart_user_app/app/modules/checkout/domain/repository/order_repo_interface.dart';
import 'package:get/get.dart';

class OrderController extends GetxController implements GetxService {
  final OrderRepoInterface orderRepoInterface;

  OrderController({required this.orderRepoInterface});

  List<OrderModel> _orders = [];
  OrderModel? _selectedOrder;
  bool _isLoading = false;
  bool _isPlacingOrder = false;
  bool _isLoadingMore = false;
  bool _isOrderDetailsLoading = false;
  bool _isCancellingOrder = false;

  // Filter and search state
  String _selectedStatus = 'all';
  String _searchQuery = '';
  Timer? _debounce;

  // Pagination state
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _hasMore = true;

  List<OrderModel> get orders => _orders;
  OrderModel? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  bool get isPlacingOrder => _isPlacingOrder;
  bool get isLoadingMore => _isLoadingMore;
  bool get isOrderDetailsLoading => _isOrderDetailsLoading;
  bool get isCancellingOrder => _isCancellingOrder;

  bool _isRequestingRefund = false;
  bool get isRequestingRefund => _isRequestingRefund;
  String get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;
  bool get hasMore => _hasMore;

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  void initialSetup() {
    _selectedStatus = 'all';
    fetchUserOrders(refresh: true);
  }

  /// Resets the module-scoped view state ahead of a storefront switch.
  ///
  /// The status filter is written in the active module's vocabulary — food
  /// orders go cooking → ready → handover, shop orders go packing → shipped —
  /// so a filter carried across the switch selects a status the incoming module
  /// never uses. The list comes back empty with no chip highlighted and nothing
  /// on screen explaining why. Clearing it lands the customer on "All", which
  /// is the only filter both vocabularies share.
  void clearForModuleSwitch() {
    _selectedStatus = 'all';
    _searchQuery = '';
    _debounce?.cancel();
    _currentPage = 0;
    _hasMore = true;
    // No update() — the caller refetches immediately and updates once.
  }

  /// Place a new order.
  ///
  /// The backend function prices it from the customer's cart, takes the
  /// payment (wallet) or checks it (gateway), and writes it; the totals passed
  /// here are what the customer was shown, and a disagreement comes back as
  /// `prices_changed_review_order` with `code: 'price_changed'`.
  ///
  /// [requestId] names this checkout attempt, so retrying it can never place
  /// a second order.
  Future<Map<String, dynamic>> placeOrder({
    required String requestId,
    required AddressModel address,
    required List<CartItemModel> cartItems,
    required double totalAmount,
    required double deliveryFee,
    double taxAmount = 0.0,
    double discountAmount = 0.0,
    double couponDiscount = 0.0,
    required String paymentMethod,
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
    // An order with no lines is not an order. The checkout screen already hides
    // its button behind an empty-cart state, but that is a rendering decision
    // made before the taps — the cart can still be emptied during the
    // confirmation dialog, and the order-failed page's retry re-enters the flow
    // long after the screen stopped gating it. This is the rule itself, so it
    // holds for whatever calls in.
    if (cartItems.isEmpty) {
      return {'success': false, 'error': 'cannot_place_order_empty_cart'.tr};
    }

    try {
      _isPlacingOrder = true;
      update();

      final result = await orderRepoInterface.createOrder(
        requestId: requestId,
        addressId: address.id,
        paymentMethod: paymentMethod,
        totalAmount: totalAmount,
        deliveryFee: deliveryFee,
        taxAmount: taxAmount,
        discountAmount: discountAmount,
        couponDiscount: couponDiscount,
        couponId: couponId,
        shippingMethodId: shippingMethodId,
        paymentSessionId: paymentSessionId,
        paymentReference: paymentReference,
        deliveryInstructions: deliveryInstructions,
        deliveryType: deliveryType,
        scheduledDate: scheduledDate,
        scheduledTimeSlot: scheduledTimeSlot,
        moduleType: moduleType,
      );

      _isPlacingOrder = false;
      update();
      return {
        'success': true,
        'orderId': result['orderId'],
        'orderNumber': result['orderNumber'],
      };
    } on BackendException catch (e) {
      _isPlacingOrder = false;
      update();
      log('Order refused: $e');
      return {
        'success': false,
        'code': e.code,
        'error': _placeOrderErrorKey(e.code).tr,
      };
    } catch (e) {
      _isPlacingOrder = false;
      update();
      log('Error placing order: $e');
      return {'success': false, 'error': 'failed_to_place_order'.tr};
    }
  }

  /// What the order costs as the server prices it — the amounts to show,
  /// charge and confirm — or null when they cannot be had (the server is
  /// unreachable, or an item can no longer be priced; [quoteError] says why).
  ///
  /// Returns the app's own figures unchanged while the server's are not yet
  /// binding (`enforced` false during a store's rollout).
  Future<OrderQuote?> quoteOrder({
    required AddressModel address,
    required OrderQuote fallback,
    String? couponId,
    String? shippingMethodId,
  }) async {
    _quoteError = null;
    try {
      final q = await orderRepoInterface.quoteOrder(
        addressId: address.id,
        couponId: couponId,
        shippingMethodId: shippingMethodId,
      );
      if (q['enforced'] != true) return fallback;
      double n(String k) => (q[k] as num?)?.toDouble() ?? 0.0;
      return OrderQuote(
        total: n('total'),
        deliveryFee: n('delivery_fee'),
        tax: n('tax'),
        itemDiscount: n('item_discount'),
        couponDiscount: n('coupon_discount'),
      );
    } on BackendException catch (e) {
      log('Quote refused: $e');
      _quoteError = _placeOrderErrorKey(e.code).tr;
      return null;
    } catch (e) {
      log('Quote failed: $e');
      _quoteError = 'failed_to_place_order'.tr;
      return null;
    }
  }

  String? _quoteError;

  /// Why the last [quoteOrder] returned null, translated.
  String? get quoteError => _quoteError;

  /// The message for each reason the backend refuses an order.
  static String _placeOrderErrorKey(String code) => switch (code) {
    'price_changed' => 'prices_changed_review_order',
    'insufficient_wallet' => 'insufficient_wallet_balance',
    'payment_unverified' || 'payment_already_used' => 'payment_failed_try_again',
    'cart_item_unavailable' || 'cart_item_changed' => 'cart_item_no_longer_available',
    'cart_empty' => 'cannot_place_order_empty_cart',
    'address_required' => 'please_select_delivery_address',
    _ => 'failed_to_place_order',
  };

  /// Runs the bookkeeping that follows an order actually being written: sale
  /// counters first, then emptying the cart it came from.
  ///
  /// Shared because an order now completes in two places — the checkout screen
  /// on mobile, and the payment-return route the web redirect lands on — and a
  /// cart left unemptied on one of those paths would be reordered by mistake.
  Future<void> finalizePlacedOrder(List<CartItemModel> cartItems) async {
    // Capture the lines before the cart is cleared out from under them.
    final items = List.of(cartItems);

    await Get.find<ProductController>().recordSaleForItems(items);
    // Flash sale sold counters (best effort — no-op when no sale is live).
    if (Get.isRegistered<FlashSaleController>()) {
      unawaited(Get.find<FlashSaleController>().recordSoldItems(items));
    }

    final cartController = Get.find<CartController>();
    await cartController.clearCart();
    cartController.removeCoupon();
  }

  /// Fetch user's orders with current filters
  Future<void> fetchUserOrders({bool refresh = false}) async {
    // Auth-required: never hit Appwrite for a guest.
    if (!isUserLoggedIn()) {
      _orders = [];
      update();
      return;
    }
    try {
      if (refresh) {
        _currentPage = 0;
        _hasMore = true;
      }

      _isLoading = true;
      update();

      final fetchedOrders = await orderRepoInterface.getUserOrders(
        status: _selectedStatus == 'all' ? null : _selectedStatus,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (refresh) {
        _orders = fetchedOrders;
      } else {
        _orders.addAll(fetchedOrders);
      }

      // Check if there are more orders to load
      _hasMore = fetchedOrders.length >= _pageSize;

      _isLoading = false;
      update();
    } catch (e) {
      _isLoading = false;
      update();
      log('Error fetching orders: $e');
    }
  }

  /// Load more orders (pagination)
  Future<void> loadMoreOrders() async {
    if (!isUserLoggedIn()) return;
    if (_isLoadingMore || !_hasMore) return;

    try {
      _isLoadingMore = true;
      update();

      _currentPage++;

      final fetchedOrders = await orderRepoInterface.getUserOrders(
        status: _selectedStatus == 'all' ? null : _selectedStatus,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      _orders.addAll(fetchedOrders);
      _hasMore = fetchedOrders.length >= _pageSize;

      _isLoadingMore = false;
      update();
    } catch (e) {
      _isLoadingMore = false;
      _currentPage--; // Revert page increment on error
      update();
      log('Error loading more orders: $e');
    }
  }

  /// Filter orders by status
  void filterByStatus(String status) {
    if (_selectedStatus == status) return;

    _selectedStatus = status;
    _currentPage = 0;
    _hasMore = true;
    fetchUserOrders(refresh: true);
  }

  /// Search orders with debounce
  void searchOrders(String query) {
    _searchQuery = query;

    // Cancel previous debounce timer
    _debounce?.cancel();

    // Set new debounce timer
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _currentPage = 0;
      _hasMore = true;
      fetchUserOrders(refresh: true);
    });

    update(); // Update UI to show search query immediately
  }

  /// Refresh orders
  Future<void> refreshOrders() async {
    await fetchUserOrders(refresh: true);
  }

  Future<OrderModel?> fetchOrderDetails(
    String orderId, {
    bool showLoader = true,
  }) async {
    // Auth-required: never hit Appwrite for a guest.
    if (!isUserLoggedIn()) return null;
    try {
      if (showLoader) {
        _isOrderDetailsLoading = true;
        _selectedOrder = null;
      }

      final order = await orderRepoInterface.getOrderById(orderId);
      _selectedOrder = order;
      _isOrderDetailsLoading = false;
      update();
      return order;
    } catch (e) {
      _isOrderDetailsLoading = false;
      update();
      log('Error fetching order details: $e');
      return null;
    }
  }

  Future<void> refreshOrderDetails(String orderId) async {
    await fetchOrderDetails(orderId, showLoader: false);
  }

  /// Whether [order] may ask for a refund: cancelled, paid from the wallet or
  /// by card, and not asked before. The server checks the same rule.
  bool canRequestRefund(OrderModel order) {
    final method = order.paymentMethod.toLowerCase();
    return order.status.toLowerCase() == 'cancelled' &&
        order.paymentStatus.toLowerCase() == 'paid' &&
        (method == 'wallet' || method == 'online') &&
        order.refundStatus.isEmpty &&
        order.totalAmount > 0;
  }

  Future<bool> requestRefund(String orderId) async {
    try {
      _isRequestingRefund = true;
      update();

      await orderRepoInterface.requestRefund(orderId);

      if (_selectedOrder?.id == orderId) {
        _selectedOrder = _selectedOrder!.copyWith(refundStatus: 'requested');
      }
      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex != -1) {
        _orders[orderIndex] =
            _orders[orderIndex].copyWith(refundStatus: 'requested');
      }
      return true;
    } catch (e) {
      log('Error requesting refund: $e');
      return false;
    } finally {
      _isRequestingRefund = false;
      update();
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    try {
      _isCancellingOrder = true;
      update();

      await orderRepoInterface.cancelOrder(orderId);

      if (_selectedOrder?.id == orderId) {
        _selectedOrder = _selectedOrder!.copyWith(status: 'cancelled');
      }

      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex != -1) {
        _orders[orderIndex] = _orders[orderIndex].copyWith(status: 'cancelled');
      }

      _isCancellingOrder = false;
      update();
      return true;
    } catch (e) {
      _isCancellingOrder = false;
      update();
      log('Error cancelling order: $e');
      return false;
    }
  }
}

/// The amounts an order is shown, confirmed and charged with.
class OrderQuote {
  final double total;
  final double deliveryFee;
  final double tax;
  final double itemDiscount;
  final double couponDiscount;

  const OrderQuote({
    required this.total,
    required this.deliveryFee,
    required this.tax,
    required this.itemDiscount,
    required this.couponDiscount,
  });
}
