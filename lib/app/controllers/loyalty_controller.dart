import 'dart:developer';

import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/controllers/profile_controller.dart';
import 'package:appwrite_user_app/app/controllers/settings_controller.dart';
import 'package:appwrite_user_app/app/helper/session_manager.dart';
import 'package:appwrite_user_app/app/models/loyalty_history_model.dart';
import 'package:appwrite_user_app/app/modules/loyalty_point/domain/repository/loyalty_repo_interface.dart';
import 'package:get/get.dart';

class LoyaltyController extends GetxController implements GetxService {
  final LoyaltyRepoInterface loyaltyRepoInterface;

  LoyaltyController({required this.loyaltyRepoInterface});

  List<LoyaltyHistoryModel> _history = [];
  bool _isLoading = false;
  bool _isConverting = false;

  List<LoyaltyHistoryModel> get history => _history;
  bool get isLoading => _isLoading;
  bool get isConverting => _isConverting;

  /// Whether the store is running the loyalty programme at all. Everything the
  /// app shows about points has to respect this — promising points that will
  /// never arrive is worse than staying quiet.
  bool get isLoyaltyEnabled {
    if (!Get.isRegistered<SettingsController>()) return false;
    return Get.find<SettingsController>().businessSetup?.isLoyaltyPointEnabled ??
        true;
  }

  double get earningRate {
    final settingsController = Get.find<SettingsController>();
    return settingsController.businessSetup?.loyaltyPointEarningRate ?? 1.0;
  }

  /// Points an order of [orderTotal] will earn once it is delivered.
  ///
  /// Mirrors the store app's award arithmetic exactly
  /// (`order_repository._addLoyaltyPointsForDeliveredOrder`): the grand total
  /// times the earning rate, floored. Returns 0 when the programme is off, so
  /// callers can simply hide the row.
  int pointsForOrderTotal(double orderTotal) {
    // Business setup not loaded yet — say nothing rather than quoting a figure
    // computed from the fallback rate, which would be wrong for any store that
    // configured a different one.
    if (!Get.isRegistered<SettingsController>()) return 0;
    final setup = Get.find<SettingsController>().businessSetup;
    if (setup == null) return 0;

    if (!setup.isLoyaltyPointEnabled) return 0;
    final rate = setup.loyaltyPointEarningRate;
    if (rate <= 0 || orderTotal <= 0) return 0;
    return (orderTotal * rate).floor();
  }

  double get walletConversionRate {
    final settingsController = Get.find<SettingsController>();
    return settingsController.businessSetup?.loyaltyPointWalletRate ?? 0.10;
  }

  Future<void> fetchHistory() async {
    // Auth-required: never hit Appwrite for a guest.
    if (!isUserLoggedIn()) {
      _history = [];
      update();
      return;
    }
    try {
      _isLoading = true;
      update();

      final settingsController = Get.find<SettingsController>();
      if (settingsController.businessSetup == null) {
        await settingsController.fetchBusinessSetup();
      }

      final profileController = Get.find<ProfileController>();
      if (profileController.userProfile == null) {
        await profileController.fetchUserProfile();
      }

      final user = profileController.userProfile;
      if (user == null) {
        _history = [];
        return;
      }

      _history = await loyaltyRepoInterface.getLoyaltyHistory(user.id);
    } catch (e) {
      log('Error fetching loyalty history: $e');
      customToster('Failed to load loyalty history', isSuccess: false);
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<bool> convertPointsToWallet(int points) async {
    final profileController = Get.find<ProfileController>();
    final user = profileController.userProfile;

    if (user == null) {
      customToster('Failed to load profile', isSuccess: false);
      return false;
    }

    if (points <= 0 || points > user.loyaltyPoints || walletConversionRate <= 0) {
      customToster('Enter valid loyalty points', isSuccess: false);
      return false;
    }

    try {
      _isConverting = true;
      update();

      final updatedUser = await loyaltyRepoInterface.convertPointsToWallet(
        user: user,
        points: points,
        conversionRate: walletConversionRate,
      );

      profileController.setUserProfile(updatedUser);
      await fetchHistory();
      customToster('Loyalty points converted to wallet');
      return true;
    } catch (e) {
      log('Error converting loyalty points: $e');
      customToster('Failed to convert loyalty points', isSuccess: false);
      return false;
    } finally {
      _isConverting = false;
      update();
    }
  }
}
 