import 'package:appwrite_user_app/app/controllers/deliveryman_review_controller.dart';
import 'package:appwrite_user_app/app/models/deliveryman_review_model.dart';
import 'package:appwrite_user_app/app/models/order_model.dart';
import 'package:appwrite_user_app/app/modules/reviews/widgets/rate_deliveryman_bottomsheet.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The rating block that lives at the foot of the deliveryman card on an order.
///
/// It is three states in one: an invitation to rate, the rating already given,
/// or nothing at all — an order that cannot be rated (counter sale, courier
/// shipment, still in flight) renders zero height rather than an explanation
/// nobody asked for.
class DeliverymanReviewSection extends StatelessWidget {
  const DeliverymanReviewSection({
    super.key,
    required this.order,
    required this.isLoggedIn,
  });

  final OrderModel order;
  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DeliverymanReviewController>(
      builder: (controller) {
        if (!controller.canShowDeliveryRating(order) || !isLoggedIn) {
          return const SizedBox.shrink();
        }

        final review = controller.getOrderReview(order.id);
        final isResolved = controller.hasOrderReviewLoaded(order.id);
        final canStillRate = controller.canReviewDelivery(order);

        // Past the rating window with nothing given, there is nothing to show:
        // a prompt that cannot be acted on is worse than no prompt.
        if (review == null && isResolved && !canStillRate) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: Constants.paddingSizeDefault),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: review != null
                ? _SubmittedRatingPanel(
                    order: order,
                    review: review,
                    isEditable: canStillRate,
                  )
                : isResolved
                ? _RatePrompt(order: order)
                : const _LoadingPanel(),
          ),
        );
      },
    );
  }
}

/// Placeholder held while the existing rating is being looked up. It occupies
/// the same footprint as the prompt so the card does not jump when it resolves.
class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.scaffoldBackground,
        borderRadius: BorderRadius.circular(Constants.radiusDefault),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: ColorResource.primaryDark.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

/// The invitation. The stars are live: tapping one opens the sheet already on
/// that score, so the common case — a customer who just wants to give five
/// stars and leave — costs two taps instead of four.
class _RatePrompt extends StatelessWidget {
  const _RatePrompt({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Constants.paddingSizeDefault,
        vertical: Constants.paddingSizeDefault,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorResource.primaryDark.withValues(alpha: 0.10),
            ColorResource.primaryLight.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(Constants.radiusDefault),
        border: Border.all(
          color: ColorResource.primaryDark.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Text(
            'rate_your_delivery'.tr,
            textAlign: TextAlign.center,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'your_feedback_helps_us_improve_deliveries'.tr,
            textAlign: TextAlign.center,
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeExtraSmall,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: Constants.paddingSizeSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final star = index + 1;
              return IconButton(
                // The stars sit inside a scrolling card, so each needs a real
                // tap target rather than the icon's own bounds.
                constraints: const BoxConstraints(
                  minWidth: Constants.minTapTarget,
                  minHeight: Constants.minTapTarget,
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                tooltip: '$star',
                onPressed: () => openRateDeliverymanSheet(
                  context,
                  order: order,
                  initialRating: star,
                ),
                icon: Icon(
                  Icons.star_rounded,
                  size: 30,
                  color: ColorResource.ratingStarColor.withValues(alpha: 0.45),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// What the customer already said, with the way back in. Ratings are editable
/// because the alternative — a rating locked the instant it is tapped — is what
/// makes people hesitate before tapping at all.
class _SubmittedRatingPanel extends StatelessWidget {
  const _SubmittedRatingPanel({
    required this.order,
    required this.review,
    required this.isEditable,
  });

  final OrderModel order;
  final DeliverymanReviewModel review;

  /// False once the rating window has closed. The rating stays on screen; only
  /// the way back into it goes away.
  final bool isEditable;

  Color _accent() {
    if (review.rating <= 2) return ColorResource.error;
    if (review.rating == 3) return ColorResource.warning;
    return ColorResource.success;
  }

  String _label() {
    switch (review.rating) {
      case 1:
        return 'rating_very_bad'.tr;
      case 2:
        return 'rating_bad'.tr;
      case 3:
        return 'rating_okay'.tr;
      case 4:
        return 'rating_good'.tr;
      default:
        return 'rating_excellent'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Constants.paddingSizeDefault),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(Constants.radiusDefault),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_rounded, size: 18, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'you_rated_this_delivery'.tr,
                  style: poppinsMedium.copyWith(
                    fontSize: Constants.fontSizeSmall,
                    color: context.textPrimary,
                  ),
                ),
              ),
              if (isEditable)
                TextButton(
                  onPressed: () => openRateDeliverymanSheet(
                    context,
                    order: order,
                    existingReview: review,
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, Constants.minTapTarget),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Constants.paddingSizeSmall,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    'edit'.tr,
                    style: poppinsMedium.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: ColorResource.primaryDark,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Constants.paddingSizeExtraSmall),
          Row(
            children: [
              ...List.generate(
                5,
                (index) => Icon(
                  index < review.rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 20,
                  color: index < review.rating
                      ? ColorResource.ratingStarColor
                      : context.textLight,
                ),
              ),
              const SizedBox(width: Constants.paddingSizeSmall - 2),
              Text(
                _label(),
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: accent,
                ),
              ),
            ],
          ),
          if (review.tags.isNotEmpty) ...[
            const SizedBox(height: Constants.paddingSizeSmall),
            Wrap(
              spacing: Constants.paddingSizeExtraSmall,
              runSpacing: Constants.paddingSizeExtraSmall,
              children: review.tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Constants.paddingSizeSmall - 2,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: context.cardBackground,
                        borderRadius: BorderRadius.circular(
                          Constants.radiusExtraLarge,
                        ),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        tag.tr,
                        style: poppinsRegular.copyWith(
                          fontSize: Constants.fontSizeExtraSmall,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (review.hasComment) ...[
            const SizedBox(height: Constants.paddingSizeSmall),
            Text(
              review.comment!,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: context.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Opens the rating sheet. Shared by every entry point so the pre-selected
/// star, the edit path, and the state refresh afterwards behave identically.
Future<void> openRateDeliverymanSheet(
  BuildContext context, {
  required OrderModel order,
  int initialRating = 0,
  DeliverymanReviewModel? existingReview,
}) {
  return RateDeliverymanBottomSheet.show(
    context,
    order: order,
    existingReview: existingReview,
    initialRating: initialRating,
  );
}
