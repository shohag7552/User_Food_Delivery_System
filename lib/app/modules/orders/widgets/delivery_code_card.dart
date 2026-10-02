import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The code the customer reads out to the deliveryman on the doorstep.
///
/// A plain order card, like its neighbours: the title and the code share one
/// centred row, and the hint runs full width beneath them so it never has to
/// squeeze in beside the code.
class DeliveryCodeCard extends StatelessWidget {
  final String code;
  final EdgeInsetsGeometry margin;

  const DeliveryCodeCard({
    super.key,
    required this.code,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
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
              Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: context.textSecondary,
              ),
              const SizedBox(width: Constants.paddingSizeExtraSmall + 3),
              Expanded(
                child: Text(
                  'delivery_code'.tr,
                  style: poppinsMedium.copyWith(
                    fontSize: Constants.fontSizeDefault,
                    color: context.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: Constants.paddingSizeSmall),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Constants.paddingSizeSmall + 2,
                  vertical: Constants.paddingSizeExtraSmall + 1,
                ),
                decoration: BoxDecoration(
                  color: ColorResource.primaryDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(Constants.radiusDefault),
                ),
                child: Text(
                  code.trim(),
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeExtraLarge + 2,
                    color: ColorResource.primaryDark,
                    letterSpacing: 3,
                    height: 1.2,
                    // Digits read aloud must not wobble between glyph widths.
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Constants.paddingSizeSmall),
          Text(
            'share_code_with_deliveryman'.tr,
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeSmall,
              color: context.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
