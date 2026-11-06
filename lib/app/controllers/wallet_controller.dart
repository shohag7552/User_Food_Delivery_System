import 'dart:developer';

import 'package:kikomart_user_app/app/controllers/profile_controller.dart';
import 'package:kikomart_user_app/app/helper/session_manager.dart';
import 'package:kikomart_user_app/app/models/wallet_transaction_model.dart';
import 'package:kikomart_user_app/app/modules/wallet/domain/repository/wallet_repo_interface.dart';
import 'package:get/get.dart';

/// The customer's wallet: balance (from the profile row) and the history of
/// every change to it, loaded a page at a time.
class WalletController extends GetxController implements GetxService {
  final WalletRepoInterface walletRepoInterface;

  WalletController({required this.walletRepoInterface});

  static const int _pageSize = 15;

  List<WalletTransactionModel> _transactions = [];
  // True until the first load, so the page opens on a spinner rather than
  // flashing "no transactions" for the frame before loading starts.
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  /// Translation key of the last load failure, shown with a retry button.
  String? _errorKey;

  List<WalletTransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorKey => _errorKey;

  double get balance => Get.find<ProfileController>().walletBalance;

  /// Reloads the balance and the first page of history.
  Future<void> loadWallet() async {
    // Auth-required: never hit Appwrite for a guest.
    if (!isUserLoggedIn()) {
      _transactions = [];
      _hasMore = false;
      _isLoading = false;
      update();
      return;
    }

    _isLoading = true;
    _errorKey = null;
    update();

    try {
      final profileController = Get.find<ProfileController>();
      // Always re-read: the balance may have moved since the profile loaded.
      await profileController.fetchUserProfile();
      final userId = profileController.userProfile?.id;
      if (userId == null) {
        _transactions = [];
        _hasMore = false;
      } else {
        final page = await walletRepoInterface.getTransactions(
          userId,
          limit: _pageSize,
          offset: 0,
        );
        _transactions = page;
        _hasMore = page.length >= _pageSize;
      }
    } catch (e) {
      log('Error loading wallet: $e');
      _errorKey = 'failed_to_load_wallet';
    }

    _isLoading = false;
    update();
  }

  /// Appends the next page (mobile: on scroll; web: "View more").
  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    final userId = Get.find<ProfileController>().userProfile?.id;
    if (userId == null) return;

    _isLoadingMore = true;
    update();

    try {
      final page = await walletRepoInterface.getTransactions(
        userId,
        limit: _pageSize,
        offset: _transactions.length,
      );
      _transactions = [..._transactions, ...page];
      _hasMore = page.length >= _pageSize;
    } catch (e) {
      // The loaded rows stay; scrolling or "View more" simply tries again.
      log('Error loading more wallet history: $e');
    }

    _isLoadingMore = false;
    update();
  }
}
