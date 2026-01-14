import 'dart:developer';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/modules/products/domain/repository/product_repo_interface.dart';

class ProductRepository implements ProductRepoInterface {
  final AppwriteService appwriteService;

  ProductRepository({required this.appwriteService});

  @override
  Future<List<ProductModel>> getProducts() async {
    try {
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.productsCollection,
      );
      return response.rows.map((row) {
        log('====> Product Data: ${row.data}');
        return ProductModel.fromJson(row.data);
      }).toList();
    } catch (e) {
      log('====> Error fetching products: $e');
      rethrow;
    }
  }

  @override
  Future<List<ProductModel>> getSpecialProducts() async {
    try {
      // Query for products that have a discount (special products)
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.productsCollection,
        queries: [
          Query.isNotNull('discount_type'),
          Query.greaterThan('discount_value', 5),
          Query.equal('is_available', true),
        ],
      );
      return response.rows.map((row) {
        log('====> Special Product Data: ${row.data}');
        return ProductModel.fromJson(row.data);
      }).toList();
    } catch (e) {
      log('====> Error fetching special products: $e');
      rethrow;
    }
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    try {
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.productsCollection,
        queries: [
          Query.equal('category_id', categoryId),
          Query.equal('is_available', true),
        ],
      );
      return response.rows.map((row) {
        log('====> Product Data for category $categoryId: ${row.data}');
        return ProductModel.fromJson(row.data);
      }).toList();
    } catch (e) {
      log('====> Error fetching products by category: $e');
      rethrow;
    }
  }
}
