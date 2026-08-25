import 'package:appwrite_user_app/app/models/deliveryman_review_model.dart';

abstract class DeliverymanReviewRepoInterface {
  /// The review this customer left for one delivery, or null if they have not
  /// rated it yet.
  Future<DeliverymanReviewModel?> getOrderReview(String orderId, String userId);

  /// Create the review and refresh the driver's rating summary.
  Future<DeliverymanReviewModel> submitReview(DeliverymanReviewModel review);

  /// Edit an existing review (rating / comment / tags) and re-sync the summary.
  Future<DeliverymanReviewModel> updateReview(
    String reviewId,
    Map<String, dynamic> data,
  );

  /// Reviews a driver has received, newest first.
  Future<List<DeliverymanReviewModel>> getDriverReviews(
    String driverId, {
    int limit,
  });

  /// The driver's live rating summary — `(average, count)`.
  Future<({double average, int count})> getDriverRatingSummary(String driverId);
}
