import 'dart:developer';

import 'package:kikomart_user_app/app/common/widgets/custom_toster.dart';
import 'package:kikomart_user_app/app/models/coupon_model.dart';
import 'package:kikomart_user_app/app/modules/coupons/domain/repository/coupon_repo_interface.dart';
import 'package:get/get.dart';

class CouponController extends GetxController implements GetxService {
  final CouponRepoInterface couponRepoInterface;
  CouponController({required this.couponRepoInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<CouponModel>? _coupons;
  List<CouponModel>? get coupons => _coupons;

  /// Coupons the customer can actually use right now (active, inside their
  /// validity window, usage limit not reached) — the number the profile menu
  /// badge shows. Expired or exhausted coupons still appear in the list but
  /// are not counted.
  int get availableCouponCount =>
      _coupons?.where((c) => c.isValid()).length ?? 0;

  // Form state for adding/editing
  String _discountType = 'percentage';
  String get discountType => _discountType;

  bool _isActive = true;
  bool get isActive => _isActive;

  /// Fetch all coupons. [showError] is off for background loads (e.g. the
  /// profile badge) so a failed count doesn't toast on an unrelated screen.
  Future<void> getCoupons({bool showError = true}) async {
    try {
      _isLoading = true;
      // update();

      _coupons = await couponRepoInterface.getCoupons();

      _isLoading = false;
      update();
    } catch (e) {
      _isLoading = false;
      update();
      if (showError) {
        log('Error loading coupons: $e');
        customToster('failed_to_load_coupons'.tr, isSuccess: false);
      }
    }
  }

  /// Resolve a coupon by id — from the already-loaded list when possible,
  /// otherwise fetched from the backend (cold deep links). Null if not found.
  Future<CouponModel?> getCouponById(String id) async {
    for (final coupon in _coupons ?? const <CouponModel>[]) {
      if (coupon.id == id) return coupon;
    }
    return couponRepoInterface.getCouponById(id);
  }

  /// Validate coupon by code
  Future<CouponModel?> validateCouponCode(String code, {double? orderAmount}) async {
    try {
      final coupon = await couponRepoInterface.getCouponByCode(code);

      if (coupon == null) {
        customToster('coupon_not_found'.tr, isSuccess: false);
        return null;
      }

      if (!coupon.isValid(orderAmount: orderAmount)) {
        if (!coupon.isActive) {
          customToster('coupon_no_longer_active'.tr, isSuccess: false);
        } else if (DateTime.now().isBefore(coupon.validFrom)) {
          customToster('coupon_not_yet_valid'.tr, isSuccess: false);
        } else if (DateTime.now().isAfter(coupon.validUntil)) {
          customToster('coupon_has_expired'.tr, isSuccess: false);
        } else if (coupon.usageLimit != null && coupon.usedCount >= coupon.usageLimit!) {
          customToster('coupon_usage_limit_reached'.tr, isSuccess: false);
        } else if (coupon.minOrderAmount != null && orderAmount != null && orderAmount < coupon.minOrderAmount!) {
          customToster(
            'coupon_min_order_amount_required'.trParams({
              'amount': '\$${coupon.minOrderAmount!.toStringAsFixed(2)}',
            }),
            isSuccess: false,
          );
        } else {
          customToster('coupon_not_valid'.tr, isSuccess: false);
        }
        return null;
      }

      customToster('coupon_applied_successfully'.tr, isSuccess: true);
      return coupon;
    } catch (e) {
      log('Error validating coupon: $e');
      customToster('failed_to_validate_coupon'.tr, isSuccess: false);
      return null;
    }
  }

  /// Add new coupon
  Future<bool> addCoupon({
    required String code,
    required String description,
    required double discountValue,
    double? minOrderAmount,
    double? maxDiscount,
    int? usageLimit,
    required DateTime validFrom,
    required DateTime validUntil,
  }) async {
    try {
      _isLoading = true;
      update();

      final coupon = CouponModel(
        code: code.toUpperCase(),
        description: description,
        discountType: _discountType,
        discountValue: discountValue,
        minOrderAmount: minOrderAmount,
        maxDiscount: maxDiscount,
        usageLimit: usageLimit,
        validFrom: validFrom,
        validUntil: validUntil,
        isActive: _isActive,
      );

      bool success = await couponRepoInterface.addCoupon(coupon);

      if (success) {
        customToster('coupon_added_successfully'.tr, isSuccess: true);
        await getCoupons();
        resetForm();
      } else {
        customToster('failed_to_add_coupon'.tr, isSuccess: false);
      }

      _isLoading = false;
      update();

      return success;
    } catch (e) {
      _isLoading = false;
      update();
      log('Error adding coupon: $e');
      customToster('failed_to_add_coupon'.tr, isSuccess: false);
      return false;
    }
  }

  /// Update existing coupon
  Future<bool> updateCoupon({
    required String id,
    required String code,
    required String description,
    required double discountValue,
    double? minOrderAmount,
    double? maxDiscount,
    int? usageLimit,
    required DateTime validFrom,
    required DateTime validUntil,
    required int usedCount,
  }) async {
    try {
      _isLoading = true;
      update();

      final coupon = CouponModel(
        id: id,
        code: code.toUpperCase(),
        description: description,
        discountType: _discountType,
        discountValue: discountValue,
        minOrderAmount: minOrderAmount,
        maxDiscount: maxDiscount,
        usageLimit: usageLimit,
        usedCount: usedCount,
        validFrom: validFrom,
        validUntil: validUntil,
        isActive: _isActive,
      );

      final updatedCoupon = await couponRepoInterface.updateCoupon(id, coupon);

      if (updatedCoupon != null) {
        customToster('coupon_updated_successfully'.tr, isSuccess: true);

        // Update in local list
        final index = _coupons!.indexWhere((c) => c.id == id);
        if (index != -1) {
          _coupons![index] = updatedCoupon;
        }

        resetForm();
      } else {
        customToster('failed_to_update_coupon'.tr, isSuccess: false);
      }

      _isLoading = false;
      update();

      return updatedCoupon != null;
    } catch (e) {
      _isLoading = false;
      update();
      log('Error updating coupon: $e');
      customToster('failed_to_update_coupon'.tr, isSuccess: false);
      return false;
    }
  }

  /// Delete coupon
  Future<bool> deleteCoupon(String id) async {
    try {
      _isLoading = true;
      update();

      bool success = await couponRepoInterface.deleteCoupon(id);

      if (success) {
        _coupons?.removeWhere((c) => c.id == id);
        customToster('coupon_deleted_successfully'.tr, isSuccess: true);
      } else {
        customToster('failed_to_delete_coupon'.tr, isSuccess: false);
      }

      _isLoading = false;
      update();

      return success;
    } catch (e) {
      _isLoading = false;
      update();
      log('Error deleting coupon: $e');
      customToster('failed_to_delete_coupon'.tr, isSuccess: false);
      return false;
    }
  }

  /// Increment usage count when coupon is applied to an order
  Future<bool> useCoupon(String id) async {
    try {
      bool success = await couponRepoInterface.incrementUsageCount(id);

      if (success) {
        // Update local coupon
        final index = _coupons?.indexWhere((c) => c.id == id);
        if (index != null && index != -1 && _coupons != null) {
          _coupons![index] = _coupons![index].copyWith(
            usedCount: _coupons![index].usedCount + 1,
          );
          update();
        }
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  // Form helpers
  void setDiscountType(String type, {bool withUpdate = true}) {
    _discountType = type;
    if (withUpdate) update();
  }

  void toggleActiveStatus(bool value, {bool withUpdate = true}) {
    _isActive = value;
    if (withUpdate) update();
  }

  void resetForm() {
    _discountType = 'percentage';
    _isActive = true;
  }

  // Validation methods
  String? validateCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'coupon_code_required'.tr;
    }
    if (value.trim().length < 3) {
      return 'coupon_code_min_3_chars'.tr;
    }
    return null;
  }

  String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'description_required'.tr;
    }
    return null;
  }

  String? validateDiscountValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'discount_value_required'.tr;
    }
    final discount = double.tryParse(value);
    if (discount == null || discount <= 0) {
      return 'enter_valid_discount_value'.tr;
    }
    if (_discountType == 'percentage' && discount > 100) {
      return 'percentage_cannot_exceed_100'.tr;
    }
    return null;
  }

  String? validateMinOrder(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final amount = double.tryParse(value);
    if (amount == null || amount < 0) {
      return 'enter_valid_amount'.tr;
    }
    return null;
  }

  String? validateUsageLimit(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final limit = int.tryParse(value);
    if (limit == null || limit < 1) {
      return 'enter_valid_usage_limit'.tr;
    }
    return null;
  }
}
