import 'package:appwrite_user_app/app/models/flash_sale_item_model.dart';
import 'package:appwrite_user_app/app/models/flash_sale_model.dart';

abstract class FlashSaleRepoInterface {
  /// The currently running flash sale (active flag + inside its time window),
  /// or null when none is live. When several overlap, the lowest sort_order
  /// wins.
  Future<FlashSaleModel?> getActiveFlashSale();

  /// Items of [flashSaleId] with their products hydrated. Items whose product
  /// is missing or unavailable are dropped.
  Future<List<FlashSaleItemModel>> getFlashSaleItems(String flashSaleId);

  /// Adds [quantity] to the item's sold_count (read-then-write, best effort).
  Future<void> incrementSoldCount(String itemId, int quantity);
}
