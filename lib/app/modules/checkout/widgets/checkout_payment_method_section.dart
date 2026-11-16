import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kikomart_user_app/app/resources/colors.dart';
import 'package:kikomart_user_app/app/resources/constants.dart';
import 'package:kikomart_user_app/app/resources/text_style.dart';
import 'package:kikomart_user_app/app/controllers/profile_controller.dart';
import 'package:kikomart_user_app/app/controllers/settings_controller.dart';
import 'package:kikomart_user_app/app/enums/payment_method_enum.dart';
import 'package:kikomart_user_app/app/helper/currency_helper.dart';

/// Payment method radios, limited to what the store accepts, plus the gateway
/// chips for online payment. [onMethodChanged] is also called after the frame
/// when the current choice is no longer offered.
class CheckoutPaymentMethodSection extends StatelessWidget {
  const CheckoutPaymentMethodSection({
    super.key,
    required this.selectedMethod,
    required this.selectedGateway,
    required this.gateways,
    required this.onMethodChanged,
    required this.onGatewayChanged,
  });

  final PaymentMethod selectedMethod;
  final PaymentGateway selectedGateway;
  final List<PaymentGateway> gateways;
  final ValueChanged<PaymentMethod> onMethodChanged;
  final ValueChanged<PaymentGateway> onGatewayChanged;

  @override
  Widget build(BuildContext context) {
    final businessSetup = Get.find<SettingsController>().businessSetup;
    final codActive = businessSetup?.acceptsCash ?? true; // is_cod_active
    final onlineActive =
        businessSetup?.acceptsOnlinePayment ?? false; // is_digital_active
    final walletActive =
        businessSetup?.acceptsDigitalWallet ?? false; // is_wallet_active

    // Keep the chosen method within what's actually enabled.
    final available = <PaymentMethod>[
      if (codActive) PaymentMethod.cod,
      if (onlineActive) PaymentMethod.online,
      if (walletActive) PaymentMethod.wallet,
    ];
    if (available.isNotEmpty && !available.contains(selectedMethod)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onMethodChanged(available.first);
      });
    }

    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'payment_method'.tr,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeLarge,
                color: context.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          if (codActive)
            RadioListTile<PaymentMethod>(
              value: PaymentMethod.cod,
              groupValue: selectedMethod,
              onChanged: (value) => onMethodChanged(value!),
              title: Row(
                children: [
                  Icon(Icons.money, color: Colors.green),
                  const SizedBox(width: 12),
                  Text(
                    'cash_on_delivery'.tr,
                    style: poppinsMedium.copyWith(
                      fontSize: Constants.fontSizeDefault,
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                'pay_when_you_receive'.tr,
                style: poppinsRegular.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: context.textSecondary,
                ),
              ),
              activeColor: ColorResource.primaryDark,
            ),
          if (onlineActive)
            RadioListTile<PaymentMethod>(
              value: PaymentMethod.online,
              groupValue: selectedMethod,
              onChanged: (value) => onMethodChanged(value!),
              title: Row(
                children: [
                  Icon(
                    Icons.credit_card,
                    color: selectedMethod == PaymentMethod.online
                        ? ColorResource.primaryDark
                        : context.textLight,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'online_payment'.tr,
                    style: poppinsMedium.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: selectedMethod == PaymentMethod.online
                          ? context.textPrimary
                          : context.textLight,
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                'pay_securely_online'.tr,
                style: poppinsRegular.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: selectedMethod == PaymentMethod.online
                      ? context.textSecondary
                      : context.textLight,
                ),
              ),
              activeColor: ColorResource.primaryDark,
            ),
          // Gateway selection chips — visible when online is selected
          if (onlineActive)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: selectedMethod == PaymentMethod.online
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'choose_gateway'.tr,
                            style: poppinsMedium.copyWith(
                              fontSize: Constants.fontSizeSmall,
                              color: context.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: gateways.map((gateway) {
                              final isSelected = selectedGateway == gateway;
                              return ChoiceChip(
                                label: Text(gateway.displayName),
                                selected: isSelected,
                                onSelected: (_) => onGatewayChanged(gateway),
                                selectedColor: ColorResource.primaryDark
                                    .withValues(alpha: 0.15),
                                backgroundColor: context.scaffoldBackground,
                                labelStyle: poppinsMedium.copyWith(
                                  fontSize: Constants.fontSizeSmall,
                                  color: isSelected
                                      ? ColorResource.primaryDark
                                      : context.textSecondary,
                                ),
                                side: BorderSide(
                                  color: isSelected
                                      ? ColorResource.primaryDark
                                      : Colors.grey.shade300,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedGateway.description,
                            style: poppinsRegular.copyWith(
                              fontSize: Constants.fontSizeExtraSmall,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          if (walletActive)
            GetBuilder<ProfileController>(
              builder: (profileController) {
                final walletBalance = profileController.walletBalance;
                return RadioListTile<PaymentMethod>(
                  value: PaymentMethod.wallet,
                  groupValue: selectedMethod,
                  onChanged: (value) => onMethodChanged(value!),
                  title: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: selectedMethod == PaymentMethod.wallet
                            ? ColorResource.primaryDark
                            : context.textLight,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'wallet'.tr,
                          style: poppinsMedium.copyWith(
                            fontSize: Constants.fontSizeDefault,
                            color: selectedMethod == PaymentMethod.wallet
                                ? context.textPrimary
                                : context.textLight,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: walletBalance > 0
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          CurrencyHelper.formatAmount(walletBalance),
                          style: poppinsBold.copyWith(
                            fontSize: Constants.fontSizeSmall,
                            color: walletBalance > 0
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    'pay_from_wallet_balance'.tr,
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: selectedMethod == PaymentMethod.wallet
                          ? context.textSecondary
                          : context.textLight,
                    ),
                  ),
                  activeColor: ColorResource.primaryDark,
                );
              },
            ),
        ],
      ),
    );
  }
}
