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

  const ReviewCard({
    super.key,
    required this.review,
    this.onHelpful,
    this.onDelete,
    this.showActions = true,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusDefault),
        border: Border.all(
          color: ColorResource.textLight.withOpacity(0.1),
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
                        Text(
                          review.userName,
                          style: poppinsMedium.copyWith(
                            fontSize: Constants.fontSizeDefault,
                            color: ColorResource.textPrimary,
                          ),
                        ),
                        if (review.verifiedPurchase) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 12,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Verified',
                                  style: poppinsMedium.copyWith(
                                    fontSize: 10,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
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
                        color: ColorResource.textLight,
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
                color: ColorResource.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
          },

          // Comment
          Text(
            review.comment,
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: ColorResource.textSecondary,
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ColorResource.scaffoldBackground,
                        borderRadius: BorderRadius.circular(
                          Constants.radiusSmall,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.thumb_up_outlined,
                            size: 14,
                            color: ColorResource.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Helpful',
                            style: poppinsRegular.copyWith(
                              fontSize: Constants.fontSizeSmall,
                              color: ColorResource.textSecondary,
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
