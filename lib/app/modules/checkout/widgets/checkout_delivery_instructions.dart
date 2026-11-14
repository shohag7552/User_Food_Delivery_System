import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kikomart_user_app/app/resources/colors.dart';
import 'package:kikomart_user_app/app/resources/constants.dart';
import 'package:kikomart_user_app/app/resources/text_style.dart';

class CheckoutDeliveryInstructions extends StatelessWidget {
  const CheckoutDeliveryInstructions({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'delivery_instructions'.tr,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeLarge,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'delivery_instructions_hint'.tr,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Constants.radiusDefault),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}
