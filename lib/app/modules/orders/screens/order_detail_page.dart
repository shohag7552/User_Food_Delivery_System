import 'package:kikomart_user_app/app/common/widgets/auth_gate.dart';
import 'package:kikomart_user_app/app/common/widgets/custom_appbar.dart';
import 'package:kikomart_user_app/app/common/widgets/custom_toster.dart';
import 'package:kikomart_user_app/app/common/widgets/custom_network_image.dart';
import 'package:kikomart_user_app/app/common/widgets/web_footer.dart';
import 'package:kikomart_user_app/app/common/widgets/web_top_nav.dart';
import 'package:kikomart_user_app/app/controllers/auth_controller.dart';
import 'package:kikomart_user_app/app/controllers/deliveryman_review_controller.dart';
import 'package:kikomart_user_app/app/controllers/order_controller.dart';
import 'package:kikomart_user_app/app/controllers/review_controller.dart';
import 'package:kikomart_user_app/app/controllers/settings_controller.dart';
import 'package:kikomart_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kikomart_user_app/app/models/order_model.dart';
import 'package:kikomart_user_app/app/models/review_model.dart';
import 'package:kikomart_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
import 'package:kikomart_user_app/app/modules/orders/screens/order_delivery_map_page.dart';
import 'package:kikomart_user_app/app/helper/routes/app_router.dart';
import 'package:kikomart_user_app/app/modules/reviews/widgets/deliveryman_rating_badge.dart';
import 'package:kikomart_user_app/app/modules/reviews/widgets/deliveryman_review_section.dart';
import 'package:kikomart_user_app/app/modules/reviews/widgets/submit_review_bottomsheet.dart';
import 'package:kikomart_user_app/app/modules/orders/widgets/delivery_code_card.dart';
import 'package:kikomart_user_app/app/modules/orders/widgets/refund_request_card.dart';
import 'package:kikomart_user_app/app/resources/colors.dart';
import 'package:kikomart_user_app/app/helper/price_helper.dart';
import 'package:kikomart_user_app/app/resources/constants.dart';
import 'package:kikomart_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kikomart_user_app/app/helper/store_time_helper.dart';
part '../widgets/order_detail_page_header.dart';
part '../widgets/order_detail_page_items.dart';
part '../widgets/order_detail_page_info.dart';
part '../widgets/order_detail_page_actions.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;
  final OrderModel? initialOrder;

  const OrderDetailPage({super.key, required this.orderId, this.initialOrder});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  // Web/desktop layout kicks in above this width.
  static const double _webBreakpoint = 900;
  // Wide two-column layout is used above this; between the breakpoint and this
  // width the web layout falls back to a single centered column.
  static const double _twoColumnWidth = 1000;
  static const double _maxContentWidth = 1160;

  final GlobalKey<ScaffoldState> _webScaffoldKey = GlobalKey<ScaffoldState>();

  late final OrderController _orderController;
  late final ReviewController _reviewController;
  late final DeliverymanReviewController _deliverymanReviewController;

  Color get _borderColor => Theme.of(context).brightness == Brightness.dark
      ? Colors.grey.shade800
      : Colors.grey.shade200;
  OrderModel? _fallbackOrder;
  String? _currentUserId;
  String? _reviewPrefetchedOrderId;
  String? _deliverymanReviewPrefetchedOrderId;

  @override
  void initState() {
    super.initState();
    _orderController = Get.find<OrderController>();
    _reviewController = Get.find<ReviewController>();
    _deliverymanReviewController = Get.find<DeliverymanReviewController>();
    _fallbackOrder = widget.initialOrder;
    _orderController.fetchOrderDetails(widget.orderId);
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final authController = Get.find<AuthController>();
    final userId = await authController.getUserId();

    if (!mounted) {
      return;
    }

    setState(() {
      _currentUserId = userId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= _webBreakpoint;
    final twoColumn = screenWidth >= _twoColumnWidth;
    // Shared site top-nav only on desktop web; mobile/tablet keep the
    // regular back-button app bar.
    final showWebNav = WebTopNav.isEnabled(context);

    return Scaffold(
      key: _webScaffoldKey,
      backgroundColor: context.scaffoldBackground,
      endDrawer: showWebNav ? const WebProfileDrawer() : null,
      appBar: showWebNav
          ? WebTopNav(
              selectedIndex: null,
              onDestinationSelected: (index) {
                DashboardTabs.open(context, index);
              },
              onMenuTap: () => _webScaffoldKey.currentState?.openEndDrawer(),
            )
          : CustomAppbar(title: 'order_details'.tr),
      bottomNavigationBar: isWide
          ? null
          : GetBuilder<OrderController>(
              builder: (controller) {
                final order = controller.selectedOrder?.id == widget.orderId
                    ? controller.selectedOrder
                    : _fallbackOrder;

                if (order == null || !_shouldShowBottomActionBar(order)) {
                  return const SizedBox.shrink();
                }

                return _buildBottomActionBar(order, controller);
              },
            ),
      body: AuthGate(
        child: GetBuilder<OrderController>(
          builder: (controller) {
            final order = controller.selectedOrder?.id == widget.orderId
                ? controller.selectedOrder
                : _fallbackOrder;

            if (controller.isOrderDetailsLoading && order == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (order == null && controller.isOrderDetailsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (order == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: context.textLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'unable_to_load_order_details'.tr,
                        style: poppinsBold.copyWith(
                          fontSize: Constants.fontSizeLarge,
                          color: context.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'pull_to_refresh_or_try_again'.tr,
                        style: poppinsRegular.copyWith(
                          fontSize: Constants.fontSizeDefault,
                          color: context.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                await controller.refreshOrderDetails(widget.orderId);
                if (controller.selectedOrder?.id == widget.orderId && mounted) {
                  setState(() {
                    _fallbackOrder = controller.selectedOrder;
                  });
                }
              },
              color: ColorResource.primaryDark,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    isWide
                        ? _buildWebContent(order, twoColumn, controller)
                        : _buildMobileContent(order),
                    if (isWide) const WebFooter(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// One place that decides what a raw status string looks like, so the
  /// header icon and the badge can never disagree about a status.
  ({Color background, Color foreground, IconData icon, String label})
  _statusVisual(String status) {
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
      case 'preparing':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        icon = Icons.restaurant;
        label = 'preparing'.tr;
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
      // A real value in the orders enum that had no case here — it used to
      // fall through to the raw string, which now headlines the header.
      case 'picked_up':
        backgroundColor = Colors.lightBlue.shade100;
        textColor = Colors.lightBlue.shade900;
        icon = Icons.directions_bike_rounded;
        label = 'picked_up'.tr;
        break;
      case 'on_way':
      case 'delivering':
      case 'on_the_way':
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade700;
        icon = Icons.delivery_dining;
        label = 'on_the_way'.tr;
        break;
      case 'completed':
      case 'delivered':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        label = 'completed_status'.tr;
        break;
      case 'cancelled':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        icon = Icons.cancel;
        label = 'cancelled_status'.tr;
        break;
      // --- Ecommerce statuses ---
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
        // A status the app has not been taught yet. Show it as words rather
        // than as `snake_case`, which reads like a bug to the customer.
        label = status.replaceAll('_', ' ');
    }

    return (
      background: backgroundColor,
      foreground: textColor,
      icon: icon,
      label: label,
    );
  }

  bool _isOrderDelivered(OrderModel order) {
    return order.status.toLowerCase() == 'delivered' ||
        order.status.toLowerCase() == 'completed';
  }

  bool _isCompleted(OrderModel order) {
    final status = order.status.toLowerCase();
    return status == 'completed' || status == 'delivered';
  }

  bool _isPosOrder(OrderModel order) {
    final isPosOrderSource = order.orderSource?.toLowerCase() == 'pos';
    final isPosOrderNumber = order.orderNumber.toUpperCase().contains('POS');
    final isPosPaymentMethod = order.paymentMethod.toLowerCase() == 'pos';
    return isPosOrderSource || isPosOrderNumber || isPosPaymentMethod;
  }

  bool _shouldShowBottomActionBar(OrderModel order) {
    final showCancel = _canCancelOrder(order);
    final showMap = !(_isCompleted(order) && _isPosOrder(order));
    return showCancel || showMap;
  }

  bool _shouldShowWebActionButtons(OrderModel order) {
    final showCancel = _canCancelOrder(order);
    final showMap = !(_isCompleted(order) && _isPosOrder(order));
    return showCancel || showMap;
  }

  bool _hasDeliveryman(OrderModel order) {
    return (order.driverId?.isNotEmpty ?? false) || order.deliveryman != null;
  }

}
