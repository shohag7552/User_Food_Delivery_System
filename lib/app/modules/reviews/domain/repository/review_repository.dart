import 'dart:developer';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/models/review_model.dart';
import 'package:appwrite_user_app/app/modules/reviews/domain/repository/review_repo_interface.dart';

class ReviewRepository implements ReviewRepoInterface {
  final AppwriteService appwriteService;
  static const int _reviewBatchSize = 100;

  ReviewRepository({required this.appwriteService});

  @override
  Future<List<ReviewModel>> getProductReviews(String productId) async {
    try {
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.reviewsCollection,
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
        tableId: AppwriteConfig.reviewsCollection,
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
        collectionId: AppwriteConfig.reviewsCollection,
        data: review.toJson(),
      );

      final createdReview = ReviewModel.fromJson(response.data);
      await _syncProductRatingSummary(review.productId);
      return createdReview;
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
        tableId: AppwriteConfig.reviewsCollection,
        rowId: reviewId,
        data: data,
      );

      final updatedReview = ReviewModel.fromJson(response.data);
      await _syncProductRatingSummary(updatedReview.productId);
      return updatedReview;
    } catch (e) {
      log('Error updating review: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    try {
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.reviewsCollection,
        queries: [
          Query.equal('\$id', reviewId),
          Query.limit(1),
        ],
      );
      final productId = response.rows.isNotEmpty
          ? (response.rows.first.data['product_id'] ?? '').toString()
          : '';

      await appwriteService.deleteRow(
        collectionId: AppwriteConfig.reviewsCollection,
        rowId: reviewId,
      );

      if (productId.isNotEmpty) {
        await _syncProductRatingSummary(productId);
      }
    } catch (e) {
      log('Error deleting review: $e');
      rethrow;
    }
  }

  @override
  Future<ReviewModel> toggleHelpful(String reviewId, String userId) async {
    try {
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.reviewsCollection,
        queries: [
          Query.equal('\$id', reviewId),
          Query.limit(1),
        ],
      );

      if (response.rows.isEmpty) {
        throw Exception('Review not found');
      }

      final reviewData = response.rows.first.data;
      final helpfulUserIds = (reviewData['helpful_user_ids'] is List)
          ? List<String>.from(
              (reviewData['helpful_user_ids'] as List).map((e) => e.toString()),
            )
          : <String>[];

      // Toggle this user's membership.
      if (helpfulUserIds.contains(userId)) {
        helpfulUserIds.remove(userId);
      } else {
        helpfulUserIds.add(userId);
      }

      // Keep the count derived from the list so they never drift apart.
      final updated = await appwriteService.updateTable(
        tableId: AppwriteConfig.reviewsCollection,
        rowId: reviewId,
        data: {
          'helpful_user_ids': helpfulUserIds,
          'helpful_count': helpfulUserIds.length,
        },
      );

      return ReviewModel.fromJson(updated.data);
    } catch (e) {
      log('Error toggling review helpful: $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasUserReviewedProduct(
    String userId,
    String productId, {
    String? orderId,
  }) async {
    try {
      final review = await getUserProductReview(
        userId,
        productId,
        orderId: orderId,
      );
      return review != null;
    } catch (e) {
      log('Error checking if user reviewed product: $e');
      return false;
    }
  }

  @override
  Future<ReviewModel?> getUserProductReview(
    String userId,
    String productId, {
    String? orderId,
  }) async {
    try {
      final queries = <String>[
        Query.equal('user_id', userId),
        Query.equal('product_id', productId),
        Query.orderDesc('\$createdAt'),
        Query.limit(1),
      ];

      if (orderId != null && orderId.isNotEmpty) {
        queries.insert(2, Query.equal('order_id', orderId));
      }

      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.reviewsCollection,
        queries: queries,
      );

      if (response.rows.isEmpty) {
        return null;
      }

      return ReviewModel.fromJson(response.rows.first.data);
    } catch (e) {
      log('Error fetching user product review: $e');
      return null;
    }
  }

  @override
  Future<double> getProductAverageRating(String productId) async {
    try {
      final reviews = await _getAllProductReviews(productId);
      
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

  Future<List<ReviewModel>> _getAllProductReviews(String productId) async {
    final List<ReviewModel> reviews = [];
    int offset = 0;

    while (true) {
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.reviewsCollection,
        queries: [
          Query.equal('product_id', productId),
          Query.orderDesc('\$createdAt'),
          Query.offset(offset),
          Query.limit(_reviewBatchSize),
        ],
      );

      if (response.rows.isEmpty) {
        break;
      }

      reviews.addAll(
        response.rows.map((row) => ReviewModel.fromJson(row.data)),
      );

      if (response.rows.length < _reviewBatchSize) {
        break;
      }

      offset += _reviewBatchSize;
    }

    return reviews;
  }

  Future<void> _syncProductRatingSummary(String productId) async {
    final reviews = await _getAllProductReviews(productId);
    final ratingCount = reviews.length;
    final avgRating = ratingCount == 0
        ? 0.0
        : reviews.fold<int>(0, (sum, review) => sum + review.rating) /
            ratingCount;

    await appwriteService.updateTable(
      tableId: AppwriteConfig.productsCollection,
      rowId: productId,
      data: {
        'rating_count': ratingCount,
        'avg_rating': avgRating,
      },
    );
  }
}
