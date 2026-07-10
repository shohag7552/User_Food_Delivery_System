import 'dart:async';
import 'dart:developer';

import 'package:appwrite_user_app/app/models/cart_item_model.dart';
import 'package:appwrite_user_app/app/models/flash_sale_item_model.dart';
import 'package:appwrite_user_app/app/models/flash_sale_model.dart';
import 'package:appwrite_user_app/app/modules/flash_sale/domain/repository/flash_sale_repo_interface.dart';
import 'package:get/get.dart';

/// Flash sale state for the ecommerce module: the currently running sale, its
/// items, and a 1-second countdown that expires the sale live in the UI.
class FlashSaleController extends GetxController implements GetxService {
  final FlashSaleRepoInterface flashSaleRepoInterface;

  FlashSaleController({required this.flashSaleRepoInterface});

  FlashSaleModel? _activeSale;
  FlashSaleModel? get activeSale => _activeSale;

  List<FlashSaleItemModel> _items = [];
  List<FlashSaleItemModel> get items => _items;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Duration _remaining = Duration.zero;
  Duration get remaining => _remaining;

  Timer? _ticker;

  /// A live sale with at least one sellable item.
  bool get hasActiveSale =>
      _activeSale != null && _activeSale!.isRunning && _items.isNotEmpty;

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }

  /// Drops cached sale data (used when the active module switches away).
  void clearForModuleSwitch() {
    _ticker?.cancel();
    _activeSale = null;
    _items = [];
    _remaining = Duration.zero;
    update();
  }

  Future<void> getFlashSale({bool reload = false}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      if (!reload) update();

      final sale = await flashSaleRepoInterface.getActiveFlashSale();
      if (sale == null) {
        _activeSale = null;
        _items = [];
        _ticker?.cancel();
      } else {
        _activeSale = sale;
        _items = await flashSaleRepoInterface.getFlashSaleItems(sale.id);
        _startTicker();
      }

      _isLoading = false;
      update();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load flash sale: $e';
      log('====> Error loading flash sale: $e');
      update();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _remaining = _activeSale?.remaining ?? Duration.zero;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final sale = _activeSale;
      if (sale == null) {
        _ticker?.cancel();
        return;
      }

      _remaining = sale.remaining;
      if (_remaining == Duration.zero) {
        // Sale just ended — clear it and check whether a follow-up sale
        // starts right away.
        _ticker?.cancel();
        _activeSale = null;
        _items = [];
        update();
        getFlashSale(reload: true);
        return;
      }
      update();
    });
  }

  /// The flash item for [productId] in the running sale, or null.
  FlashSaleItemModel? itemForProduct(String productId) {
    if (!hasActiveSale) return null;
    for (final item in _items) {
      if (item.productId == productId) return item;
    }
    return null;
  }

  /// Records sold quantities after a confirmed order (best effort): bumps
  /// sold_count for every ordered product that was part of the running sale,
  /// and mirrors the change into the cached items.
  Future<void> recordSoldItems(List<CartItemModel> orderedItems) async {
    if (!hasActiveSale) return;

    bool changed = false;
    for (final ordered in orderedItems) {
      final flashItem = itemForProduct(ordered.productId);
      if (flashItem == null) continue;

      await flashSaleRepoInterface.incrementSoldCount(
        flashItem.id,
        ordered.quantity,
      );
      _items = [
        for (final item in _items)
          if (item.id == flashItem.id)
            item.copyWith(soldCount: item.soldCount + ordered.quantity)
          else
            item,
      ];
      changed = true;
    }
    if (changed) update();
  }
}
