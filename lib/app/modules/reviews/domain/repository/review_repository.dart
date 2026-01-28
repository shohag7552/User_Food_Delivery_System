import 'dart:developer';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/models/review_model.dart';
import 'package:appwrite_user_app/app/modules/reviews/domain/repository/review_repo_interface.dart';

class ReviewRepository implements ReviewRepoInterface {
  final AppwriteService appwriteService;

  ReviewRepository({required this.appwriteService});


  @override
  Future<List<ReviewModel>> getProductReviews(String productId) async {
    try {
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.collectionId,
        queries: [
          Query.equal('product_id', productId),
          Query.orderDesc('\$createdAt'),
          Query.limit(100),
        ],
      );

      return response.rows
          .map((row) => ReviewModel.fromJson(row.data))
          .toList();
    } catch (e) {
      log('Error fetching product reviews: $e');
      rethrow;
    }
  }

  @override
  Future<List<ReviewModel>> getUserReviews(String userId) async {
    try {
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.collectionId,
        queries: [
          Query.equal('user_id', userId),
          Query.orderDesc('\$createdAt'),
        ],
      );

      return response.rows
          .map((row) => ReviewModel.fromJson(row.data))
          .toList();
    } catch (e) {
      log('Error fetching user reviews: $e');
      rethrow;
    }
  }

  @override
  Future<ReviewModel> submitReview(ReviewModel review) async {
    try {
      final response = await appwriteService.createRow(
        collectionId: AppwriteConfig.collectionId,
        data: review.toJson(),
      );

      return ReviewModel.fromJson(response.data);
    } catch (e) {
      log('Error submitting review: $e');
      rethrow;
    }
  }

  @override
  Future<ReviewModel> updateReview(
      String reviewId, Map<String, dynamic> data) async {
    try {
      final response = await appwriteService.updateTable(
        tableId: AppwriteConfig.collectionId,
        rowId: reviewId,
        data: data,
      );

      return ReviewModel.fromJson(response.data);
    } catch (e) {
      log('Error updating review: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    try {
      await appwriteService.deleteRow(
        collectionId: AppwriteConfig.collectionId,
        rowId: reviewId,
      );
    } catch (e) {
      log('Error deleting review: $e');
      rethrow;
    }
  }

  @override
  Future<void> markHelpful(String reviewId) async {
    try {
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.collectionId,
        queries: [
          Query.equal('\$id', reviewId),
          Query.limit(1),
        ],
      );

      if (response.rows.isEmpty) {
        throw Exception('Review not found');
      }

      final reviewData = response.rows.first.data;
      final currentCount = reviewData['helpful_count'] ?? 0;

      // Increment helpful count
      await appwriteService.updateTable(
        tableId: AppwriteConfig.collectionId,
        rowId: reviewId,
        data: {'helpful_count': currentCount + 1},
      );
    } catch (e) {
      log('Error marking review as helpful: $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasUserReviewedProduct(String userId, String productId) async {
    try {
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.collectionId,
        queries: [
          Query.equal('user_id', userId),
          Query.equal('product_id', productId),
          Query.limit(1),
        ],
      );

      return response.rows.isNotEmpty;
    } catch (e) {
      log('Error checking if user reviewed product: $e');
      return false;
    }
  }

  @override
  Future<double> getProductAverageRating(String productId) async {
    try {
      final reviews = await getProductReviews(productId);
      
      if (reviews.isEmpty) return 0.0;

      final totalRating = reviews.fold<int>(
        0,
        (sum, review) => sum + review.rating,
      );

      return totalRating / reviews.length;
    } catch (e) {
      log('Error calculating average rating: $e');
      return 0.0;
    }
  }
}
