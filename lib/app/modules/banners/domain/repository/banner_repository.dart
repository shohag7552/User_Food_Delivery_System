import 'dart:developer';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/models/banner_model.dart';
import 'package:appwrite_user_app/app/modules/banners/domain/repository/banner_repo_interface.dart';

class BannerRepository implements BannerRepoInterface {
  final AppwriteService appwriteService;

  BannerRepository({required this.appwriteService});

  @override
  Future<List<BannerModel>> getActiveBanners() async {
    try {
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.bannersCollection,
        queries: [
          Query.equal('is_active', true),
          Query.orderAsc('sort_order'),
        ],
      );
      return response.rows.map((row) {
        log('====> Banner Data: ${row.data}');
        return BannerModel.fromJson(row.data);
      }).toList();
    } catch (e) {
      log('====> Error fetching banners: $e');
      rethrow;
    }
  }
}
