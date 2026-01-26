import 'package:appwrite_user_app/app/controllers/order_controller.dart';
import 'package:appwrite_user_app/app/helper/currency_helper.dart';
import 'package:appwrite_user_app/app/models/order_model.dart';
import 'package:appwrite_user_app/app/modules/orders/screens/order_detail_page.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    Get.find<OrderController>().fetchUserOrders(refresh: true);

    // Listen to scroll for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Nearly reached bottom, load more
      Get.find<OrderController>().loadMoreOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResource.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeLarge,
            color: ColorResource.textWhite,
          ),
        ),
        backgroundColor: ColorResource.primaryDark,
        elevation: 0,
      ),
      body: Column(
        children: [

          // Filter Chips
          _buildFilterChips(),

          // Orders List
          Expanded(
            child: GetBuilder<OrderController>(
              builder: (controller) {
                if (controller.isLoading && controller.orders.isEmpty) {
                  return _buildLoadingState();
                }

                if (controller.orders.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: controller.refreshOrders,
                  color: ColorResource.primaryDark,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.orders.length + (controller.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == controller.orders.length) {
                        // Loading indicator at bottom
                        return _buildLoadMoreIndicator(controller);
                      }
                      final order = controller.orders[index];
                      return _buildOrderCard(order);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'All', 'value': 'all'},
      {'label': 'Pending', 'value': 'pending'},
      {'label': 'Cooking', 'value': 'cooking'},
      {'label': 'Ready', 'value': 'ready'},
      {'label': 'Handover', 'value': 'handover'},
      {'label': 'On the Way', 'value': 'on_way'},
      {'label': 'Delivered', 'value': 'delivered'},
      {'label': 'Cancelled', 'value': 'cancelled'},
    ];

    return GetBuilder<OrderController>(
      builder: (controller) {
        return Container(
          color: ColorResource.cardBackground,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: filters.map((filter) {
                final isSelected = controller.selectedStatus == filter['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(
                    label: filter['label']!,
                    value: filter['value']!,
                    isSelected: isSelected,
                    onTap: () => controller.filterByStatus(filter['value']!),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? ColorResource.primaryGradient : null,
          color: isSelected ? null : ColorResource.scaffoldBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : ColorResource.shadowLight,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: poppinsMedium.copyWith(
            fontSize: Constants.fontSizeSmall,
            color: isSelected ? ColorResource.textWhite : ColorResource.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: ColorResource.primaryDark,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your orders...',
            style: poppinsMedium.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: ColorResource.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator(OrderController controller) {
    if (!controller.isLoadingMore) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: CircularProgressIndicator(
          color: ColorResource.primaryDark,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return GetBuilder<OrderController>(
      builder: (controller) {
        final isFiltered = controller.selectedStatus != 'all' || controller.searchQuery.isNotEmpty;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: ColorResource.primaryDark.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFiltered ? Icons.search_off : Icons.receipt_long_outlined,
                    size: 60,
                    color: ColorResource.textLight,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isFiltered ? 'No Orders Found' : 'No Orders Yet',
                  style: poppinsBold.copyWith(
                    fontSize: 24,
                    color: ColorResource.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isFiltered
                      ? 'Try adjusting your filters or search query'
                      : 'Start ordering delicious food and\nyour orders will appear here',
                  textAlign: TextAlign.center,
                  style: poppinsRegular.copyWith(
                    fontSize: Constants.fontSizeDefault,
                    color: ColorResource.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                if (!isFiltered)
                  ElevatedButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('Browse Menu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorResource.primaryDark,
                      foregroundColor: ColorResource.textWhite,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Constants.radiusLarge),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return GestureDetector(
      onTap: () => Get.to(() => OrderDetailPage(order: order)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: ColorResource.cardBackground,
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          boxShadow: ColorResource.customShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Order ID, Date, and Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorResource.primaryDark.withValues(alpha: 0.05),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(Constants.radiusLarge),
                  topRight: Radius.circular(Constants.radiusLarge),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNumber,
                          style: poppinsBold.copyWith(
                            fontSize: Constants.fontSizeDefault,
                            color: ColorResource.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: ColorResource.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
                              style: poppinsRegular.copyWith(
                                fontSize: Constants.fontSizeSmall,
                                color: ColorResource.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(order.status),
                ],
              ),
            ),

            // Order Items Summary
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 20,
                    color: ColorResource.primaryDark,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${order.items.length} ${order.items.length == 1 ? 'Item' : 'Items'}',
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeLarge,
                      color: ColorResource.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Payable',
                        style: poppinsRegular.copyWith(
                          fontSize: Constants.fontSizeSmall,
                          color: ColorResource.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyHelper.formatAmount(order.totalAmount),
                        style: poppinsBold.copyWith(
                          fontSize: Constants.fontSizeExtraLarge,
                          color: ColorResource.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Delivery Address
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: ColorResource.primaryDark,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Address',
                          style: poppinsBold.copyWith(
                            fontSize: Constants.fontSizeDefault,
                            color: ColorResource.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.address.street,
                          style: poppinsRegular.copyWith(
                            fontSize: Constants.fontSizeSmall,
                            color: ColorResource.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        icon = Icons.schedule;
        label = 'Pending';
        break;
      case 'cooking':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        icon = Icons.restaurant;
        label = 'Cooking';
        break;
      case 'ready':
        backgroundColor = Colors.cyan.shade100;
        textColor = Colors.cyan.shade700;
        icon = Icons.done_all;
        label = 'Ready';
        break;
      case 'handover':
        backgroundColor = Colors.indigo.shade100;
        textColor = Colors.indigo.shade700;
        icon = Icons.handshake;
        label = 'Handover';
        break;
      case 'on_way':
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade700;
        icon = Icons.delivery_dining;
        label = 'On the Way';
        break;
      case 'delivered':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        label = 'Delivered';
        break;
      case 'cancelled':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        icon = Icons.cancel;
        label = 'Cancelled';
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        icon = Icons.info;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeSmall,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
