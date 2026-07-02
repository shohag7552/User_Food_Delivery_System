import 'package:appwrite_user_app/app/common/widgets/hover_lift.dart';
import 'package:appwrite_user_app/app/controllers/order_controller.dart';
import 'package:appwrite_user_app/app/helper/currency_helper.dart';
import 'package:appwrite_user_app/app/models/order_model.dart';
import 'package:appwrite_user_app/app/modules/orders/screens/order_detail_page.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

    Get.find<OrderController>().initialSetup();

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

  // Web/desktop layout kicks in above this width.
  static const double _webBreakpoint = 900;
  static const double _maxContentWidth = 1200;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _webBreakpoint;
    // As a dashboard tab on web the shared top-nav is already shown, so drop the
    // page's own app bar — unless this page was pushed as a standalone route.
    final hideAppBar = kIsWeb && !Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: ColorResource.scaffoldBackground,
      appBar: hideAppBar
          ? null
          : AppBar(
              title: Text(
                'my_orders'.tr,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeLarge,
                  color: ColorResource.textWhite,
                ),
              ),
              backgroundColor: ColorResource.primaryDark,
              elevation: 0,
            ),
      body: isWide
          ? _buildWebBody(hideAppBar)
          : Column(
              children: [
                _buildFilterChips(),
                Expanded(child: _buildOrdersList(false)),
              ],
            ),
    );
  }

  Widget _buildWebBody(bool showInlineTitle) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showInlineTitle)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'my_orders'.tr,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeOverLarge,
                    color: ColorResource.textPrimary,
                  ),
                ),
              ),
            _buildFilterChips(),
            Expanded(child: _buildOrdersList(true)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(bool isWide) {
    return GetBuilder<OrderController>(
      builder: (controller) {
        if (controller.isLoading && controller.orders.isEmpty) {
          return _buildLoadingState();
        }

        if (controller.orders.isEmpty) {
          return _buildEmptyState();
        }

        return isWide
            ? _buildOrdersGrid(controller)
            : _buildOrdersListView(controller);
      },
    );
  }

  // Mobile: single-column list.
  Widget _buildOrdersListView(OrderController controller) {
    return RefreshIndicator(
      onRefresh: controller.refreshOrders,
      color: ColorResource.primaryDark,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, Constants.bottomNavSpace),
        itemCount: controller.orders.length + (controller.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.orders.length) {
            return _buildLoadMoreIndicator(controller);
          }
          return _buildOrderCard(controller.orders[index]);
        },
      ),
    );
  }

  // Web: responsive grid. A Wrap lets each card keep its natural height (no
  // overflow), while the column count adapts to the available width.
  Widget _buildOrdersGrid(OrderController controller) {
    return RefreshIndicator(
      onRefresh: controller.refreshOrders,
      color: ColorResource.primaryDark,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(8, 16, 8, Constants.bottomNavSpace),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = width >= 1080
                    ? 3
                    : width >= 680
                        ? 2
                        : 1;
                const spacing = 16.0;
                final itemWidth =
                    (width - (columns - 1) * spacing) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: 0, // each card carries its own bottom margin
                  children: [
                    for (final order in controller.orders)
                      SizedBox(
                        width: itemWidth,
                        child: HoverLift(child: _buildOrderCard(order)),
                      ),
                  ],
                );
              },
            ),
            _buildLoadMoreIndicator(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'all'.tr, 'value': 'all'},
      {'label': 'pending'.tr, 'value': 'pending'},
      {'label': 'cooking'.tr, 'value': 'cooking'},
      {'label': 'ready'.tr, 'value': 'ready'},
      {'label': 'handover'.tr, 'value': 'handover'},
      {'label': 'on_the_way'.tr, 'value': 'on_way'},
      {'label': 'delivered'.tr, 'value': 'delivered'},
      {'label': 'cancelled'.tr, 'value': 'cancelled'},
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
            'loading_your_orders'.tr,
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
                  isFiltered ? 'no_orders_found'.tr : 'no_orders_yet'.tr,
                  style: poppinsBold.copyWith(
                    fontSize: 24,
                    color: ColorResource.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isFiltered
                      ? 'try_adjusting_filters'.tr
                      : 'start_ordering_food'.tr,
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
                    label: Text('browse_menu'.tr),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OrderDetailPage(
                orderId: order.id,
                initialOrder: order,
              ),
            ),
          );
        },
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
                          '#${order.orderNumber}',
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
                    '${order.items.length} ${order.items.length == 1 ? 'item'.tr : 'items'.tr}',
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
                        'total_payable'.tr,
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
                          'delivery_address'.tr,
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
        label = 'pending'.tr;
        break;
      case 'cooking':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        icon = Icons.restaurant;
        label = 'cooking'.tr;
        break;
      case 'ready':
        backgroundColor = Colors.cyan.shade100;
        textColor = Colors.cyan.shade700;
        icon = Icons.done_all;
        label = 'ready'.tr;
        break;
      case 'handover':
        backgroundColor = Colors.indigo.shade100;
        textColor = Colors.indigo.shade700;
        icon = Icons.handshake;
        label = 'handover'.tr;
        break;
      case 'on_way':
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade700;
        icon = Icons.delivery_dining;
        label = 'on_the_way'.tr;
        break;
      case 'delivered':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        label = 'delivered'.tr;
        break;
      case 'cancelled':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        icon = Icons.cancel;
        label = 'cancelled'.tr;
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
