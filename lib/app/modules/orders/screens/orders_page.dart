import 'package:appwrite_user_app/app/common/widgets/auth_gate.dart';
import 'package:appwrite_user_app/app/common/widgets/hover_lift.dart';
import 'package:appwrite_user_app/app/common/widgets/web_footer.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/module_controller.dart';
import 'package:appwrite_user_app/app/controllers/order_controller.dart';
import 'package:appwrite_user_app/app/helper/currency_helper.dart';
import 'package:appwrite_user_app/app/helper/nav_bar_visibility.dart';
import 'package:appwrite_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
import 'package:appwrite_user_app/app/models/order_model.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:appwrite_user_app/app/helper/store_time_helper.dart';

class OrdersPage extends StatefulWidget {
  /// True when this page is its own route rather than a tab inside
  /// `DashboardScreen`.
  ///
  /// It decides who supplies the web chrome. As a dashboard tab the shell
  /// already renders [WebTopNav], so this page must not add a second one; as a
  /// standalone route nothing else will, so it has to render its own.
  ///
  /// This used to be inferred from `Navigator.canPop()`, which cannot tell the
  /// two apart — both are unpoppable. Arriving from the order-success page,
  /// which navigates with a stack-replacing `go`, the page concluded it was a
  /// dashboard tab and dropped its app bar, leaving the route with no header
  /// at all.
  final bool isStandalone;

  const OrdersPage({super.key, this.isStandalone = false});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  // Lets the top-nav menu button open the end drawer, as on every other
  // standalone web page.
  final _webScaffoldKey = GlobalKey<ScaffoldState>();
  // Tracks the web/desktop layout so scroll-driven pagination stays mobile-only;
  // web loads the next page via the explicit "View more" button instead.
  bool _isWide = false;

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
    // Web paginates via the "View more" button, so skip scroll auto-load there.
    if (_isWide) return;
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
    _isWide = isWide;
    final canPop = Navigator.of(context).canPop();
    final showWebNav = WebTopNav.isEnabled(context);
    // As a dashboard tab the shell already renders the top nav, so this page
    // adds none of its own; standalone it renders the full web chrome.
    final ownsWebChrome = showWebNav && widget.isStandalone;
    final hideAppBar = showWebNav && !widget.isStandalone;
    // The page's own "My Orders" heading, rendered inside the body. Needed
    // for every web layout: neither the dashboard shell nor [WebTopNav] names
    // the current page, so without it the web view has no title anywhere.
    // Off on mobile, where the AppBar already carries it.
    final showInlineTitle = showWebNav;

    // Nothing to pop back to. Happens whenever this page was reached by a
    // stack-replacing `go` — the order-success page does exactly that so the
    // success screen can't be returned to — or opened straight from a URL.
    // Without a fallback the app bar renders no back button and Android's back
    // gesture closes the app instead of leaving the page.
    final needsHomeFallback = !canPop;

    final scaffold = Scaffold(
      key: _webScaffoldKey,
      backgroundColor: context.scaffoldBackground,
      endDrawer: ownsWebChrome ? const WebProfileDrawer() : null,
      appBar: ownsWebChrome
          ? WebTopNav(
              // Orders is dashboard tab 3, so the destination highlights.
              selectedIndex: 3,
              onDestinationSelected: (index) =>
                  DashboardTabs.open(context, index),
              onMenuTap: () => _webScaffoldKey.currentState?.openEndDrawer(),
            )
          : hideAppBar
          ? null
          : AppBar(
              // Null keeps Flutter's automatic back button whenever the route
              // really can pop; only the dead-end case is overridden.
              leading: needsHomeFallback
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: ColorResource.textWhite,
                      onPressed: _goHome,
                      tooltip:
                          MaterialLocalizations.of(context).backButtonTooltip,
                    )
                  : null,
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
      body: AuthGate(
        child: isWide
            ? _buildWebBody(showInlineTitle)
            : Column(
                children: [
                  _buildFilterChips(),
                  Expanded(child: _buildOrdersList(false)),
                ],
              ),
      ),
    );

