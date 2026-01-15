import 'package:appwrite_user_app/app/models/banner_model.dart';

abstract class BannerRepoInterface {
  Future<List<BannerModel>> getActiveBanners();
}
