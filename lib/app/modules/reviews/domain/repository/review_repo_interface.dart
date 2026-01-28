import 'package:appwrite_user_app/app/models/review_model.dart';

abstract class ReviewRepoInterface {
  /// Get all reviews for a specific product
  Future<List<ReviewModel>> getProductReviews(String productId);

  /// Get all reviews by a specific user
  Future<List<ReviewModel>> getUserReviews(String userId);

  /// Submit a new review
  Future<ReviewModel> submitReview(ReviewModel review);

  /// Update an existing review
  Future<ReviewModel> updateReview(String reviewId, Map<String, dynamic> data);

  /// Delete a review
  Future<void> deleteReview(String reviewId);

  /// Mark a review as helpful
  Future<void> markHelpful(String reviewId);

  /// Check if user has reviewed a product
  Future<bool> hasUserReviewedProduct(String userId, String productId);

  /// Get average rating for a product
  Future<double> getProductAverageRating(String productId);
}
