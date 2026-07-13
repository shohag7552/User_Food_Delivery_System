import 'package:appwrite_user_app/app/common/widgets/rating_stars.dart';
import 'package:appwrite_user_app/app/models/review_model.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final VoidCallback? onHelpful;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool isCurrentUser;
  final bool isMarkedHelpful;

  const ReviewCard({
    super.key,
    required this.review,
    this.onHelpful,
    this.onDelete,
    this.showActions = true,
    this.isCurrentUser = false,
    this.isMarkedHelpful = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusDefault),
        border: Border.all(
          color: context.textLight.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: User info and rating
          Row(
            children: [
              // User avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: ColorResource.primaryDark.withOpacity(0.1),
                child: Text(
                  review.userName[0].toUpperCase(),
                  style: poppinsBold.copyWith(
                    color: ColorResource.primaryDark,
                    fontSize: Constants.fontSizeLarge,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // User name and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            review.userName,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: poppinsMedium.copyWith(
                              fontSize: Constants.fontSizeDefault,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                        if (review.verifiedPurchase) ...[
                          const SizedBox(width: Constants.paddingSizeExtraSmall),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.verified,
                              size: 12,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeago.format(review.createdAt),
                      style: poppinsRegular.copyWith(
                        fontSize: Constants.fontSizeSmall,
                        color: context.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              // Rating
              RatingStars(
                rating: review.rating.toDouble(),
                size: 16,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Title
          if (review.title != null && review.title!.isNotEmpty) ...{
            Text(
              review.title!,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
          },

          // Comment
          Text(
            review.comment,
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: context.textSecondary,
              height: 1.5,
            ),
          ),

          if (showActions) ...[
            const SizedBox(height: 12),
            // Actions
            Row(
              children: [
                // Helpful button
                if (onHelpful != null && !isCurrentUser)
                  GestureDetector(
                    onTap: onHelpful,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isMarkedHelpful
                            ? ColorResource.primaryDark.withValues(alpha: 0.1)
                            : context.scaffoldBackground,
                        borderRadius: BorderRadius.circular(
                          Constants.radiusSmall,
                        ),
                        border: Border.all(
                          color: isMarkedHelpful
                              ? ColorResource.primaryDark.withValues(alpha: 0.4)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isMarkedHelpful
                                ? Icons.thumb_up
                                : Icons.thumb_up_outlined,
                            size: 14,
                            color: isMarkedHelpful
                                ? ColorResource.primaryDark
                                : context.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Helpful',
                            style: poppinsMedium.copyWith(
                              fontSize: Constants.fontSizeSmall,
                              color: isMarkedHelpful
                                  ? ColorResource.primaryDark
                                  : context.textSecondary,
                            ),
                          ),
                          if (review.helpfulCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${review.helpfulCount})',
                              style: poppinsMedium.copyWith(
                                fontSize: Constants.fontSizeSmall,
                                color: ColorResource.primaryDark,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                const Spacer(),

                // Delete button (only for current user)
                if (isCurrentUser && onDelete != null)
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ColorResource.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          Constants.radiusSmall,
                        ),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: ColorResource.error,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
