import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kikomart_user_app/app/resources/colors.dart';
import 'package:kikomart_user_app/app/resources/constants.dart';
import 'package:kikomart_user_app/app/resources/text_style.dart';
import 'package:kikomart_user_app/app/controllers/cart_controller.dart';
import 'package:kikomart_user_app/app/helper/currency_helper.dart';
import 'package:kikomart_user_app/app/modules/coupons/widgets/coupon_selection_bottomsheet.dart';

/// Checkout's promo-code row: a prompt, or the coupon already applied.
class CheckoutCouponSection extends StatelessWidget {
  const CheckoutCouponSection({super.key, required this.controller});

  final CartController controller;

  @override
  Widget build(BuildContext context) {
    return controller.appliedCoupon != null
        ? _appliedCoupon(context)
        : _applyPrompt(context);
  }

  Future<void> _openCouponSheet(BuildContext context) async {
    final result = await CouponSelectionBottomSheet.showAdaptive(context);
    if (result != null) {
      controller.applyCoupon(result);
    }
  }

  Widget _applyPrompt(BuildContext context) {
    return GestureDetector(
      onTap: () => _openCouponSheet(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(Constants.radiusLarge),
          boxShadow: ColorResource.customShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ColorResource.primaryDark.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_offer_rounded,
                size: 22,
                color: ColorResource.primaryDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'have_a_promo_code'.tr,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'apply_to_save'.tr,
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: context.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => _openCouponSheet(context),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: ColorResource.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'apply'.tr,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appliedCoupon(BuildContext context) {
    final coupon = controller.appliedCoupon!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorResource.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        border: Border.all(
          color: ColorResource.success.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ColorResource.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_offer_rounded,
              size: 22,
              color: ColorResource.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.cardBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: ColorResource.success.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.confirmation_number_outlined,
                        size: 13,
                        color: ColorResource.success,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        coupon.code,
                        style: poppinsBold.copyWith(
                          fontSize: Constants.fontSizeSmall,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${'you_saved_amount'.tr} ${CurrencyHelper.formatAmount(controller.discountAmount)}',
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: Colors.green.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => controller.removeCoupon(),
            style: TextButton.styleFrom(
              foregroundColor: ColorResource.error,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              'remove'.tr,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: ColorResource.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
