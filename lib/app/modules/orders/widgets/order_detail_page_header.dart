part of '../screens/order_detail_page.dart';

extension _OrderDetailPageHeader on _OrderDetailPageState {
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
        if (_shouldShowRefund(order)) ...[
          const SizedBox(height: 16),
          _buildRefundCard(order),
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
      if (_shouldShowRefund(order)) ...[
        _buildRefundCard(order),
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
        constraints: const BoxConstraints(
          maxWidth: _OrderDetailPageState._maxContentWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
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
                    const SizedBox(width: 20),
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

  // Web/desktop: the same header, boxed and rounded instead of full-bleed.
  Widget _buildWebHeaderCard(OrderModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: ColorResource.primaryGradient,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: _buildOrderHeaderContent(order),
    );
  }

  // Mobile: full-bleed under the app bar.
  Widget _buildHeader(OrderModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: ColorResource.primaryGradient,
        boxShadow: ColorResource.customShadow,
      ),
      child: _buildOrderHeaderContent(order),
    );
  }

  /// The header both layouts share.
  ///
  /// Status leads, because "where is my order?" is the question that brought
  /// the customer to this screen — the order number is a reference they need
  /// only when contacting support, so it moved down into the facts strip. The
  /// strip also carries the item count and total, which used to live in a
  /// separate white card repeating what the header already said.
  Widget _buildOrderHeaderContent(OrderModel order) {
    final status = _statusVisual(order.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // The tile carries the status colour rather than a pastel pill
            // floating on the gradient: green/amber/red still reads at a
            // glance, and the label beside it stays white for contrast.
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: status.background,
                borderRadius: BorderRadius.circular(
                  Constants.radiusDefault + 2,
                ),
              ),
              child: Icon(status.icon, size: 24, color: status.foreground),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.label,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeExtraLarge,
                      color: ColorResource.textWhite,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 13,
                        color: ColorResource.textWhite.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        // Short date form: the weekday spelled out in full runs
                        // long in Bengali and Arabic and pushed the time off the
                        // end of the line.
                        child: Text(
                          '${'placed_on'.tr} '
                          '${StoreTime.format(order.createdAt, 'MMM dd, yyyy • hh:mm a')}',
                          style: poppinsRegular.copyWith(
                            fontSize: Constants.fontSizeSmall,
                            color: ColorResource.textWhite.withValues(
                              alpha: 0.85,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        _buildScheduledLine(order),
        const SizedBox(height: Constants.paddingSizeDefault),
        Divider(
          height: 1,
          thickness: 1,
          color: ColorResource.textWhite.withValues(alpha: 0.18),
        ),
        const SizedBox(height: Constants.paddingSizeDefault - 1),
        _buildHeaderFacts(order),
      ],
    );
  }

  /// The three references a customer reaches for on a placed order, read left
  /// to right in the order they are needed: which order, how much of it, what
  /// it cost.
  Widget _buildHeaderFacts(OrderModel order) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: _headerFact(
            label: 'order_id'.tr,
            value: '#${order.orderNumber}',
            alignment: CrossAxisAlignment.start,
            textAlign: TextAlign.start,
          ),
        ),
        _headerFactDivider(),
        Expanded(
          flex: 3,
          child: _headerFact(
            label: 'items'.tr,
            value: '${order.items.length}',
            alignment: CrossAxisAlignment.center,
            textAlign: TextAlign.center,
          ),
        ),
        _headerFactDivider(),
        Expanded(
          flex: 4,
          child: _headerFact(
            label: 'total'.tr,
            value: PriceHelper.formatPrice(order.totalAmount),
            alignment: CrossAxisAlignment.end,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _headerFact({
    required String label,
    required String value,
    required CrossAxisAlignment alignment,
    required TextAlign textAlign,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: textAlign,
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeExtraSmall,
            color: ColorResource.textWhite.withValues(alpha: 0.7),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Shrinks rather than truncates: a long order number or a large total
        // must never lose its last digits.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: switch (alignment) {
            CrossAxisAlignment.center => Alignment.center,
            CrossAxisAlignment.end => AlignmentDirectional.centerEnd,
            _ => AlignmentDirectional.centerStart,
          },
          child: Text(
            value,
            textAlign: textAlign,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeLarge,
              color: ColorResource.textWhite,
              height: 1.2,
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _headerFactDivider() {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(
        horizontal: Constants.paddingSizeSmall,
      ),
      color: ColorResource.textWhite.withValues(alpha: 0.18),
    );
  }

  /// The delivery slot, shown only on scheduled orders (empty for ASAP).
  ///
  /// Two lines, not one: `Scheduled Delivery: Tue, Aug 26 • 2:00 PM - 4:00 PM`
  /// is wider than a phone at this type size, so as a single ellipsised line it
  /// cut off the end of the window — the half of the sentence the customer
  /// actually needs. The label sits above the slot, and the slot itself is free
  /// to wrap. Times render in the store timezone.
  Widget _buildScheduledLine(OrderModel order) {
    final start = order.scheduledStart;
    if (start == null) return const SizedBox.shrink();

    final day = StoreTime.format(start, 'EEE, MMM dd');
    // `h:mm` rather than `hh:mm`: a leading zero on "02:00 PM" buys nothing and
    // costs width on the line most at risk of running out of it.
    final startTime = StoreTime.format(start, 'h:mm a');
    final endTime = order.scheduledEnd != null
        ? StoreTime.format(order.scheduledEnd!, 'h:mm a')
        : null;
    final slot = endTime != null ? '$startTime - $endTime' : startTime;

    return Padding(
      padding: const EdgeInsets.only(top: Constants.paddingSizeSmall + 2),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: Constants.paddingSizeSmall,
          vertical: Constants.paddingSizeSmall - 2,
        ),
        decoration: BoxDecoration(
          color: ColorResource.textWhite.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(Constants.radiusDefault),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 16,
              color: ColorResource.textWhite,
            ),
            const SizedBox(width: Constants.paddingSizeSmall - 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'scheduled_delivery'.tr,
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeExtraSmall,
                      color: ColorResource.textWhite.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$day • $slot',
                    style: poppinsMedium.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: ColorResource.textWhite,
                      height: 1.35,
                    ),
                    // Wraps rather than truncates — the window is the point.
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
