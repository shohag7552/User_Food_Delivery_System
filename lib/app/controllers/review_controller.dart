import 'dart:developer';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
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
  final Map<String, ReviewModel?> _userProductReviews = {};
  final Map<String, bool> _userProductReviewLoadingStates = {};
  final Map<String, bool> _userProductReviewLoadedStates = {};

  bool isLoading(String productId) => _loadingStates[productId] ?? false;
  List<ReviewModel> getProductReviews(String productId) =>
      _productReviews[productId] ?? [];
  double getProductRating(String productId) => _productRatings[productId] ?? 0.0;
  int getReviewCount(String productId) =>
      _productReviews[productId]?.length ?? 0;
  bool isUserProductReviewLoading(
    String userId,
    String productId, {
    String? orderId,
  }) =>
      _userProductReviewLoadingStates[
        _userProductKey(userId, productId, orderId: orderId)
      ] ??
      false;
  bool hasUserProductReviewLoaded(
    String userId,
    String productId, {
    String? orderId,
  }) =>
      _userProductReviewLoadedStates[
        _userProductKey(userId, productId, orderId: orderId)
      ] ??
      false;
  ReviewModel? getCachedUserProductReview(
    String userId,
    String productId, {
    String? orderId,
  }) => _userProductReviews[
    _userProductKey(userId, productId, orderId: orderId)
  ];

  String _userProductKey(
    String userId,
    String productId, {
    String? orderId,
  }) => '$userId::$productId::${orderId ?? ''}';

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
    String? orderId,
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
      final hasReviewed = await reviewRepoInterface.hasUserReviewedProduct(
        userId,
        productId,
        orderId: orderId,
      );

      if (hasReviewed) {
        customToster('You have already reviewed this product', isSuccess: false);
        return false;
      }

      final review = ReviewModel(
        id: '',
        orderId: orderId,
        productId: productId,
        userId: userId,
        userName: userName,
        rating: rating,
        title: title,
        comment: comment,
        verifiedPurchase: verifiedPurchase,
        createdAt: DateTime.now(),
      );

      final createdReview = await reviewRepoInterface.submitReview(review);
      final reviewKey = _userProductKey(
        userId,
        productId,
        orderId: orderId,
      );
      _userProductReviews[reviewKey] = createdReview;
      _userProductReviewLoadedStates[reviewKey] = true;
      _userProductReviewLoadingStates[reviewKey] = false;

      // Refresh reviews
      await fetchProductReviews(productId, forceRefresh: true);
      _syncProductRatingSummaryInCache(productId);

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
      _userProductReviews.removeWhere(
        (_, review) => review?.id == reviewId,
      );
      _syncProductRatingSummaryInCache(productId);

      customToster('Review deleted', isSuccess: true);
    } catch (e) {
      log('Error deleting review: $e');
      customToster('Failed to delete review', isSuccess: false);
    }
  }

  /// Check if user has reviewed a product
  Future<bool> hasUserReviewedProduct(
    String userId,
    String productId, {
    String? orderId,
  }) async {
    try {
      return await reviewRepoInterface.hasUserReviewedProduct(
        userId,
        productId,
        orderId: orderId,
      );
    } catch (e) {
      log('Error checking review status: $e');
      return false;
    }
  }

  Future<ReviewModel?> fetchUserProductReview(
    String userId,
    String productId, {
    String? orderId,
    bool forceRefresh = false,
  }) async {
    final key = _userProductKey(userId, productId, orderId: orderId);
    if (!forceRefresh && _userProductReviewLoadedStates[key] == true) {
      return _userProductReviews[key];
    }

    try {
      _userProductReviewLoadingStates[key] = true;
      update();

      final review = await reviewRepoInterface.getUserProductReview(
        userId,
        productId,
        orderId: orderId,
      );
      _userProductReviews[key] = review;
      _userProductReviewLoadedStates[key] = true;
      return review;
    } catch (e) {
      log('Error fetching user product review: $e');
      return null;
    } finally {
      _userProductReviewLoadingStates[key] = false;
      update();
    }
  }

  void _syncProductRatingSummaryInCache(String productId) {
    if (!Get.isRegistered<ProductController>()) {
      return;
    }

    Get.find<ProductController>().updateProductRatingSummary(
      productId,
      avgRating: getProductRating(productId),
      ratingCount: getReviewCount(productId),
    );
  }
}
