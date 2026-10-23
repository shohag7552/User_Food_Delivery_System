import 'package:kikomart_user_app/app/models/banner_model.dart';

abstract class BannerRepoInterface {
  Future<List<BannerModel>> getActiveBanners();
  // Future<void> sendNotification();
}
