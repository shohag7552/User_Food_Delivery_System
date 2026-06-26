import 'dart:developer';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/models/brand_model.dart';
import 'package:appwrite_user_app/app/modules/brands/domain/repository/brand_repo_interface.dart';

class BrandRepository implements BrandRepoInterface {
  final AppwriteService appwriteService;

  BrandRepository({required this.appwriteService});

  @override
  Future<List<BrandModel>> getBrands() async {
    try {
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.brandsCollection,
        queries: [
          Query.equal('is_active', true),
          Query.orderAsc('sort_order'),
        ],
      );
      return response.rows.map((row) => BrandModel.fromJson(row.data)).toList();
    } catch (e) {
      log('Error fetching brands: $e');
      rethrow;
    }
  }
}
