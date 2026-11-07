import 'package:kikomart_user_app/app/helper/currency_helper.dart';
import 'package:kikomart_user_app/app/models/order_model.dart';
import 'package:kikomart_user_app/app/resources/colors.dart';
import 'package:kikomart_user_app/app/resources/constants.dart';
import 'package:kikomart_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Refund for a cancelled order paid by wallet or card: the button that asks
/// the store for it, then where that request stands. An approved refund is
/// paid into the customer's wallet.
class RefundRequestCard extends StatelessWidget {
  final OrderModel order;

  /// Shown as the button while the order has no refund request yet.
  final bool canRequest;
  final bool isBusy;
  final VoidCallback onRequest;
  final EdgeInsetsGeometry margin;

  const RefundRequestCard({
    super.key,
    required this.order,
    required this.canRequest,
    required this.isBusy,
    required this.onRequest,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final amount = CurrencyHelper.formatAmount(order.totalAmount);
    final (IconData icon, Color color, String message) =
        switch (order.refundStatus) {
          'requested' => (
            Icons.hourglass_top_rounded,
            ColorResource.warning,
            'refund_requested_waiting'.tr,
          ),
          'refunded' => (
            Icons.account_balance_wallet_rounded,
            ColorResource.success,
            'refund_added_to_wallet'.trParams({'amount': amount}),
          ),
          'rejected' => (
            Icons.block_rounded,
            ColorResource.error,
            'refund_request_rejected'.tr,
          ),
          _ => (
            Icons.replay_rounded,
            ColorResource.primaryDark,
            'refund_available_hint'.trParams({'amount': amount}),
          ),
        };

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(Constants.paddingSizeDefault),
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
              Icon(icon, size: 20, color: color),
              const SizedBox(width: Constants.paddingSizeSmall),
              Expanded(
                child: Text(
                  'refund'.tr,
                  style: poppinsMedium.copyWith(
                    fontSize: Constants.fontSizeDefault,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Constants.paddingSizeSmall),
          Text(
            message,
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeSmall,
              color: context.textSecondary,
            ),
          ),
          if (canRequest) ...[
            const SizedBox(height: Constants.paddingSizeDefault),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isBusy ? null : onRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorResource.primaryDark,
                  padding: const EdgeInsets.symmetric(
                    vertical: Constants.paddingSizeDefault,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Constants.radiusLarge),
                  ),
                ),
                child: isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColorResource.textWhite,
                        ),
                      )
                    : Text(
                        'request_refund'.tr,
                        style: poppinsBold.copyWith(
                          color: ColorResource.textWhite,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
