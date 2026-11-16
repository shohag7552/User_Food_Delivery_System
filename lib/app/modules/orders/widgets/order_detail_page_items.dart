part of '../screens/order_detail_page.dart';

extension _OrderDetailPageItems on _OrderDetailPageState {
  Widget _buildItemsList(OrderModel order) {
    _prefetchUserReviews(order);
    final isWide =
        MediaQuery.of(context).size.width >=
        _OrderDetailPageState._webBreakpoint;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isWide ? 0 : 16),
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
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: _borderColor,
            ),
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
                          fontSize: Constants.fontSizeExtraSmall,
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
                        fontSize: Constants.fontSizeExtraSmall,
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
        Icon(
          Icons.check_circle_rounded,
          size: 15,
          color: ColorResource.success,
        ),
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
}
