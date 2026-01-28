import 'package:appwrite_user_app/app/common/widgets/rating_stars.dart';
import 'package:appwrite_user_app/app/controllers/review_controller.dart';
import 'package:appwrite_user_app/app/modules/reviews/widgets/review_card.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReviewListSection extends StatelessWidget {
  final String productId;
  final String? currentUserId;

  const ReviewListSection({
    super.key,
    required this.productId,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReviewController>(
      builder: (controller) {
        final reviews = controller.getProductReviews(productId);
        final rating = controller.getProductRating(productId);
        final reviewCount = controller.getReviewCount(productId);
        final isLoading = controller.isLoading(productId);

        // Fetch reviews on first build
        if (!isLoading && reviews.isEmpty) {
          Future.microtask(() => controller.fetchProductReviews(productId));
        }

        if (isLoading && reviews.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating summary
            if (reviewCount > 0) ...[
              _buildRatingSummary(rating, reviewCount),
              const SizedBox(height: 24),
            ],

            // Reviews header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reviews ($reviewCount)',
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeLarge,
                    color: ColorResource.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Reviews list or empty state
            if (reviews.isEmpty)
              _buildEmptyState()
            else
              ...reviews.map((review) {
                final isCurrentUser = currentUserId != null &&
                    review.userId == currentUserId;

                return ReviewCard(
                  review: review,
                  isCurrentUser: isCurrentUser,
                  onHelpful: () => controller.markReviewHelpful(
                    review.id,
                    productId,
                  ),
                  onDelete: isCurrentUser
                      ? () => controller.deleteReview(review.id, productId)
                      : null,
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildRatingSummary(double rating, int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorResource.scaffoldBackground,
        borderRadius: BorderRadius.circular(Constants.radiusDefault),
      ),
      child: Row(
        children: [
          // Large rating
          Column(
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: poppinsBold.copyWith(
                  fontSize: 48,
                  color: ColorResource.textPrimary,
                ),
              ),
              RatingStars(
                rating: rating,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                '$count reviews',
                style: poppinsRegular.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: ColorResource.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: ColorResource.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeLarge,
                color: ColorResource.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to review this product!',
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: ColorResource.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
