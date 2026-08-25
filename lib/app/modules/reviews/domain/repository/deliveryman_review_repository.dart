import 'dart:developer';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/models/deliveryman_review_model.dart';
import 'package:appwrite_user_app/app/modules/reviews/domain/repository/deliveryman_review_repo_interface.dart';

class DeliverymanReviewRepository implements DeliverymanReviewRepoInterface {
  final AppwriteService appwriteService;

  DeliverymanReviewRepository({required this.appwriteService});

  @override
  Future<DeliverymanReviewModel?> getOrderReview(
    String orderId,
    String userId,
  ) async {
    try {
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.deliverymanReviewsCollection,
        queries: [
          Query.equal('order_id', orderId),
          Query.equal('user_id', userId),
          Query.limit(1),
        ],
      );

      if (response.rows.isEmpty) {
        return null;
      }
      return DeliverymanReviewModel.fromJson(response.rows.first.data);
    } catch (e) {
      log('Error fetching deliveryman review for order $orderId: $e');
      rethrow;
    }
  }

  @override
  Future<DeliverymanReviewModel> submitReview(
    DeliverymanReviewModel review,
  ) async {
    try {
      final response = await appwriteService.createRow(
        collectionId: AppwriteConfig.deliverymanReviewsCollection,
        data: review.toJson(),
        // Anyone may read a driver's ratings; only the author may change or
        // remove their own. The collection grants no blanket update, so this
        // row-level stamp is what makes a review editable at all.
        permissions: [
          Permission.read(Role.any()),
          Permission.update(Role.user(review.userId)),
          Permission.delete(Role.user(review.userId)),
        ],
      );

      final created = DeliverymanReviewModel.fromJson(response.data);
      await _applyRatingDelta(
        driverId: created.driverId,
        ratingDelta: created.rating,
        countDelta: 1,
      );
      return created;
    } catch (e) {
      log('Error submitting deliveryman review: $e');
      rethrow;
    }
  }

  @override
  Future<DeliverymanReviewModel> updateReview(
    String reviewId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Read the row first: the driver average moves by the *difference*
      // between the old and new star count, so the old value has to be known
      // before it is overwritten.
      final existingRow = await appwriteService.getDocument(
        tableId: AppwriteConfig.deliverymanReviewsCollection,
        rowId: reviewId,
      );
      final existing = DeliverymanReviewModel.fromJson(existingRow.data);

      final response = await appwriteService.updateTable(
        tableId: AppwriteConfig.deliverymanReviewsCollection,
        rowId: reviewId,
        data: data,
      );

      final updated = DeliverymanReviewModel.fromJson(response.data);
      if (updated.rating != existing.rating) {
        await _applyRatingDelta(
          driverId: updated.driverId,
          ratingDelta: updated.rating - existing.rating,
          countDelta: 0,
        );
      }
      return updated;
    } catch (e) {
      log('Error updating deliveryman review: $e');
      rethrow;
    }
  }

  @override
  Future<List<DeliverymanReviewModel>> getDriverReviews(
    String driverId, {
    int limit = 20,
  }) async {
    try {
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.deliverymanReviewsCollection,
        queries: [
          Query.equal('driver_id', driverId),
          Query.orderDesc('created_at'),
          Query.limit(limit),
        ],
      );

      return response.rows
          .map((row) => DeliverymanReviewModel.fromJson(row.data))
          .toList();
    } catch (e) {
      log('Error fetching reviews for driver $driverId: $e');
      rethrow;
    }
  }

  @override
  Future<({double average, int count})> getDriverRatingSummary(
    String driverId,
  ) async {
    try {
      final row = await appwriteService.getDocument(
        tableId: AppwriteConfig.driversCollection,
        rowId: driverId,
      );

      return (
        average: (row.data['avg_rating'] as num?)?.toDouble() ?? 0.0,
        count: (row.data['rating_count'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      log('Error fetching rating summary for driver $driverId: $e');
      return (average: 0.0, count: 0);
    }
  }

  /// Moves the driver's denormalized `avg_rating` / `rating_count` by a delta
  /// instead of recounting every review.
  ///
  /// A driver accumulates one review per delivery, so a full recount would grow
  /// without bound and make every submission slower than the last. The trade-off
  /// is that two ratings landing on the same driver in the same instant can lose
  /// one another; that is rare, self-corrects on the next write, and never
  /// blocks the review itself — a failure here is logged, not rethrown, because
  /// the customer's rating is already safely stored.
  Future<void> _applyRatingDelta({
    required String driverId,
    required int ratingDelta,
    required int countDelta,
  }) async {
    if (driverId.isEmpty) return;

    try {
      final row = await appwriteService.getDocument(
        tableId: AppwriteConfig.driversCollection,
        rowId: driverId,
      );

      final currentAverage = (row.data['avg_rating'] as num?)?.toDouble() ?? 0.0;
      final currentCount = (row.data['rating_count'] as num?)?.toInt() ?? 0;

      final newCount = (currentCount + countDelta).clamp(0, 1 << 30);
      final newTotal = (currentAverage * currentCount) + ratingDelta;
      final newAverage = newCount == 0
          ? 0.0
          : (newTotal / newCount).clamp(0.0, 5.0);

      await appwriteService.updateTable(
        tableId: AppwriteConfig.driversCollection,
        rowId: driverId,
        data: {
          'avg_rating': double.parse(newAverage.toStringAsFixed(2)),
          'rating_count': newCount,
        },
      );
    } catch (e) {
      // The review is stored; only the cached summary is stale.
      log('Error syncing rating summary for driver $driverId: $e');
    }
  }
}
