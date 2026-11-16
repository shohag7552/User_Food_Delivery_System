part of '../screens/order_detail_page.dart';

extension _OrderDetailPageActions on _OrderDetailPageState {
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
    final isWide = screenWidth >= _OrderDetailPageState._webBreakpoint;

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
      padding: EdgeInsets.zero,
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
