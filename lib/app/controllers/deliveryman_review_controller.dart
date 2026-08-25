import 'dart:async';
import 'dart:developer';

import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/models/deliveryman_review_model.dart';
import 'package:appwrite_user_app/app/models/order_model.dart';
import 'package:appwrite_user_app/app/modules/reviews/domain/repository/deliveryman_review_repo_interface.dart';
import 'package:get/get.dart';

/// Owns everything about rating the person who delivered an order: who is
/// allowed to rate, what has already been rated, and the driver's public score.
///
/// The eligibility rules live here rather than in the order screen so every
/// entry point (order detail, order list, a future post-delivery prompt) agrees
/// on when the prompt may appear.
class DeliverymanReviewController extends GetxController
    implements GetxService {
  final DeliverymanReviewRepoInterface deliverymanReviewRepoInterface;

  DeliverymanReviewController({required this.deliverymanReviewRepoInterface});

  /// How long after an order is placed a delivery can still be rated. Feedback
  /// arriving months later says nothing useful about the driver, and an
  /// indefinite prompt keeps nagging on orders the customer has moved on from.
  static const Duration reviewWindow = Duration(days: 30);

  /// The chips offered under the stars. Which set appears depends on the score:
  /// asking a happy customer whether the driver was rude, or an unhappy one
  /// whether they were polite, reads as tone-deaf.
  static const List<String> positiveTags = [
    'on_time_delivery',
    'polite_behaviour',
    'careful_handling',
    'good_communication',
  ];

  static const List<String> negativeTags = [
    'late_delivery',
    'rude_behaviour',
    'items_damaged',
    'hard_to_reach',
  ];

  // ── State, keyed by order id ────────────────────────────────────────────
  final Map<String, DeliverymanReviewModel?> _orderReviews = {};
  final Map<String, bool> _loadingStates = {};
  final Map<String, bool> _loadedStates = {};

  // Driver rating summaries, keyed by driver id.
  final Map<String, ({double average, int count})> _driverSummaries = {};

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  DeliverymanReviewModel? getOrderReview(String orderId) =>
      _orderReviews[orderId];

  bool isOrderReviewLoading(String orderId) => _loadingStates[orderId] ?? false;

  bool hasOrderReviewLoaded(String orderId) => _loadedStates[orderId] ?? false;

  ({double average, int count})? getDriverSummary(String driverId) =>
      _driverSummaries[driverId];

  /// Chips to offer for a given score. Empty until a star is picked, so the
  /// sheet does not present choices before there is anything to qualify.
  List<String> tagsForRating(int rating) {
    if (rating <= 0) return const [];
    return rating >= 4 ? positiveTags : negativeTags;
  }

  // ── Eligibility ─────────────────────────────────────────────────────────

  bool isOrderDelivered(OrderModel order) {
    final status = order.status.toLowerCase();
    return status == 'delivered' || status == 'completed';
  }

  /// The driver this order should be rated against — the order's own
  /// `driver_id` when present, otherwise the joined deliveryman row.
  ///
  /// The fallback is guarded: [DeliverymanInfo.fromOrderJson] can end up
  /// reading the *order's* `$id` when the driver's details are flattened onto
  /// the order row, and a review filed against an order id would credit a
  /// driver that does not exist.
  String? resolveDriverId(OrderModel order) {
    if (order.driverId != null && order.driverId!.isNotEmpty) {
      return order.driverId;
    }
    final nestedId = order.deliveryman?.id;
    if (nestedId != null && nestedId.isNotEmpty && nestedId != order.id) {
      return nestedId;
    }
    return null;
  }

  /// A counter sale is handed over face to face — there is no deliveryman to
  /// rate, so the prompt must not appear on it.
  bool isPosOrder(OrderModel order) {
    return order.orderSource?.toLowerCase() == 'pos' ||
        order.orderNumber.toUpperCase().contains('POS') ||
        order.paymentMethod.toLowerCase() == 'pos';
  }

  /// Shipped by a third-party courier rather than one of the store's drivers.
  /// There is a tracking number instead of a person, and nobody to score.
  bool isCourierShipment(OrderModel order) {
    return (order.courierName?.trim().isNotEmpty ?? false) ||
        (order.trackingNumber?.trim().isNotEmpty ?? false);
  }

  bool isReviewWindowOpen(OrderModel order) {
    return DateTime.now().difference(order.createdAt) <= reviewWindow;
  }

  /// Whether a delivery rating belongs on this order at all — a real driver
  /// handed a real delivery over. Says nothing about the rating window, so a
  /// rating already given stays visible for as long as the order does.
  bool canShowDeliveryRating(OrderModel order) {
    return isOrderDelivered(order) &&
        resolveDriverId(order) != null &&
        !isPosOrder(order) &&
        !isCourierShipment(order);
  }

  /// Whether the customer may still write or change a rating — the above, plus
  /// the window still being open.
  bool canReviewDelivery(OrderModel order) {
    return canShowDeliveryRating(order) && isReviewWindowOpen(order);
  }

  // ── Loading ─────────────────────────────────────────────────────────────

  /// Loads this customer's existing rating for one delivery, plus the driver's
  /// public score. Safe to call on every build: it returns immediately once the
  /// order has been resolved, so the CTA never flickers between states.
  Future<void> loadOrderReview(
    OrderModel order,
    String userId, {
    bool forceRefresh = false,
  }) async {
    if (!canShowDeliveryRating(order)) return;

    final driverId = resolveDriverId(order);
    if (driverId != null) {
      // Decoration on the card — the review state must not wait on it.
      // `fetchDriverSummary` swallows its own failures.
      unawaited(fetchDriverSummary(driverId));
    }

    if (!forceRefresh &&
        (_loadedStates[order.id] == true || _loadingStates[order.id] == true)) {
      return;
    }

    _loadingStates[order.id] = true;
    update();

    try {
      _orderReviews[order.id] = await deliverymanReviewRepoInterface
          .getOrderReview(order.id, userId);
      _loadedStates[order.id] = true;
    } catch (e) {
      log('Error loading deliveryman review: $e');
    } finally {
      _loadingStates[order.id] = false;
      update();
    }
  }

  /// The driver's average and review count, for the badge on the driver card.
  Future<void> fetchDriverSummary(
    String driverId, {
    bool forceRefresh = false,
  }) async {
    if (driverId.isEmpty) return;
    if (!forceRefresh && _driverSummaries.containsKey(driverId)) return;

    try {
      final summary = await deliverymanReviewRepoInterface
          .getDriverRatingSummary(driverId);
      _driverSummaries[driverId] = summary;
      update();
    } catch (e) {
      log('Error loading driver rating summary: $e');
    }
  }

  // ── Writing ─────────────────────────────────────────────────────────────

  /// Creates the rating, or edits the one already on this order.
  ///
  /// Returns true only when the row was written — the caller closes the sheet
  /// on that, so a failed submit leaves the customer's text where they typed it
  /// rather than discarding it.
  Future<bool> submitReview({
    required OrderModel order,
    required String userId,
    required String userName,
    required int rating,
    String? comment,
    List<String> tags = const [],
  }) async {
    if (rating < 1 || rating > 5) {
      customToster('please_select_a_rating'.tr, isSuccess: false);
      return false;
    }

    final driverId = resolveDriverId(order);
    if (driverId == null) {
      customToster('delivery_rating_not_available'.tr, isSuccess: false);
      return false;
    }

    _isSubmitting = true;
    update();

    try {
      final trimmedComment = comment?.trim();
      final existing = _orderReviews[order.id];

      final DeliverymanReviewModel saved;
      if (existing != null) {
        saved = await deliverymanReviewRepoInterface.updateReview(existing.id, {
          'rating': rating,
          'comment': (trimmedComment?.isEmpty ?? true) ? null : trimmedComment,
          'tags': tags,
        });
      } else {
        saved = await deliverymanReviewRepoInterface.submitReview(
          DeliverymanReviewModel(
            id: '',
            driverId: driverId,
            driverName: order.deliveryman?.name ?? '',
            orderId: order.id,
            orderNumber: order.orderNumber,
            userId: userId,
            userName: userName,
            rating: rating,
            comment:
                (trimmedComment?.isEmpty ?? true) ? null : trimmedComment,
            tags: tags,
            createdAt: DateTime.now(),
          ),
        );
      }

      _orderReviews[order.id] = saved;
      _loadedStates[order.id] = true;
      // The average just moved; pull the authoritative value back rather than
      // recomputing it locally and risking a disagreement with the server.
      await fetchDriverSummary(driverId, forceRefresh: true);

      customToster(
        existing != null
            ? 'delivery_rating_updated'.tr
            : 'thanks_for_rating_your_delivery'.tr,
        isSuccess: true,
      );
      return true;
    } catch (e) {
      log('Error submitting deliveryman review: $e');
      customToster('failed_to_submit_delivery_rating'.tr, isSuccess: false);
      return false;
    } finally {
      _isSubmitting = false;
      update();
    }
  }

  /// Drops cached state for one order so the next open re-reads it.
  void clearOrder(String orderId) {
    _orderReviews.remove(orderId);
    _loadedStates.remove(orderId);
    _loadingStates.remove(orderId);
    update();
  }
}
