import 'package:appwrite_user_app/app/controllers/deliveryman_review_controller.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The deliveryman's own public score, shown beside their name.
///
/// Renders nothing until a score exists: "0.0 ★" on a driver's first week
/// reads as a bad driver rather than as a new one.
class DeliverymanRatingBadge extends StatelessWidget {
  const DeliverymanRatingBadge({super.key, required this.driverId});

  final String? driverId;

  @override
  Widget build(BuildContext context) {
    final id = driverId;
    if (id == null || id.isEmpty) return const SizedBox.shrink();

    return GetBuilder<DeliverymanReviewController>(
      builder: (controller) {
        final summary = controller.getDriverSummary(id);
        if (summary == null || summary.count == 0) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Constants.paddingSizeSmall - 2,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: ColorResource.ratingStarColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(Constants.radiusExtraLarge),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: ColorResource.ratingStarColor,
                ),
                const SizedBox(width: 3),
                Text(
                  '${summary.average.toStringAsFixed(1)} (${summary.count})',
                  style: poppinsMedium.copyWith(
                    fontSize: Constants.fontSizeExtraSmall,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
