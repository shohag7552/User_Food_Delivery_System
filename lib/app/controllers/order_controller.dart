import 'dart:async';
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
  bool _isLoadingMore = false;
  
  // Filter and search state
  String _selectedStatus = 'all';
  String _searchQuery = '';
  Timer? _debounce;
  
  // Pagination state
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _hasMore = true;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  bool get isPlacingOrder => _isPlacingOrder;
  bool get isLoadingMore => _isLoadingMore;
  String get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;
  bool get hasMore => _hasMore;

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

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

  /// Fetch user's orders with current filters
  Future<void> fetchUserOrders({bool refresh = false}) async {
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
}
