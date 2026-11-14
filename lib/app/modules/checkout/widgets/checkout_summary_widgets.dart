import 'package:flutter/material.dart';
import 'package:kikomart_user_app/app/resources/colors.dart';
import 'package:kikomart_user_app/app/resources/constants.dart';
import 'package:kikomart_user_app/app/resources/text_style.dart';
import 'package:kikomart_user_app/app/helper/currency_helper.dart';

class CheckoutSummaryRow extends StatelessWidget {
  const CheckoutSummaryRow(
    this.label,
    this.amount, {
    super.key,
    this.isTotal = false,
    this.isDiscount = false,
  });

  final String label;
  final double amount;
  final bool isTotal;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (isTotal ? poppinsBold : poppinsRegular).copyWith(
            fontSize: isTotal
                ? Constants.fontSizeLarge
                : Constants.fontSizeDefault,
            color: isDiscount ? Colors.green : context.textPrimary,
          ),
        ),
        Text(
          CurrencyHelper.formatAmount(amount),
          style: (isTotal ? poppinsBold : poppinsMedium).copyWith(
            fontSize: isTotal
                ? Constants.fontSizeLarge
                : Constants.fontSizeDefault,
            color: isDiscount
                ? Colors.green
                : (isTotal ? ColorResource.primaryDark : context.textPrimary),
          ),
        ),
      ],
    );
  }
}

class CheckoutBlockedButtonContent extends StatelessWidget {
  const CheckoutBlockedButtonContent(this.icon, this.label, {super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: ColorResource.textWhite, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: ColorResource.textWhite,
            ),
          ),
        ),
      ],
    );
  }
}
