import 'dart:developer';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/models/review_model.dart';
import 'package:appwrite_user_app/app/modules/reviews/domain/repository/review_repo_interface.dart';
import 'package:get/get.dart';

class ReviewController extends GetxController implements GetxService {
  final ReviewRepoInterface reviewRepoInterface;

  ReviewController({required this.reviewRepoInterface});

  // Reviews by product ID
  final Map<String, List<ReviewModel>> _productReviews = {};
  final Map<String, double> _productRatings = {};
  final Map<String, bool> _loadingStates = {};

  bool isLoading(String productId) => _loadingStates[productId] ?? false;
  List<ReviewModel> getProductReviews(String productId) =>
      _productReviews[productId] ?? [];
  double getProductRating(String productId) => _productRatings[productId] ?? 0.0;
  int getReviewCount(String productId) =>
      _productReviews[productId]?.length ?? 0;

  /// Fetch reviews for a product
  Future<void> fetchProductReviews(String productId,
      {bool forceRefresh = false}) async {
    // Return cached if available and not forcing refresh
    if (!forceRefresh && _productReviews.containsKey(productId)) {
      return;
    }

    try {
      _loadingStates[productId] = true;
      update();

      final reviews = await reviewRepoInterface.getProductReviews(productId);
      _productReviews[productId] = reviews;

      // Calculate average rating
      if (reviews.isNotEmpty) {
        final totalRating = reviews.fold<int>(
          0,
          (sum, review) => sum + review.rating,
        );
        _productRatings[productId] = totalRating / reviews.length;
      } else {
        _productRatings[productId] = 0.0;
      }

      _loadingStates[productId] = false;
      update();
    } catch (e) {
      _loadingStates[productId] = false;
      update();
      log('Error fetching reviews: $e');
    }
  }

  /// Submit a new review
  Future<bool> submitReview({
    required String productId,
    required String userId,
    required String userName,
    required int rating,
    String? title,
    required String comment,
    bool verifiedPurchase = false,
  }) async {
    try {
      // Check if user already reviewed
      final hasReviewed =
          await reviewRepoInterface.hasUserReviewedProduct(userId, productId);

      if (hasReviewed) {
        customToster('You have already reviewed this product',
            isSuccess: false);
        return false;
      }

      final review = ReviewModel(
        id: '',
        productId: productId,
        userId: userId,
        userName: userName,
        rating: rating,
        title: title,
        comment: comment,
        verifiedPurchase: verifiedPurchase,
        createdAt: DateTime.now(),
      );

      await reviewRepoInterface.submitReview(review);

      // Refresh reviews
      await fetchProductReviews(productId, forceRefresh: true);

      customToster('Review submitted successfully!', isSuccess: true);
      return true;
    } catch (e) {
      log('Error submitting review: $e');
      customToster('Failed to submit review', isSuccess: false);
      return false;
    }
  }

  /// Mark review as helpful
  Future<void> markReviewHelpful(String reviewId, String productId) async {
    try {
      await reviewRepoInterface.markHelpful(reviewId);

      // Update local cache
      final reviews = _productReviews[productId];
      if (reviews != null) {
        final index = reviews.indexWhere((r) => r.id == reviewId);
        if (index != -1) {
          reviews[index] = reviews[index].copyWith(
            helpfulCount: reviews[index].helpfulCount + 1,
          );
          update();
        }
      }

      customToster('Marked as helpful', isSuccess: true);
    } catch (e) {
      log('Error marking review as helpful: $e');
      customToster('Failed to mark as helpful', isSuccess: false);
    }
  }

  /// Delete a review
  Future<void> deleteReview(String reviewId, String productId) async {
    try {
      await reviewRepoInterface.deleteReview(reviewId);

      // Refresh reviews
      await fetchProductReviews(productId, forceRefresh: true);

      customToster('Review deleted', isSuccess: true);
    } catch (e) {
      log('Error deleting review: $e');
      customToster('Failed to delete review', isSuccess: false);
    }
  }

  /// Check if user has reviewed a product
  Future<bool> hasUserReviewedProduct(String userId, String productId) async {
    try {
      return await reviewRepoInterface.hasUserReviewedProduct(
          userId, productId);
    } catch (e) {
      log('Error checking review status: $e');
      return false;
    }
  }
}
