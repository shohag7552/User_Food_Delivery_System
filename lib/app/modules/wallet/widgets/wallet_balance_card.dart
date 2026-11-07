import 'package:kikomart_user_app/app/helper/currency_helper.dart';
import 'package:kikomart_user_app/app/resources/colors.dart';
import 'package:kikomart_user_app/app/resources/constants.dart';
import 'package:kikomart_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Brand-gradient card at the top of the wallet page, showing the balance.
/// Same surface as the Loyalty Points summary card.
class WalletBalanceCard extends StatelessWidget {
  final double balance;

  const WalletBalanceCard({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  ColorResource.brandShade(0.29),
                  ColorResource.brandShade(0.47),
                  ColorResource.brandShade(0.63),
                ]
              : [
                  ColorResource.primaryMedium,
                  ColorResource.primaryDark,
                  ColorResource.brandShade(0.21),
                ],
        ),
        borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
        boxShadow: [
          BoxShadow(
            color: ColorResource.primaryDark.withValues(
              alpha: isDark ? 0.35 : 0.2,
            ),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Watermark, as on the loyalty card.
          PositionedDirectional(
            end: -20,
            bottom: -20,
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 180,
              color: ColorResource.textWhite.withValues(
                alpha: isDark ? 0.04 : 0.06,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Constants.paddingSizeExtraLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(
                        Constants.paddingSizeSmall,
                      ),
                      decoration: BoxDecoration(
                        color: ColorResource.textWhite.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          Constants.radiusDefault,
                        ),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: ColorResource.textWhite,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: Constants.paddingSizeSmall),
                    Text(
                      'wallet_balance'.tr,
                      style: poppinsMedium.copyWith(
                        fontSize: Constants.fontSizeLarge,
                        color: ColorResource.textWhite.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Constants.paddingSizeLarge),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    CurrencyHelper.formatAmount(balance),
                    style: poppinsBold.copyWith(
                      fontSize: 34,
                      color: ColorResource.textWhite,
                    ),
                  ),
                ),
                const SizedBox(height: Constants.paddingSizeSmall),
                Text(
                  'wallet_balance_hint'.tr,
                  style: poppinsRegular.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: ColorResource.textWhite.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
