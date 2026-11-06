import 'package:kikomart_user_app/app/common/widgets/custom_button.dart';
import 'package:kikomart_user_app/app/controllers/loyalty_controller.dart';
import 'package:kikomart_user_app/app/controllers/profile_controller.dart';
import 'package:kikomart_user_app/app/helper/currency_helper.dart';
import 'package:kikomart_user_app/app/resources/colors.dart';
import 'package:kikomart_user_app/app/resources/constants.dart';
import 'package:kikomart_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// "Convert loyalty points" dialog: enter points, see the wallet amount, convert.
///
/// Owns its [TextEditingController] so it is disposed only when the dialog is
/// really gone. Disposing it when `showDialog` returns is too early: the
/// dialog still rebuilds during its closing animation and would use a
/// disposed controller.
class ConvertPointsDialog extends StatefulWidget {
  const ConvertPointsDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => const ConvertPointsDialog(),
  );

  @override
  State<ConvertPointsDialog> createState() => _ConvertPointsDialogState();
}

class _ConvertPointsDialogState extends State<ConvertPointsDialog> {
  final _pointsController = TextEditingController();

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loyaltyController = Get.find<LoyaltyController>();
    final totalPoints =
        Get.find<ProfileController>().userProfile?.loyaltyPoints ?? 0;
    final walletConversionRate = loyaltyController.walletConversionRate;

    final enteredPoints = int.tryParse(_pointsController.text.trim()) ?? 0;
    final validationMessage = _getConversionValidation(
      _pointsController.text.trim(),
      totalPoints: totalPoints,
      walletConversionRate: walletConversionRate,
    );
    final convertedAmount = CurrencyHelper.formatWithSeparators(
      enteredPoints / walletConversionRate,
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Text(
        'convert_loyalty_points'.tr,
        style: poppinsBold.copyWith(fontSize: 20),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'available_points_count'.trParams({
                'points': NumberFormat.decimalPattern().format(totalPoints),
              }),
              style: poppinsMedium.copyWith(color: context.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'conversion_rate_points_to_amount'.trParams({
                'points': '$walletConversionRate',
                'amount': CurrencyHelper.formatAmount(1),
              }),
              style: poppinsRegular.copyWith(
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pointsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'enter_points_to_convert'.tr,
                hintText: 'points_input_hint'.tr,
                errorText: validationMessage,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: ColorResource.primaryDark,
                    width: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorResource.primaryDark.withValues(
                  alpha: 0.08,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'you_will_receive'.tr,
                    style: poppinsRegular.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    convertedAmount,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeLarge,
                      color: ColorResource.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'cancel'.tr,
            style: poppinsMedium.copyWith(color: context.textSecondary),
          ),
        ),
        SizedBox(
          width: 120,
          child: GetBuilder<LoyaltyController>(
            builder: (controller) {
              return CustomButton(
                onPressed:
                    validationMessage != null || controller.isConverting
                    ? null
                    : () async {
                        final converted = await controller
                            .convertPointsToWallet(enteredPoints);
                        if (converted && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                buttonText: 'convert'.tr,
                height: 46,
                elevation: 0,
                isLoading: controller.isConverting,
              );
            },
          ),
        ),
      ],
    );
  }

  String? _getConversionValidation(
    String value, {
    required int totalPoints,
    required double walletConversionRate,
  }) {
    if (value.isEmpty) {
      return 'enter_loyalty_points_to_convert'.tr;
    }

    if (walletConversionRate <= 0) {
      return 'wallet_conversion_unavailable'.tr;
    }

    final points = int.tryParse(value);
    if (points == null) {
      return 'enter_valid_number'.tr;
    }

    if (points <= 0) {
      return 'points_must_be_greater_than_zero'.tr;
    }

    if (points > totalPoints) {
      return 'you_only_have_points'.trParams({
        'points': NumberFormat.decimalPattern().format(totalPoints),
      });
    }

    return null;
  }
}
