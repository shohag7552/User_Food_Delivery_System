import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/models/coupon_model.dart';
import 'package:appwrite_user_app/app/modules/coupons/domain/repository/coupon_repo_interface.dart';
import 'package:get/get.dart';

class CouponController extends GetxController implements GetxService {
  final CouponRepoInterface couponRepoInterface;
  CouponController({required this.couponRepoInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<CouponModel>? _coupons;
  List<CouponModel>? get coupons => _coupons;

  // Form state for adding/editing
  String _discountType = 'percentage';
  String get discountType => _discountType;

  bool _isActive = true;
  bool get isActive => _isActive;

  /// Fetch all coupons
  Future<void> getCoupons() async {
    try {
      _isLoading = true;
      update();

      _coupons = await couponRepoInterface.getCoupons();

      _isLoading = false;
      update();
    } catch (e) {
      _isLoading = false;
      update();
      customToster('Failed to load coupons: $e', isSuccess: false);
    }
  }

  /// Validate coupon by code
  Future<CouponModel?> validateCouponCode(String code, {double? orderAmount}) async {
    try {
      final coupon = await couponRepoInterface.getCouponByCode(code);

      if (coupon == null) {
        customToster('Coupon code not found', isSuccess: false);
        return null;
      }

      if (!coupon.isValid(orderAmount: orderAmount)) {
        if (!coupon.isActive) {
          customToster('This coupon is no longer active', isSuccess: false);
        } else if (DateTime.now().isBefore(coupon.validFrom)) {
          customToster('This coupon is not yet valid', isSuccess: false);
        } else if (DateTime.now().isAfter(coupon.validUntil)) {
          customToster('This coupon has expired', isSuccess: false);
        } else if (coupon.usageLimit != null && coupon.usedCount >= coupon.usageLimit!) {
          customToster('This coupon has reached its usage limit', isSuccess: false);
        } else if (coupon.minOrderAmount != null && orderAmount != null && orderAmount < coupon.minOrderAmount!) {
          customToster('Minimum order amount of \$${coupon.minOrderAmount!.toStringAsFixed(2)} required', isSuccess: false);
        } else {
          customToster('This coupon is not valid', isSuccess: false);
        }
        return null;
      }

      customToster('Coupon applied successfully!', isSuccess: true);
      return coupon;
    } catch (e) {
      customToster('Failed to validate coupon: $e', isSuccess: false);
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
        customToster('Coupon added successfully', isSuccess: true);
        await getCoupons();
        resetForm();
      } else {
        customToster('Failed to add coupon', isSuccess: false);
      }

      _isLoading = false;
      update();

      return success;
    } catch (e) {
      _isLoading = false;
      update();
      customToster('Failed to add coupon: $e', isSuccess: false);
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
        customToster('Coupon updated successfully', isSuccess: true);

        // Update in local list
        final index = _coupons!.indexWhere((c) => c.id == id);
        if (index != -1) {
          _coupons![index] = updatedCoupon;
        }

        resetForm();
      } else {
        customToster('Failed to update coupon', isSuccess: false);
      }

      _isLoading = false;
      update();

      return updatedCoupon != null;
    } catch (e) {
      _isLoading = false;
      update();
      customToster('Failed to update coupon: $e', isSuccess: false);
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
        customToster('Coupon deleted successfully', isSuccess: true);
      } else {
        customToster('Failed to delete coupon', isSuccess: false);
      }

      _isLoading = false;
      update();

      return success;
    } catch (e) {
      _isLoading = false;
      update();
      customToster('Failed to delete coupon: $e', isSuccess: false);
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
      return 'Coupon code is required';
    }
    if (value.trim().length < 3) {
      return 'Coupon code must be at least 3 characters';
    }
    return null;
  }

  String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    return null;
  }

  String? validateDiscountValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Discount value is required';
    }
    final discount = double.tryParse(value);
    if (discount == null || discount <= 0) {
      return 'Please enter a valid discount value';
    }
    if (_discountType == 'percentage' && discount > 100) {
      return 'Percentage cannot exceed 100%';
    }
    return null;
  }

  String? validateMinOrder(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final amount = double.tryParse(value);
    if (amount == null || amount < 0) {
      return 'Please enter a valid amount';
    }
    return null;
  }

  String? validateUsageLimit(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final limit = int.tryParse(value);
    if (limit == null || limit < 1) {
      return 'Please enter a valid usage limit';
    }
    return null;
  }
}
