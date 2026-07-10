import 'dart:developer';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/controllers/module_controller.dart';
import 'package:appwrite_user_app/app/models/flash_sale_item_model.dart';
import 'package:appwrite_user_app/app/models/flash_sale_model.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/modules/flash_sale/domain/repository/flash_sale_repo_interface.dart';

class FlashSaleRepository implements FlashSaleRepoInterface {
  final AppwriteService appwriteService;

  FlashSaleRepository({required this.appwriteService});

  @override
  Future<FlashSaleModel?> getActiveFlashSale() async {
    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.flashSalesCollection,
        queries: [
          Query.equal('is_active', true),
          Query.equal('module_type', ModuleController.ecommerce),
          Query.lessThanEqual('start_time', nowUtc),
          Query.greaterThanEqual('end_time', nowUtc),
          Query.orderAsc('sort_order'),
          Query.limit(1),
        ],
      );

      if (response.rows.isEmpty) return null;
      return FlashSaleModel.fromJson(response.rows.first.data);
    } catch (e) {
      log('Error fetching active flash sale: $e');
      rethrow;
    }
  }

  @override
  Future<List<FlashSaleItemModel>> getFlashSaleItems(String flashSaleId) async {
    try {
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.flashSaleItemsCollection,
        queries: [
          Query.equal('flash_sale_id', flashSaleId),
          Query.equal('module_type', ModuleController.ecommerce),
          Query.limit(100),
        ],
      );

      if (response.rows.isEmpty) return [];

      // Hydrate the joined products in one batch query.
      final productIds = response.rows
          .map((row) => row.data['product_id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final productsResponse = await appwriteService.listTable(
        tableId: AppwriteConfig.productsCollection,
        queries: [
          Query.equal(r'$id', productIds),
          Query.equal('is_available', true),
          Query.limit(productIds.length),
        ],
      );

      final productsById = {
        for (final row in productsResponse.rows)
          row.$id: ProductModel.fromJson(row.data),
      };

      return response.rows
          .map((row) => FlashSaleItemModel.fromJson(
                row.data,
                product: productsById[row.data['product_id']],
              ))
          // Drop items whose product vanished or is unavailable.
          .where((item) => item.product != null)
          .toList();
    } catch (e) {
      log('Error fetching flash sale items: $e');
      rethrow;
    }
  }

  @override
  Future<void> incrementSoldCount(String itemId, int quantity) async {
    try {
      final row = await appwriteService.getDocument(
        tableId: AppwriteConfig.flashSaleItemsCollection,
        rowId: itemId,
      );
      final current = (row.data['sold_count'] as num?)?.toInt() ?? 0;
      await appwriteService.updateTable(
        tableId: AppwriteConfig.flashSaleItemsCollection,
        rowId: itemId,
        data: {'sold_count': current + quantity},
      );
    } catch (e) {
      // Best effort — a failed counter must never surface to the order flow.
      log('Error incrementing flash sale sold_count: $e');
    }
  }
}
