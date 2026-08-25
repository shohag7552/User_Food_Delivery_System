import 'package:appwrite_user_app/app/common/widgets/auth_gate.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_appbar.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/common/widgets/web_footer.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/controllers/deliveryman_review_controller.dart';
import 'package:appwrite_user_app/app/controllers/order_controller.dart';
import 'package:appwrite_user_app/app/controllers/review_controller.dart';
import 'package:appwrite_user_app/app/controllers/settings_controller.dart';
import 'package:appwrite_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:appwrite_user_app/app/models/order_model.dart';
import 'package:appwrite_user_app/app/models/review_model.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
import 'package:appwrite_user_app/app/modules/orders/screens/order_delivery_map_page.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/modules/reviews/widgets/deliveryman_rating_badge.dart';
import 'package:appwrite_user_app/app/modules/reviews/widgets/deliveryman_review_section.dart';
import 'package:appwrite_user_app/app/modules/reviews/widgets/submit_review_bottomsheet.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/helper/price_helper.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:appwrite_user_app/app/helper/store_time_helper.dart';

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

  // ── Mobile: single stacked column (unchanged from the original design) ──
  Widget _buildMobileContent(OrderModel order) {
    final isEcom = order.moduleType == 'ecommerce';
    final showTimeline =
        isEcom &&
        ![
          'cancelled',
          'returned',
          'refunded',
        ].contains(order.status.toLowerCase());
    final hasTracking = isEcom && (order.trackingNumber ?? '').isNotEmpty;

    return Column(
      children: [
        _buildHeader(order),
        // Directly under the header: the customer needs this the moment the
        // deliveryman is at the door, not after scrolling past the item list.
        if (_shouldShowVerificationCode(order)) ...[
          const SizedBox(height: 16),
          _buildVerificationCode(order),
        ],
        if (showTimeline) ...[
          const SizedBox(height: 16),
          _buildStatusTimeline(order),
        ],
        if (hasTracking) ...[
          const SizedBox(height: 16),
          _buildTrackingInfo(order),
        ],
        const SizedBox(height: 16),
        _buildItemsList(order),
        const SizedBox(height: 16),
        _buildDeliveryInfo(order),
        const SizedBox(height: 16),
        _buildPaymentInfo(order),
        if (_hasDeliveryman(order)) ...[
          const SizedBox(height: 16),
          _buildDeliverymanSection(order),
        ],
        const SizedBox(height: 16),
        _buildPricingBreakdown(order),
        const SizedBox(height: 24),
        // No extra clearance for the action bar: it is the Scaffold's
        // bottomNavigationBar, so the body is already laid out above it.
        // Padding for it here just adds dead space under the last card.
      ],
    );
  }

  // ── Web/desktop: constrained layout with a rounded gradient header. ──
  // Wide screens get a two-column split (order contents on the left, a summary
  // rail on the right); narrower web widths fall back to a single column.
  Widget _buildWebContent(
    OrderModel order,
    bool twoColumn,
    OrderController controller,
  ) {
    final isEcom = order.moduleType == 'ecommerce';
    final showTimeline =
        isEcom &&
        ![
          'cancelled',
          'returned',
          'refunded',
        ].contains(order.status.toLowerCase());
    final hasTracking = isEcom && (order.trackingNumber ?? '').isNotEmpty;

    // Left / primary column: what was ordered and where it's going.
    final primary = <Widget>[
      _buildItemsList(order),
      const SizedBox(height: 16),
      _buildDeliveryInfo(order),
      if (_hasDeliveryman(order)) ...[
        const SizedBox(height: 16),
        _buildDeliverymanSection(order),
      ],
    ];

    // Right / summary column: status, meta and money.
    final summary = <Widget>[
      // Top of the rail — same reasoning as mobile: this is the one thing the
      // customer needs at hand when the deliveryman arrives.
      if (_shouldShowVerificationCode(order)) ...[
        _buildVerificationCode(order),
        const SizedBox(height: 16),
      ],
      if (showTimeline) ...[
        _buildStatusTimeline(order),
        const SizedBox(height: 16),
      ],
      if (hasTracking) ...[
        _buildTrackingInfo(order),
        const SizedBox(height: 16),
      ],
      _buildPaymentInfo(order),
      const SizedBox(height: 16),
      _buildPricingBreakdown(order),
      if (_shouldShowWebActionButtons(order)) ...[
        const SizedBox(height: 20),
        _buildWebActionButtons(order, controller),
      ],
    ];

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWebHeaderCard(order),
              const SizedBox(height: 20),
              if (twoColumn)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 62,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: primary,
                      ),
                    ),
                    Expanded(
                      flex: 38,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: summary,
                      ),
                    ),
                  ],
                )
              else ...[
                ...summary,
                const SizedBox(height: 16),
                ...primary,
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Premium gradient header card used on the web layout (rounded, not
  // full-bleed) — shows the order number, date and current status badge.
  Widget _buildWebHeaderCard(OrderModel order) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: ColorResource.primaryGradient,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
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
                    fontSize: Constants.fontSizeExtraLarge,
                    color: ColorResource.textWhite,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 15,
                      color: ColorResource.textWhite.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      StoreTime.format(
                        order.createdAt,
                        'EEEE, MMMM dd, yyyy • hh:mm a',
                      ),
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeDefault,
                        color: ColorResource.textWhite.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                _buildScheduledLine(order),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildStatusBadge(order.status),
        ],
      ),
    );
  }

  /// A scheduled-delivery line (`Scheduled: day • start - end`) shown only for
  /// scheduled orders. Times render in the store timezone; empty for ASAP.
  Widget _buildScheduledLine(OrderModel order, {bool centered = false}) {
    final start = order.scheduledStart;
    if (start == null) return const SizedBox.shrink();

    final day = StoreTime.format(start, 'EEE, MMM dd');
    final startTime = StoreTime.format(start, 'hh:mm a');
    final endTime = order.scheduledEnd != null
        ? StoreTime.format(order.scheduledEnd!, 'hh:mm a')
        : null;
    final slot = endTime != null ? '$startTime - $endTime' : startTime;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 15,
            color: ColorResource.textWhite.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${'scheduled_delivery'.tr}: $day • $slot',
              textAlign: centered ? TextAlign.center : TextAlign.start,
              style: poppinsMedium.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: ColorResource.textWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(OrderModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: ColorResource.primaryGradient,
        boxShadow: ColorResource.customShadow,
      ),
      child: Column(
        children: [
          Text(
            '#${order.orderNumber}',
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeExtraLarge,
              color: ColorResource.textWhite,
            ),
          ),
          const SizedBox(height: 8),
          _buildScheduledLine(order, centered: true),
          Text(
            StoreTime.format(order.createdAt, 'EEEE, MMMM dd, yyyy • hh:mm a'),
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: ColorResource.textWhite.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatusBadge(order.status),
        ],
      ),
    );
  }

  Widget _buildItemsList(OrderModel order) {
    _prefetchUserReviews(order);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'order_items'.tr,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeLarge,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                // The count belongs on the heading, not as its own stat card
                // row: it answers "how many lines am I about to read?".
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Constants.paddingSizeSmall,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ColorResource.primaryDark.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(
                      Constants.radiusExtraLarge,
                    ),
                  ),
                  child: Text(
                    '${order.items.length}',
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: ColorResource.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Hairline-separated rows rather than a nested bordered card per
          // item: a box inside a box inside a box reads as clutter, and the
          // items are a list, not a set of independent objects.
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: order.items.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, indent: 16, endIndent: 16, color: _borderColor),
            itemBuilder: (context, index) =>
                _buildOrderItem(order, order.items[index]),
          ),
          const SizedBox(height: Constants.paddingSizeSmall),
        ],
      ),
    );
  }

  /// One line of the order: what it was, how many, what it came to.
  ///
  /// Deliberately not everything the model knows — the unit price before
  /// discount and the percentage saved were removed from here because the
  /// payment summary below already totals both, and repeating them turned a
  /// two-second scan into a paragraph.
  Widget _buildOrderItem(OrderModel order, OrderItem item) {
    final itemTotal = item.price * item.quantity;
    final variants = item.selectedVariants.join(' • ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: context.scaffoldBackground,
                  borderRadius: BorderRadius.circular(Constants.radiusDefault),
                  border: Border.all(color: _borderColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: CustomNetworkImage(
                  image: item.productImage,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: poppinsMedium.copyWith(
                        fontSize: Constants.fontSizeDefault,
                        color: context.textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (variants.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      // Variants read as one muted line instead of a row of
                      // chips — they qualify the product, they are not
                      // actions, and chips promised a tap that never existed.
                      Text(
                        variants,
                        style: poppinsRegular.copyWith(
                          fontSize: Constants.fontSizeSmall,
                          color: context.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${item.quantity} × ${PriceHelper.formatPrice(item.price)}',
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: context.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Constants.paddingSizeSmall),
              // The line total is the number the eye goes looking for, so it
              // stays right-aligned in its own column, level with the name.
              Text(
                PriceHelper.formatPrice(itemTotal),
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          if (_isOrderDelivered(order)) ...[
            const SizedBox(height: Constants.paddingSizeSmall),
            // Indented to the text column so the rating action reads as
            // belonging to this product rather than to the whole card.
            Padding(
              padding: const EdgeInsets.only(left: 64),
              child: _buildReviewAction(order, item),
            ),
          ],
        ],
      ),
    );
  }

  void _prefetchUserReviews(OrderModel order) {
    if (!_isOrderDelivered(order) ||
        _currentUserId == null ||
        _reviewPrefetchedOrderId == order.id) {
      return;
    }

    _reviewPrefetchedOrderId = order.id;
    final userId = _currentUserId!;
    final productIds = order.items
        .map((item) => item.productId)
        .where((productId) => productId.isNotEmpty)
        .toSet();

    for (final productId in productIds) {
      _reviewController.fetchUserProductReview(
        userId,
        productId,
        orderId: order.id,
      );
    }
  }

  /// Loads the customer's existing delivery rating for this order.
  ///
  /// Deferred to after the frame: the controller flips its loading flag
  /// synchronously, and notifying a [GetBuilder] mid-build is a rebuild inside
  /// a build.
  void _prefetchDeliverymanReview(OrderModel order) {
    final userId = _currentUserId;
    if (userId == null ||
        _deliverymanReviewPrefetchedOrderId == order.id ||
        !_deliverymanReviewController.canShowDeliveryRating(order)) {
      return;
    }

    _deliverymanReviewPrefetchedOrderId = order.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _deliverymanReviewController.loadOrderReview(order, userId);
    });
  }

  Widget _buildReviewAction(OrderModel order, OrderItem item) {
    final userId = _currentUserId;

    if (userId == null) {
      return _buildRateProductButton(item);
    }

    return GetBuilder<ReviewController>(
      builder: (reviewController) {
        final hasLoaded = reviewController.hasUserProductReviewLoaded(
          userId,
          item.productId,
          orderId: order.id,
        );
        final isLoading = reviewController.isUserProductReviewLoading(
          userId,
          item.productId,
          orderId: order.id,
        );
        final review = reviewController.getCachedUserProductReview(
          userId,
          item.productId,
          orderId: order.id,
        );

        if (review != null) {
          return _buildExistingReviewCard(review);
        }

        if (!hasLoaded || isLoading) {
          // Sized and aligned like the pill it stands in for, so the row does
          // not jump sideways or change height when the answer arrives.
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              height: 26,
              width: 26,
              child: Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ColorResource.primaryDark.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          );
        }

        return _buildRateProductButton(item);
      },
    );
  }

  /// Compact by design: this is an optional afterthought on a delivered order,
  /// not the card's primary action, and a full-width button per line item made
  /// a three-item order look like a form with three submit buttons.
  Widget _buildRateProductButton(OrderItem item) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Material(
        color: ColorResource.primaryDark.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showReviewBottomSheet(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Constants.paddingSizeDefault - 3,
              vertical: Constants.paddingSizeSmall - 3,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: ColorResource.primaryDark,
                ),
                const SizedBox(width: 5),
                Text(
                  'rate_this_product'.tr,
                  style: poppinsMedium.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: ColorResource.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The score already given, stated as stars rather than as a number in
  /// brackets — the previous "(5.0✭)" both read as a decimal and left the
  /// untranslated key visible when the label had no entry in the language file.
  Widget _buildExistingReviewCard(ReviewModel review) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_rounded, size: 15, color: ColorResource.success),
        const SizedBox(width: 5),
        Text(
          'rated'.tr,
          style: poppinsMedium.copyWith(
            fontSize: Constants.fontSizeSmall,
            color: context.textSecondary,
          ),
        ),
        const SizedBox(width: 6),
        ...List.generate(
          5,
          (index) => Icon(
            index < review.rating
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            size: 14,
            color: index < review.rating
                ? ColorResource.ratingStarColor
                : context.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryInfo(OrderModel order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: ColorResource.primaryDark,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'delivery_address'.tr,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeLarge,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.scaffoldBackground,
              borderRadius: BorderRadius.circular(Constants.radiusDefault),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.home_outlined,
                  color: context.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    order.address.street,
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: context.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(OrderModel order) {
    // Payment method display
    IconData methodIcon;
    String methodLabel;

    switch (order.paymentMethod.toLowerCase()) {
      case 'online':
        methodIcon = Icons.credit_card;
        methodLabel = 'online_payment'.tr;
        break;
      case 'wallet':
        methodIcon = Icons.account_balance_wallet;
        methodLabel = 'wallet'.tr;
        break;
      case 'cod':
      default:
        methodIcon = Icons.money;
        methodLabel = 'cash_on_delivery'.tr;
    }

    // Payment status display
    Color statusBgColor;
    Color statusTextColor;
    IconData statusIcon;
    String statusLabel;

    switch (order.paymentStatus.toLowerCase()) {
      case 'paid':
        statusBgColor = Colors.green.shade100;
        statusTextColor = Colors.green.shade700;
        statusIcon = Icons.check_circle;
        statusLabel = 'Paid';
        break;
      case 'failed':
        statusBgColor = Colors.red.shade100;
        statusTextColor = Colors.red.shade700;
        statusIcon = Icons.error;
        statusLabel = 'Failed';
        break;
      case 'cancelled':
        statusBgColor = Colors.orange.shade100;
        statusTextColor = Colors.orange.shade700;
        statusIcon = Icons.cancel;
        statusLabel = 'Cancelled';
        break;
      case 'unpaid':
      default:
        statusBgColor = Colors.amber.shade100;
        statusTextColor = Colors.amber.shade800;
        statusIcon = Icons.schedule;
        statusLabel = 'Unpaid';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: ColorResource.primaryDark, size: 24),
              const SizedBox(width: 8),
              Text(
                'payment_info'.tr,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeLarge,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.scaffoldBackground,
              borderRadius: BorderRadius.circular(Constants.radiusDefault),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              children: [
                // Payment method row
                Row(
                  children: [
                    Icon(
                      methodIcon,
                      color: ColorResource.primaryDark,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'payment_method'.tr,
                            style: poppinsRegular.copyWith(
                              fontSize: Constants.fontSizeSmall,
                              color: context.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            methodLabel,
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeDefault,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: _borderColor),
                const SizedBox(height: 12),
                // Payment status row
                Row(
                  children: [
                    Icon(statusIcon, color: statusTextColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'payment_status'.tr,
                            style: poppinsRegular.copyWith(
                              fontSize: Constants.fontSizeSmall,
                              color: context.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            statusLabel,
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeDefault,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusTextColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeSmall,
                              color: statusTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingBreakdown(OrderModel order) {
    // Subtotal = total - deliveryFee - tax + discounts (add discounts back since they were subtracted from total)
    final subtotal =
        order.totalAmount -
        order.deliveryFee -
        order.taxAmount +
        order.discountAmount +
        order.couponDiscount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'payment_summary'.tr,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeLarge,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceRow('subtotal'.tr, subtotal, false),
          if (order.discountAmount > 0) ...[
            const SizedBox(height: 12),
            _buildPriceRow(
              'item_discount'.tr,
              -order.discountAmount,
              false,
              isDiscount: true,
            ),
          ],
          if (order.couponDiscount > 0) ...[
            const SizedBox(height: 12),
            _buildPriceRow(
              'coupon_discount'.tr,
              -order.couponDiscount,
              false,
              isDiscount: true,
            ),
          ],
          const SizedBox(height: 12),
          _buildPriceRow('delivery_fee'.tr, order.deliveryFee, false),
          if (order.taxAmount > 0) ...[
            const SizedBox(height: 12),
            _buildPriceRow('tax_vat'.tr, order.taxAmount, false),
          ],
          const SizedBox(height: 12),
          Divider(color: _borderColor),
          const SizedBox(height: 12),
          _buildPriceRow('total_amount'.tr, order.totalAmount, true),
        ],
      ),
    );
  }

  Widget _buildDeliverymanSection(OrderModel order) {
    final deliveryman = order.deliveryman;
    _prefetchDeliverymanReview(order);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.delivery_dining,
                color: ColorResource.primaryDark,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'deliveryman'.tr,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeLarge,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.scaffoldBackground,
              borderRadius: BorderRadius.circular(Constants.radiusDefault),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: ColorResource.primaryDark.withValues(alpha: 0.08),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child:
                        deliveryman?.image != null &&
                            deliveryman!.image!.isNotEmpty
                        ? CustomNetworkImage(
                            image: deliveryman.image!,
                            width: 56,
                            height: 56,
                          )
                        : Icon(
                            Icons.person,
                            color: ColorResource.primaryDark,
                            size: 28,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deliveryman?.name.isNotEmpty == true
                            ? deliveryman!.name
                            : 'deliveryman'.tr,
                        style: poppinsBold.copyWith(
                          fontSize: Constants.fontSizeDefault,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deliveryman?.phone.isNotEmpty == true
                            ? deliveryman!.phone
                            : 'phone_number_not_available'.tr,
                        style: poppinsRegular.copyWith(
                          fontSize: Constants.fontSizeDefault,
                          color: context.textSecondary,
                        ),
                      ),
                      // The driver's own score, so the customer can see they
                      // are rating someone other customers have rated too.
                      DeliverymanRatingBadge(
                        driverId: _deliverymanReviewController.resolveDriverId(
                          order,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          DeliverymanReviewSection(
            order: order,
            isLoggedIn: _currentUserId != null,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount,
    bool isTotal, {
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (isTotal ? poppinsBold : poppinsRegular).copyWith(
            fontSize: isTotal
                ? Constants.fontSizeLarge
                : Constants.fontSizeDefault,
            color: isDiscount ? Colors.green.shade700 : context.textPrimary,
          ),
        ),
        Text(
          isDiscount
              ? '- ${PriceHelper.formatPrice(amount.abs())}'
              : PriceHelper.formatPrice(amount),
          style: poppinsBold.copyWith(
            fontSize: isTotal
                ? Constants.fontSizeExtraLarge
                : Constants.fontSizeLarge,
            color: isDiscount
                ? Colors.green.shade700
                : (isTotal ? ColorResource.primaryDark : context.textPrimary),
          ),
        ),
      ],
    );
  }

  /// Ecommerce fulfilment progress (vertical stepper).
  Widget _buildStatusTimeline(OrderModel order) {
    const steps = [
      'confirmed',
      'packing',
      'shipped',
      'out_for_delivery',
      'delivered',
    ];
    final status = order.status.toLowerCase();
    int current = steps.indexOf(status);
    if (status == 'pending') current = -1;
    if (status == 'completed') current = steps.length - 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'order_status'.tr,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeLarge,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (i) {
            final done = i <= current;
            final isLast = i == steps.length - 1;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: done
                              ? ColorResource.primaryDark
                              : context.scaffoldBackground,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: done
                                ? ColorResource.primaryDark
                                : context.textLight.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          done ? Icons.check : Icons.circle,
                          size: done ? 15 : 8,
                          color: done
                              ? ColorResource.textWhite
                              : context.textLight,
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: i < current
                                ? ColorResource.primaryDark
                                : context.textLight.withValues(alpha: 0.25),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: EdgeInsets.only(top: 3, bottom: isLast ? 0 : 20),
                    child: Text(
                      _stepLabel(steps[i]),
                      style: done
                          ? poppinsBold.copyWith(
                              fontSize: Constants.fontSizeDefault,
                              color: context.textPrimary,
                            )
                          : poppinsRegular.copyWith(
                              fontSize: Constants.fontSizeDefault,
                              color: context.textSecondary,
                            ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _stepLabel(String step) {
    switch (step) {
      case 'confirmed':
        return 'confirmed'.tr;
      case 'packing':
        return 'packing'.tr;
      case 'shipped':
        return 'shipped'.tr;
      case 'out_for_delivery':
        return 'out_for_delivery'.tr;
      case 'delivered':
        return 'completed_status'.tr;
      default:
        return step;
    }
  }

  /// Whether to surface the handover code on this order.
  ///
  /// The code exists for one moment only: a deliveryman at the door needing
  /// proof the parcel reached the right person. Every condition below removes a
  /// case where that moment never happens.
  ///
  /// - the store requires verification at all (`is_order_verification_active`)
  /// - the order carries a code — orders placed before this feature shipped,
  ///   and POS counter sales, have none
  /// - the store is not self-delivering (see below)
  /// - the order is not a courier-shipped ecommerce order (see below)
  /// - the order is still in flight; once it is delivered or cancelled the code
  ///   has done its job and showing it invites confusion
  bool _shouldShowVerificationCode(OrderModel order) {
    final businessSetup = Get.find<SettingsController>().businessSetup;
    if (businessSetup?.isOrderVerificationActive != true) return false;
    if ((order.deliveryVerificationCode ?? '').isEmpty) return false;

    // Self delivery means the store drops orders off itself, without the
    // deliveryman app — so nothing exists to type the code into.
    if (businessSetup?.isSelfDelivery == true) return false;

    // An ecommerce order placed while shipping methods are on is handed to a
    // courier, not a deliveryman — it is tracked by tracking number and there
    // is nobody at the door to read a code to. Food orders, and ecommerce
    // orders fulfilled by the store's own rider, still need it.
    final shipsByCourier =
        order.moduleType == 'ecommerce' &&
        businessSetup?.isShippingMethodEnabled == true;
    if (shipsByCourier) return false;

    final status = order.status.toLowerCase();
    return status != 'delivered' &&
        status != 'completed' &&
        status != 'cancelled' &&
        status != 'returned' &&
        status != 'refunded';
  }

  /// The code the customer reads out on the doorstep. Set large and widely
  /// tracked because it is going to be read aloud, often in bad light through a
  /// half-open door — legibility matters more here than fitting the card's
  /// usual type scale.
  Widget _buildVerificationCode(OrderModel order) {
    final code = order.deliveryVerificationCode!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Constants.paddingSizeDefault),
      padding: const EdgeInsets.all(Constants.paddingSizeDefault),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
        border: Border.all(
          color: ColorResource.primaryDark.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: ColorResource.primaryDark,
                size: 20,
              ),
              const SizedBox(width: Constants.paddingSizeSmall),
              Expanded(
                child: Text(
                  'delivery_verification_code'.tr,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeLarge,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Constants.paddingSizeDefault),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Constants.paddingSizeLarge,
                vertical: Constants.paddingSizeSmall,
              ),
              decoration: BoxDecoration(
                color: ColorResource.primaryDark.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Constants.radiusDefault),
              ),
              child: Text(
                code,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeOverLarge + 6,
                  color: ColorResource.primaryDark,
                  letterSpacing: 8,
                  // Digits read aloud must not wobble between glyph widths.
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          const SizedBox(height: Constants.paddingSizeDefault),
          Text(
            'share_code_with_deliveryman'.tr,
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeSmall,
              color: context.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingInfo(OrderModel order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                color: ColorResource.primaryDark,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'tracking_info'.tr,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeLarge,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if ((order.courierName ?? '').isNotEmpty)
            _trackingRow('courier'.tr, order.courierName!),
          _trackingRow('tracking_number'.tr, order.trackingNumber!),
        ],
      ),
    );
  }

  Widget _trackingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: context.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: poppinsMedium.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: context.textPrimary,
              ),
            ),
          ),
        ],
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
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: textColor,
            ),
          ),
        ],
      ),
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

  Widget _buildBottomActionBar(OrderModel order, OrderController controller) {
    final showCancel = _canCancelOrder(order);
    final showMap = !(_isCompleted(order) && _isPosOrder(order));

    if (!showCancel && !showMap) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (showCancel) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.isCancellingOrder
                      ? null
                      : () => _showCancelOrderConfirmation(order),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorResource.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: ColorResource.error, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        Constants.radiusLarge,
                      ),
                    ),
                  ),
                  child: controller.isCancellingOrder
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ColorResource.error,
                            ),
                          ),
                        )
                      : Text(
                          'cancel'.tr,
                          style: poppinsBold.copyWith(
                            fontSize: Constants.fontSizeDefault,
                          ),
                        ),
                ),
              ),
              if (showMap) const SizedBox(width: 12),
            ],
            if (showMap)
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _openDeliveryMap(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorResource.primaryDark,
                    foregroundColor: ColorResource.textWhite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        Constants.radiusLarge,
                      ),
                    ),
                  ),
                  child: Text(
                    'view_on_map'.tr,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: ColorResource.textWhite,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _canCancelOrder(OrderModel order) {
    return order.status.toLowerCase() == 'pending';
  }

  void _showCancelOrderConfirmation(OrderModel order) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'cancel'.tr,
          style: poppinsBold.copyWith(fontSize: Constants.fontSizeLarge),
        ),
        content: Text(
          'are_you_sure_you_want_to_cancel_this_order'.tr,
          style: poppinsRegular.copyWith(fontSize: Constants.fontSizeDefault),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'close'.tr,
              style: poppinsMedium.copyWith(color: context.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await _orderController.cancelOrder(order.id);
              if (!mounted) {
                return;
              }
              Get.snackbar(
                success ? 'success'.tr : 'error'.tr,
                success
                    ? 'order_cancelled_successfully'.tr
                    : 'failed_to_cancel_order'.tr,
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: success
                    ? ColorResource.primaryDark
                    : ColorResource.error,
                colorText: ColorResource.textWhite,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorResource.error,
            ),
            child: Text(
              'cancel'.tr,
              style: poppinsBold.copyWith(color: ColorResource.textWhite),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDeliveryMap(OrderModel order) async {
    final deliveryman = order.deliveryman;
    final settingsController = Get.find<SettingsController>();

    if (settingsController.businessSetup == null) {
      await settingsController.fetchBusinessSetup();
    }

    if (!mounted) return;

    final businessSetup = settingsController.businessSetup;

    if (businessSetup?.storeLatitude == null ||
        businessSetup?.storeLongitude == null) {
      Get.snackbar(
        'location_unavailable'.tr,
        'business_location_is_not_available_right_now'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorResource.error,
        colorText: ColorResource.textWhite,
      );
      return;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= _webBreakpoint;

    if (isWide) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Constants.radiusLarge),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.8,
              child: OrderDeliveryMapPage(
                deliveryman: deliveryman,
                businessName: businessSetup?.businessName ?? '',
                businessAddress: businessSetup?.storeLocation ?? '',
                businessLatitude: businessSetup!.storeLatitude!,
                businessLongitude: businessSetup.storeLongitude!,
                deliveryAddress: order.address.street,
                deliveryLatitude: order.address.lat,
                deliveryLongitude: order.address.lng,
                showBackButton: false,
              ),
            ),
          ),
        ),
      );
    } else {
      AppRouter.router.pushNamed(
        RouteNames.deliveryMap,
        extra: DeliveryMapArgs(
          deliveryman: deliveryman,
          businessName: businessSetup?.businessName ?? '',
          businessAddress: businessSetup?.storeLocation ?? '',
          businessLatitude: businessSetup!.storeLatitude!,
          businessLongitude: businessSetup.storeLongitude!,
          deliveryAddress: order.address.street,
          deliveryLatitude: order.address.lat,
          deliveryLongitude: order.address.lng,
        ),
      );
    }
  }

  Future<void> _showReviewBottomSheet(OrderItem item) async {
    final authController = Get.find<AuthController>();
    String? userId = await authController.getUserId();
    String? userName = await authController.getUserName();

    if (userId == null) {
      Get.snackbar(
        'login_required'.tr,
        'please_login_to_write_a_review'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorResource.error,
        colorText: ColorResource.textWhite,
      );
      return;
    }

    // Show submit review bottom sheet with verified purchase
    final didSubmit = await SubmitReviewBottomSheet.show(
      Get.context!,
      orderId: widget.orderId,
      productId: item.productId, // Use actual product ID from order item
      userId: userId,
      userName: userName ?? 'user'.tr,
      productName: item.productName,
      productImage: item.productImage,
      verifiedPurchase: true, // User purchased this product
    );

    if (didSubmit == true) {
      await _reviewController.fetchUserProductReview(
        userId,
        item.productId,
        orderId: widget.orderId,
        forceRefresh: true,
      );
    }
  }

  Widget _buildWebActionButtons(OrderModel order, OrderController controller) {
    final showCancel = _canCancelOrder(order);
    final showMap = !(_isCompleted(order) && _isPosOrder(order));

    if (!showCancel && !showMap) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (showCancel) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: controller.isCancellingOrder
                    ? null
                    : () => _showCancelOrderConfirmation(order),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorResource.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: ColorResource.error, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Constants.radiusLarge),
                  ),
                ),
                child: controller.isCancellingOrder
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ColorResource.error,
                          ),
                        ),
                      )
                    : Text(
                        'cancel'.tr,
                        style: poppinsBold.copyWith(
                          fontSize: Constants.fontSizeDefault,
                        ),
                      ),
              ),
            ),
            if (showMap) const SizedBox(width: 12),
          ],
          if (showMap)
            Expanded(
              child: ElevatedButton(
                onPressed: () => _openDeliveryMap(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorResource.primaryDark,
                  foregroundColor: ColorResource.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Constants.radiusLarge),
                  ),
                ),
                child: Text(
                  'view_on_map'.tr,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeDefault,
                    color: ColorResource.textWhite,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
