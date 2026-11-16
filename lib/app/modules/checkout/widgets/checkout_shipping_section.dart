import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kikomart_user_app/app/resources/colors.dart';
import 'package:kikomart_user_app/app/resources/constants.dart';
import 'package:kikomart_user_app/app/resources/text_style.dart';
import 'package:kikomart_user_app/app/controllers/cart_controller.dart';
import 'package:kikomart_user_app/app/controllers/shipping_controller.dart';
import 'package:kikomart_user_app/app/helper/currency_helper.dart';
import 'package:kikomart_user_app/app/models/shipping_method_model.dart';

/// Courier choice for ecommerce checkout.
class CheckoutShippingSection extends StatelessWidget {
  const CheckoutShippingSection({
    super.key,
    required this.selectedShippingId,
    required this.onSelected,
  });

  final String? selectedShippingId;
  final ValueChanged<ShippingMethodModel> onSelected;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ShippingController>(
      builder: (shippingController) {
        final methods = shippingController.methods;
        final cartTotal = Get.find<CartController>().total;

        return Container(
          padding: const EdgeInsets.all(14),
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
                    'shipping_method'.tr,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeLarge,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (shippingController.isLoading && methods.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (methods.isEmpty)
                Text(
                  'no_shipping_methods'.tr,
                  style: poppinsRegular.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: context.textSecondary,
                  ),
                )
              else
                ...methods.map((m) => _tile(context, m, cartTotal)),
            ],
          ),
        );
      },
    );
  }

  Widget _tile(
    BuildContext context,
    ShippingMethodModel method,
    double cartTotal,
  ) {
    final isSelected = selectedShippingId == method.id;
    final fee = method.feeFor(cartTotal);
    return GestureDetector(
      onTap: () => onSelected(method),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorResource.primaryDark.withValues(alpha: 0.06)
              : context.scaffoldBackground,
          borderRadius: BorderRadius.circular(Constants.radiusDefault),
          border: Border.all(
            color: isSelected ? ColorResource.primaryDark : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? ColorResource.primaryDark : context.textLight,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.name,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: context.textPrimary,
                    ),
                  ),
                  if ((method.estimatedDays ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      method.estimatedDays!,
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              fee <= 0 ? 'free'.tr : CurrencyHelper.formatAmount(fee),
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: fee <= 0
                    ? ColorResource.success
                    : ColorResource.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
