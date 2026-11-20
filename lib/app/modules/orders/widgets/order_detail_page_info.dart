part of '../screens/order_detail_page.dart';

extension _OrderDetailPageInfo on _OrderDetailPageState {
  Widget _buildDeliveryInfo(OrderModel order) {
    final isWide =
        MediaQuery.of(context).size.width >=
        _OrderDetailPageState._webBreakpoint;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isWide ? 0 : 16),
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
        statusLabel = 'payment_status_paid'.tr;
        break;
      case 'failed':
        statusBgColor = Colors.red.shade100;
        statusTextColor = Colors.red.shade700;
        statusIcon = Icons.error;
        statusLabel = 'payment_status_failed'.tr;
        break;
      case 'cancelled':
        statusBgColor = Colors.orange.shade100;
        statusTextColor = Colors.orange.shade700;
        statusIcon = Icons.cancel;
        statusLabel = 'cancelled'.tr;
        break;
      case 'unpaid':
      default:
        statusBgColor = Colors.amber.shade100;
        statusTextColor = Colors.amber.shade800;
        statusIcon = Icons.schedule;
        statusLabel = 'payment_status_unpaid'.tr;
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
    final isWide =
        MediaQuery.of(context).size.width >=
        _OrderDetailPageState._webBreakpoint;
    final deliveryman = order.deliveryman;
    _prefetchDeliverymanReview(order);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isWide ? 0 : 16),
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
                if (deliveryman?.phone.trim().isNotEmpty == true)
                  IconButton(
                    onPressed: () => _callDeliveryman(deliveryman!.phone),
                    icon: Icon(Icons.call, color: ColorResource.primaryDark),
                    tooltip: 'call_deliveryman'.tr,
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

  /// Opens the phone dialer; toasts when the device has none (web, tablets).
  Future<void> _callDeliveryman(String phone) async {
    try {
      final opened = await launchUrl(
        Uri(scheme: 'tel', path: phone.trim()),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) customToster('could_not_open_link'.tr, isSuccess: false);
    } catch (_) {
      customToster('could_not_open_link'.tr, isSuccess: false);
    }
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

  /// The code the customer reads out on the doorstep — see
  /// [DeliveryCodeCard]. Inset on mobile; flush in the web summary rail.
  Widget _buildVerificationCode(OrderModel order) {
    final isWide =
        MediaQuery.of(context).size.width >=
        _OrderDetailPageState._webBreakpoint;
    return DeliveryCodeCard(
      code: order.deliveryVerificationCode!,
      margin: EdgeInsets.symmetric(
        horizontal: isWide ? 0 : Constants.paddingSizeDefault,
      ),
    );
  }

  /// A cancelled order paid by wallet or card can be refunded; once asked
  /// for, the card stays to show where the request stands.
  bool _shouldShowRefund(OrderModel order) =>
      _orderController.canRequestRefund(order) || order.refundStatus.isNotEmpty;

  Widget _buildRefundCard(OrderModel order) {
    final isWide =
        MediaQuery.of(context).size.width >=
        _OrderDetailPageState._webBreakpoint;
    return RefundRequestCard(
      order: order,
      canRequest: _orderController.canRequestRefund(order),
      isBusy: _orderController.isRequestingRefund,
      onRequest: () => _confirmRefundRequest(order),
      margin: EdgeInsets.symmetric(
        horizontal: isWide ? 0 : Constants.paddingSizeDefault,
      ),
    );
  }

  Future<void> _confirmRefundRequest(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'request_refund'.tr,
          style: poppinsBold.copyWith(fontSize: Constants.fontSizeLarge),
        ),
        content: Text(
          'request_refund_confirm'.tr,
          style: poppinsRegular.copyWith(fontSize: Constants.fontSizeDefault),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'close'.tr,
              style: poppinsMedium.copyWith(color: context.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorResource.primaryDark,
            ),
            child: Text(
              'request_refund'.tr,
              style: poppinsBold.copyWith(color: ColorResource.textWhite),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final success = await _orderController.requestRefund(order.id);
    if (!mounted) return;
    customToster(
      success ? 'refund_request_sent'.tr : 'refund_request_failed'.tr,
      isSuccess: success,
    );
  }

  Widget _buildTrackingInfo(OrderModel order) {
    final isWide =
        MediaQuery.of(context).size.width >=
        _OrderDetailPageState._webBreakpoint;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isWide ? 0 : 16),
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
}
