import 'dart:developer';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/models/coupon_model.dart';
import 'package:appwrite_user_app/app/modules/coupons/domain/repository/coupon_repo_interface.dart';

class CouponRepository implements CouponRepoInterface {
  final AppwriteService appwriteService;

  CouponRepository({required this.appwriteService});

  @override
  Future<List<CouponModel>> getCoupons() async {
    try {
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.couponsCollection,
      );

      return response.rows.map((coupon) {
        log('===> Coupon Data: ${coupon.data}');
        return CouponModel.fromJson(coupon.data);
      }).toList();
    } catch (e) {
      log('Failed to get coupons: $e');
      return [];
    }
  }

  @override
  Future<CouponModel?> getCouponByCode(String code) async {
    try {
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.couponsCollection,
      );

      // Filter coupons by code
      final coupons = response.rows
          .map((coupon) => CouponModel.fromJson(coupon.data))
          .where((coupon) => coupon.code.toUpperCase() == code.toUpperCase())
          .toList();

      if (coupons.isEmpty) {
        return null;
      }

      return coupons.first;
    } catch (e) {
      log('Failed to get coupon by code: $e');
      return null;
    }
  }

  @override
  Future<bool> addCoupon(CouponModel coupon) async {
    try {
      await appwriteService.createRow(
        collectionId: AppwriteConfig.couponsCollection,
        data: coupon.toJson(),
      );
      return true;
    } catch (e) {
      log('Failed to add coupon: $e');
      return false;
    }
  }

  @override
  Future<CouponModel?> updateCoupon(String id, CouponModel coupon) async {
    try {
      final response = await appwriteService.updateTable(
        tableId: AppwriteConfig.couponsCollection,
        rowId: id,
        data: coupon.toJson(),
      );

      return CouponModel.fromJson(response.data);
    } catch (e) {
      log('Failed to update coupon: $e');
      return null;
    }
  }

  @override
  Future<bool> deleteCoupon(String id) async {
    try {
      await appwriteService.deleteRow(
        collectionId: AppwriteConfig.couponsCollection,
        rowId: id,
      );
      return true;
    } catch (e) {
      log('Failed to delete coupon: $e');
      return false;
    }
  }

  @override
  Future<bool> incrementUsageCount(String id) async {
    try {
      // First, get the current coupon
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.couponsCollection,
      );

      final coupon = response.rows
          .map((c) => CouponModel.fromJson(c.data))
          .firstWhere((c) => c.id == id);

      // Increment usage count
      final updatedCoupon = coupon.copyWith(
        usedCount: coupon.usedCount + 1,
      );

      // Update in database
      await appwriteService.updateTable(
        tableId: AppwriteConfig.couponsCollection,
        rowId: id,
        data: {'used_count': updatedCoupon.usedCount},
      );

      return true;
    } catch (e) {
      log('Failed to increment usage count: $e');
      return false;
    }
  }
}