    // PopScope is deliberately skipped on web: there the browser's own back
    // button drives go_router through browser history, and forcing
    // `canPop: false` would fight it. Web already has the top-nav (wide) or the
    // app-bar button added above (narrow) to get out of this page.
    if (kIsWeb || !needsHomeFallback) return scaffold;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _goHome();
      },
      child: scaffold,
    );
  }

  /// Leaves this page for the dashboard. Used only when there is no back stack
  /// to pop, so it can't strand the user or double up with a real pop.
  void _goHome() => context.goNamed(RouteNames.dashboard);

  Widget _buildWebBody(bool showInlineTitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header (title + filter chips) centered to the content width. The
        // inner column stretches so it fills the full [_maxContentWidth] (and
        // aligns with the grid below) instead of shrink-wrapping to its content.
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
                      'my_orders'.tr,
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
        // The list fills the remaining height. Its scroll view spans the FULL
        // width (so dragging over the letterboxed side gutters scrolls too —
        // previously only the centered column was scrollable) and centers its
        // own content to [_maxContentWidth].
        Expanded(child: _buildOrdersList(true)),
      ],
    );
  }

  Widget _buildWebEmptyState(OrderController controller) {
    return RefreshIndicator(
      onRefresh: controller.refreshOrders,
      color: ColorResource.primaryDark,
      child: LayoutBuilder(
        builder: (context, viewport) => SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: viewport.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 20),
                _buildEmptyState(),
                const WebFooter(),
              ],
            ),
          ),
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
          return isWide
              ? _buildWebEmptyState(controller)
              : _buildEmptyState();
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
      child: NavClearance(
        builder: (context, bottom) => ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottom),
          itemCount: controller.orders.length + (controller.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == controller.orders.length) {
              return _buildLoadMoreIndicator(controller);
            }
            return _buildOrderCard(controller.orders[index]);
          },
        ),
      ),
    );
  }

  // Web: responsive grid. A Wrap lets each card keep its natural height (no
  // overflow), while the column count adapts to the available width. The scroll
  // view is full-width (drag anywhere, including the side gutters, to scroll)
  // and centers its content to [_maxContentWidth].
  Widget _buildOrdersGrid(OrderController controller) {
    return RefreshIndicator(
      onRefresh: controller.refreshOrders,
      color: ColorResource.primaryDark,
      child: LayoutBuilder(
        builder: (context, viewport) => SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            // At least a full viewport tall so the footer anchors to the bottom
            // when content is short, and flows after it when tall.
            constraints: BoxConstraints(minHeight: viewport.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: _maxContentWidth),
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
                                  runSpacing: 0,
                                  children: [
                                    for (final order in controller.orders)
                                      SizedBox(
                                        width: itemWidth,
                                        child: HoverLift(
                                            child: _buildOrderCard(order)),
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
                const WebFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Web-only pagination control beneath the orders grid. Tapping it loads the
  /// next page (offset) and keeps working continuously while more pages remain;
  /// it renders nothing once the last page has loaded. A spinner replaces the
  /// button while a page is loading so the layout stays put.
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
    // The orders fetch is scoped to the active module, so the status filters
    // must speak that module's vocabulary: food preparation stages vs the
    // ecommerce fulfilment pipeline.
    final filters = ModuleController.current == ModuleController.ecommerce
        ? [
            {'label': 'all'.tr, 'value': 'all'},
            {'label': 'pending'.tr, 'value': 'pending'},
            {'label': 'confirmed'.tr, 'value': 'confirmed'},
            {'label': 'packing'.tr, 'value': 'packing'},
            {'label': 'shipped'.tr, 'value': 'shipped'},
            {'label': 'out_for_delivery'.tr, 'value': 'out_for_delivery'},
            {'label': 'delivered'.tr, 'value': 'delivered'},
            {'label': 'cancelled'.tr, 'value': 'cancelled'},
          ]
        : [
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
          color: context.cardBackground,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: filters.map((filter) {
                final isSelected = controller.selectedStatus == filter['value'];
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
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
            'loading_your_orders'.tr,
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
                    color: context.textLight,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isFiltered ? 'no_orders_found'.tr : 'no_orders_yet'.tr,
                  style: poppinsBold.copyWith(
                    fontSize: 24,
                    color: context.textPrimary,
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
                    color: context.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                if (!isFiltered)
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
      },
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
                          '#${order.orderNumber}',
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
                    '${order.items.length} ${order.items.length == 1 ? 'item'.tr : 'items'.tr}',
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
                        'total_payable'.tr,
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
                          'delivery_address'.tr,
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
      // --- Ecommerce statuses (same vocabulary as the order detail page) ---
      case 'confirmed':
        backgroundColor = Colors.teal.shade100;
        textColor = Colors.teal.shade700;
        icon = Icons.verified_outlined;
        label = 'confirmed'.tr;
        break;
      case 'packing':
        backgroundColor = Colors.amber.shade100;
        textColor = Colors.amber.shade800;
        icon = Icons.inventory_2_outlined;
        label = 'packing'.tr;
        break;
      case 'shipped':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        icon = Icons.local_shipping_outlined;
        label = 'shipped'.tr;
        break;
      case 'out_for_delivery':
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade700;
        icon = Icons.delivery_dining;
        label = 'out_for_delivery'.tr;
        break;
      case 'returned':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.assignment_return_outlined;
        label = 'returned'.tr;
        break;
      case 'refunded':
        backgroundColor = Colors.blueGrey.shade100;
        textColor = Colors.blueGrey.shade700;
        icon = Icons.replay_circle_filled_outlined;
        label = 'refunded'.tr;
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
