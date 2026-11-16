import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kikomart_user_app/app/resources/colors.dart';
import 'package:kikomart_user_app/app/resources/constants.dart';
import 'package:kikomart_user_app/app/resources/text_style.dart';
import 'package:kikomart_user_app/app/controllers/settings_controller.dart';

/// Food checkout's "deliver now / scheduled" row, with the closed-store notice.
class CheckoutDeliveryScheduleSection extends StatelessWidget {
  const CheckoutDeliveryScheduleSection({
    super.key,
    required this.deliveryType,
    required this.scheduleDisplayText,
    required this.storeStatus,
    required this.onChange,
  });

  final String deliveryType;
  final String? scheduleDisplayText;
  final ({bool isOpenNow, String? nextOpenLabel}) storeStatus;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final isNow = deliveryType == 'now';
    final showClosed = isNow && !storeStatus.isOpenNow;
    final scheduleTitle = isNow ? 'deliver_now'.tr : 'scheduled_delivery'.tr;
    // Live ASAP estimate from business setup (falls back when unconfigured).
    final businessSetup = Get.find<SettingsController>().businessSetup;
    final asapEstimate =
        businessSetup?.asapEstimateLabel ?? 'asap_30_45_mins'.tr;
    final scheduleSubtitle = isNow
        ? asapEstimate
        : (scheduleDisplayText ?? asapEstimate);

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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ColorResource.primaryDark.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isNow ? Icons.flash_on_rounded : Icons.schedule_rounded,
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            scheduleTitle,
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeDefault,
                              color: context.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: ColorResource.primaryDark.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isNow ? 'asap'.tr : 'scheduled'.tr,
                            style: poppinsBold.copyWith(
                              fontSize: Constants.fontSizeExtraSmall,
                              color: ColorResource.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      scheduleSubtitle,
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
              OutlinedButton(
                onPressed: onChange,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorResource.primaryDark,
                  side: BorderSide(
                    color: ColorResource.primaryDark.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'change'.tr,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: ColorResource.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          if (showClosed) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'store_is_currently_closed'.tr,
                          style: poppinsBold.copyWith(
                            fontSize: Constants.fontSizeSmall,
                            color: Colors.orange[900],
                          ),
                        ),
                        if (storeStatus.nextOpenLabel != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            storeStatus.nextOpenLabel!,
                            style: poppinsRegular.copyWith(
                              fontSize: Constants.fontSizeSmall,
                              color: Colors.orange[900],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
