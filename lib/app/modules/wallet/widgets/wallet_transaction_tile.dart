import 'package:kikomart_user_app/app/helper/currency_helper.dart';
import 'package:kikomart_user_app/app/helper/store_time_helper.dart';
import 'package:kikomart_user_app/app/models/wallet_transaction_model.dart';
import 'package:kikomart_user_app/app/resources/colors.dart';
import 'package:kikomart_user_app/app/resources/constants.dart';
import 'package:kikomart_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One row of the wallet history: what happened, when, and how much came in
/// (green, +) or went out (red, −).
class WalletTransactionTile extends StatelessWidget {
  final WalletTransactionModel transaction;

  const WalletTransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final accent = isCredit ? ColorResource.success : ColorResource.error;
    final amount = CurrencyHelper.formatAmount(transaction.amount.abs());

    return Container(
      padding: const EdgeInsets.all(Constants.paddingSizeDefault),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        border: Border.all(color: context.textLight.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Constants.radiusDefault),
            ),
            child: Icon(_icon, color: accent, size: 22),
          ),
          const SizedBox(width: Constants.paddingSizeDefault),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: poppinsMedium.copyWith(
                    fontSize: Constants.fontSizeDefault,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: Constants.paddingSizeExtraSmall),
                Text(
                  StoreTime.format(
                    transaction.createdAt,
                    'dd MMM yyyy, hh:mm a',
                  ),
                  style: poppinsRegular.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: context.textLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Constants.paddingSizeSmall),
          Text(
            '${isCredit ? '+' : '−'}$amount',
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeLarge,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  IconData get _icon => switch (transaction.type) {
    WalletTransactionModel.typeOrderPayment => Icons.shopping_bag_outlined,
    WalletTransactionModel.typeOrderRefund => Icons.replay_rounded,
    WalletTransactionModel.typeLoyaltyConversion => Icons.card_giftcard_outlined,
    WalletTransactionModel.typeAdminAdjustment => Icons.storefront_outlined,
    _ => Icons.account_balance_wallet_outlined,
  };

  String get _title {
    final number = transaction.orderNumber ?? '';
    return switch (transaction.type) {
      WalletTransactionModel.typeOrderPayment when number.isNotEmpty =>
        'wallet_tx_order_payment'.trParams({'number': number}),
      WalletTransactionModel.typeOrderRefund when number.isNotEmpty =>
        'wallet_tx_order_refund'.trParams({'number': number}),
      WalletTransactionModel.typeOrderPayment => 'wallet_tx_order_payment_plain'.tr,
      WalletTransactionModel.typeOrderRefund => 'wallet_tx_order_refund_plain'.tr,
      WalletTransactionModel.typeLoyaltyConversion =>
        'wallet_tx_loyalty_conversion'.tr,
      WalletTransactionModel.typeAdminAdjustment => transaction.isCredit
          ? 'wallet_tx_added_by_store'.tr
          : 'wallet_tx_deducted_by_store'.tr,
      _ => 'wallet_transaction'.tr,
    };
  }
}
