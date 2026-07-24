import 'package:appwrite_user_app/app/common/widgets/auth_gate.dart';
import 'package:appwrite_user_app/app/common/widgets/hover_lift.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/order_controller.dart';
import 'package:appwrite_user_app/app/helper/currency_helper.dart';
import 'package:appwrite_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/models/order_model.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:appwrite_user_app/app/common/widgets/directional_flip.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:appwrite_user_app/app/helper/store_time_helper.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedFilter = 'all'; // 'all', 'delivered', 'cancelled'

  // Web/desktop layout kicks in above this width.
  static const double _webBreakpoint = 900;
  static const double _maxContentWidth = 1200;

  // Tracks the web/desktop layout so scroll-driven pagination stays mobile-only;
  // web loads the next page via the explicit "View more" button instead.
  bool _isWide = false;

  @override
  void initState() {
    super.initState();

    // Fetch only delivered and cancelled orders
    final controller = Get.find<OrderController>();
    controller.filterByStatus('delivered');

    // Listen to scroll for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Web paginates via the "View more" button, so skip scroll auto-load there.
    if (_isWide) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Nearly reached bottom, load more
      Get.find<OrderController>().loadMoreOrders();
    }
  }

  void _filterOrders(String filter) {
    setState(() {
      _selectedFilter = filter;
    });

    final controller = Get.find<OrderController>();
    if (filter == 'all') {
      // Show both delivered and cancelled - we'll need to fetch them separately and combine
      controller.filterByStatus('delivered');
    } else {
      controller.filterByStatus(filter);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _webBreakpoint;
    _isWide = isWide;
    // Desktop web keeps the shared top-nav + account drawer; mobile/tablet use
    // the page's own app bar with a back button.
    final showWebNav = WebTopNav.isEnabled(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.scaffoldBackground,
      appBar: showWebNav
          ? WebTopNav(
              selectedIndex: null,
              onDestinationSelected: (index) =>
                  DashboardTabs.open(context, index),
              onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            )
          : AppBar(
              leading: IconButton(
                icon: DirectionalFlip(
                  child: Icon(Icons.arrow_back, color: ColorResource.textWhite),
                ),
                onPressed: () => context.pop(),
              ),
              title: Text(
                'Order History',
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeLarge,
                  color: ColorResource.textWhite,
                ),
              ),
              backgroundColor: ColorResource.primaryDark,
              elevation: 0,
            ),
      endDrawer: showWebNav ? const WebProfileDrawer() : null,
      body: AuthGate(
        child: isWide ? _buildWebBody(showWebNav) : _buildMobileBody(),
      ),
    );
  }

  Widget _buildMobileBody() {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(child: _buildOrdersList(false)),
      ],
    );
  }

  Widget _buildWebBody(bool showInlineTitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header (title + filter chips) centred to the content width.
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showInlineTitle)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Text(
                      'Order History',
                      style: poppinsBold.copyWith(
                        fontSize: Constants.fontSizeOverLarge,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                _buildFilterChips(),
              ],
            ),
          ),
        ),
        // The list fills the remaining height; its scroll view spans the full
        // width (drag anywhere, incl. the side gutters, to scroll) and centres
        // its own content to [_maxContentWidth].
        Expanded(child: _buildOrdersList(true)),
      ],
    );
  }

  Widget _buildOrdersList(bool isWide) {
    return GetBuilder<OrderController>(
      builder: (controller) {
        if (controller.isLoading && controller.orders.isEmpty) {
          return _buildLoadingState();
        }

        // Filter orders to show only delivered and cancelled
        final filteredOrders = _selectedFilter == 'all'
            ? controller.orders.where((order) =>
                order.status == 'delivered' || order.status == 'cancelled').toList()
            : controller.orders.where((order) => order.status == _selectedFilter).toList();

        if (filteredOrders.isEmpty) {
          return _buildEmptyState();
        }

        return isWide
            ? _buildOrdersGrid(controller, filteredOrders)
            : _buildOrdersListView(controller, filteredOrders);
      },
    );
  }

  // Mobile: single-column list with infinite-scroll pagination.
  Widget _buildOrdersListView(
    OrderController controller,
    List<OrderModel> filteredOrders,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await controller.refreshOrders();
      },
      color: ColorResource.primaryDark,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: filteredOrders.length + (controller.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filteredOrders.length) {
            // Loading indicator at bottom
            return _buildLoadMoreIndicator(controller);
          }
          final order = filteredOrders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  // Web: responsive card grid. A Wrap lets each card keep its natural height,
  // the scroll view is full-width (drag anywhere to scroll) and centres its
  // content to [_maxContentWidth]; pagination is the "View more" button.
  Widget _buildOrdersGrid(
    OrderController controller,
    List<OrderModel> filteredOrders,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await controller.refreshOrders();
      },
      color: ColorResource.primaryDark,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.only(
          top: 16,
          bottom: Constants.bottomNavSpace,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          for (final order in filteredOrders)
                            SizedBox(
                              width: itemWidth,
                              child: HoverLift(child: _buildOrderCard(order)),
                            ),
                        ],
                      );
                    },
                  ),
                  _buildWebPaginationFooter(controller),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Web-only pagination control beneath the grid: loads the next page on tap
  /// and keeps working while more pages remain; hidden once the last page has
  /// loaded. A spinner replaces the button while a page is loading.
  Widget _buildWebPaginationFooter(OrderController controller) {
    if (!controller.hasMore) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Constants.paddingSizeLarge),
      child: Center(
        child: SizedBox(
          height: 48,
          child: Center(
            child: controller.isLoadingMore
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: ColorResource.primaryDark,
                    ),
                  )
                : _viewMoreButton(controller.loadMoreOrders),
          ),
        ),
      ),
    );
  }

  /// Outlined pill button used by [_buildWebPaginationFooter].
  Widget _viewMoreButton(VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
        hoverColor: ColorResource.primaryDark.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Constants.paddingSizeExtraLarge,
            vertical: Constants.paddingSizeSmall,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
            border: Border.all(color: ColorResource.primaryDark, width: 1.4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'view_more'.tr,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.primaryDark,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: ColorResource.primaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'All', 'value': 'all'},
      {'label': 'Delivered', 'value': 'delivered'},
      {'label': 'Cancelled', 'value': 'cancelled'},
    ];

    return Container(
      color: context.cardBackground,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter['value'];
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: _buildFilterChip(
                label: filter['label']!,
                value: filter['value']!,
                isSelected: isSelected,
                onTap: () => _filterOrders(filter['value']!),
              ),
            );
          }).toList(),
        ),
      ),
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
          color: isSelected ? null : context.scaffoldBackground,
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
            color: isSelected ? ColorResource.textWhite : context.textSecondary,
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
            'Loading your order history...',
            style: poppinsMedium.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: context.textSecondary,
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
                Icons.history,
                size: 60,
                color: context.textLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Order History',
              style: poppinsBold.copyWith(
                fontSize: 24,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You don\'t have any ${_selectedFilter == 'all' ? 'completed' : _selectedFilter} orders yet.\nStart ordering to see your history here!',
              textAlign: TextAlign.center,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: context.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
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
  }

  Widget _buildOrderCard(OrderModel order) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        onTap: () {
          context.pushNamed(
            RouteNames.orderDetail,
            pathParameters: {'id': order.id},
            extra: order,
          );
        },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: context.cardBackground,
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
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: context.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              StoreTime.format(order.createdAt, 'MMM dd, yyyy • hh:mm a'),
                              style: poppinsRegular.copyWith(
                                fontSize: Constants.fontSizeSmall,
                                color: context.textSecondary,
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
                      color: context.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Paid',
                        style: poppinsRegular.copyWith(
                          fontSize: Constants.fontSizeSmall,
                          color: context.textSecondary,
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
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.address.street,
                          style: poppinsRegular.copyWith(
                            fontSize: Constants.fontSizeSmall,
                            color: context.textSecondary,
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
