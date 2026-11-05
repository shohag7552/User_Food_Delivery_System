import 'dart:developer';

import 'package:appwrite/appwrite.dart';
import 'package:kikomart_user_app/app/appwrite/appwrite_config.dart';
import 'package:kikomart_user_app/app/appwrite/appwrite_service.dart';
import 'package:kikomart_user_app/app/models/deliveryman_review_model.dart';
import 'package:kikomart_user_app/app/modules/reviews/domain/repository/deliveryman_review_repo_interface.dart';

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

      // The driver's avg_rating / rating_count are recounted by the backend
      // function's review event; customers cannot write the drivers row.
      return DeliverymanReviewModel.fromJson(response.data);
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
      final response = await appwriteService.updateTable(
        tableId: AppwriteConfig.deliverymanReviewsCollection,
        rowId: reviewId,
        data: data,
      );
      // The driver's summary follows from the review event on the server.
      return DeliverymanReviewModel.fromJson(response.data);
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
      // Through the backend: the drivers row holds every driver's earnings,
      // so customers only get this summary, for a driver on their own order.
      final driver = await appwriteService.callBackend('driver_summary', {
        'driver_id': driverId,
      });

      return (
        average: (driver['avg_rating'] as num?)?.toDouble() ?? 0.0,
        count: (driver['rating_count'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      log('Error fetching rating summary for driver $driverId: $e');
      return (average: 0.0, count: 0);
    }
  }
}
