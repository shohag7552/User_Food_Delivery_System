import 'dart:developer';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/models/shipping_method_model.dart';
import 'package:appwrite_user_app/app/modules/shipping/domain/repository/shipping_repo_interface.dart';

class ShippingRepository implements ShippingRepoInterface {
  final AppwriteService appwriteService;

  ShippingRepository({required this.appwriteService});

  @override
  Future<List<ShippingMethodModel>> getShippingMethods() async {
    try {
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.shippingMethodsCollection,
        queries: [
          Query.equal('is_active', true),
          Query.orderAsc('sort_order'),
        ],
      );
      return response.rows
          .map((row) => ShippingMethodModel.fromJson(row.data))
          .toList();
    } catch (e) {
      log('Error fetching shipping methods: $e');
      rethrow;
    }
  }
}
