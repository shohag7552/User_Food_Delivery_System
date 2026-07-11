import 'package:appwrite_user_app/app/models/coupon_model.dart';

abstract class CouponRepoInterface {
  /// Fetch all coupons
  Future<List<CouponModel>> getCoupons();

  /// Get coupon by code for validation
  Future<CouponModel?> getCouponByCode(String code);

  /// Fetch a single coupon by its document id (deep-link hydration)
  Future<CouponModel?> getCouponById(String id);

  /// Add new coupon
  Future<bool> addCoupon(CouponModel coupon);

  /// Update existing coupon
  Future<CouponModel?> updateCoupon(String id, CouponModel coupon);

  /// Delete coupon
  Future<bool> deleteCoupon(String id);

  /// Increment usage count when coupon is used
  Future<bool> incrementUsageCount(String id);
}
