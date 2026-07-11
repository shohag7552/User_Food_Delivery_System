import 'package:appwrite_user_app/app/models/brand_model.dart';

abstract class BrandRepoInterface {
  /// Active brands, ordered by sort order.
  Future<List<BrandModel>> getBrands();

  /// Fetch a single brand by its document id (deep-link hydration)
  Future<BrandModel?> getBrandById(String id);
}
