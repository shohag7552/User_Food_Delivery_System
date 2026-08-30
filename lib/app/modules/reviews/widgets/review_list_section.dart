import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/common/widgets/rating_stars.dart';
import 'package:appwrite_user_app/app/controllers/review_controller.dart';
import 'package:appwrite_user_app/app/models/review_model.dart';
import 'package:appwrite_user_app/app/modules/reviews/widgets/review_card.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReviewListSection extends StatefulWidget {
  final String productId;
  final String? currentUserId;

  /// How many reviews are shown before the "show all" button appears.
  ///
  /// A product detail page is about the product; an unbounded review list buries
  /// everything under it — the suggested carousel included — under however many
  /// reviews the product happens to have collected.
  final int collapsedCount;

  const ReviewListSection({
    super.key,
    required this.productId,
    this.currentUserId,
    this.collapsedCount = 5,
  });

  @override
  State<ReviewListSection> createState() => _ReviewListSectionState();
}

class _ReviewListSectionState extends State<ReviewListSection> {
  /// Collapsed until the reader asks for the rest. Deliberately not reset when
  /// a review is added or deleted — someone who expanded the list should stay
  /// expanded.
  bool _isExpanded = false;

  String get productId => widget.productId;
  String? get currentUserId => widget.currentUserId;

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
                  'reviews_count'.trParams({'count': '$reviewCount'}),
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeLarge,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Reviews list or empty state
            if (reviews.isEmpty)
              _buildEmptyState()
            else ...[
              ..._visible(reviews).map((review) {
                final isCurrentUser =
                    currentUserId != null && review.userId == currentUserId;

                return ReviewCard(
                  review: review,
                  isCurrentUser: isCurrentUser,
                  isMarkedHelpful: review.isMarkedHelpfulBy(currentUserId),
                  onHelpful: () {
                    if (currentUserId == null) {
                      customToster(
                        'please_login_to_mark_helpful'.tr,
                        isSuccess: false,
                      );
                      return;
                    }
                    controller.toggleReviewHelpful(
                      review.id,
                      productId,
                      currentUserId!,
                    );
                  },
                  onDelete: isCurrentUser
                      ? () => controller.deleteReview(review.id, productId)
                      : null,
                );
              }),
              _buildToggle(context, reviews.length),
            ],
          ],
        );
      },
    );
  }

  /// The slice currently on screen.
  List<ReviewModel> _visible(List<ReviewModel> reviews) => _isExpanded
      ? reviews
      : reviews.take(widget.collapsedCount).toList();

  /// "Show all N reviews" / "See less", or nothing when the list already fits.
  ///
  /// A text button rather than a filled one: this expands a list in place, it
  /// does not navigate or commit anything, and it should not compete with the
  /// page's real actions.
  Widget _buildToggle(BuildContext context, int total) {
    if (total <= widget.collapsedCount) return const SizedBox.shrink();

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: () => setState(() => _isExpanded = !_isExpanded),
        style: TextButton.styleFrom(
          foregroundColor: ColorResource.primaryDark,
          padding: const EdgeInsets.symmetric(
            horizontal: Constants.paddingSizeSmall,
            vertical: Constants.paddingSizeSmall,
          ),
          minimumSize: const Size(0, Constants.minTapTarget),
        ),
        icon: Icon(
          _isExpanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          size: 20,
        ),
        // Counting the total rather than the remainder: "Show all 23 reviews"
        // tells the reader how much there is, which is what decides whether
        // they want it.
        label: Text(
          _isExpanded
              ? 'see_less'.tr
              : 'show_all_reviews'.trParams({'count': '$total'}),
          style: poppinsMedium.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: ColorResource.primaryDark,
          ),
        ),
      ),
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
              RatingStars(rating: rating, size: 20),
              const SizedBox(height: 4),
              Text(
                'count_reviews'.trParams({'count': '$count'}),
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
              'no_reviews_yet'.tr,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeLarge,
                color: ColorResource.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'be_the_first_to_review'.tr,
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
