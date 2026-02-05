import 'dart:developer';
import 'package:appwrite_user_app/app/models/banner_model.dart';
import 'package:appwrite_user_app/app/modules/banners/domain/repository/banner_repo_interface.dart';
import 'package:get/get.dart';

class BannerController extends GetxController implements GetxService {
  final BannerRepoInterface bannerRepoInterface;
  
  BannerController({required this.bannerRepoInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<BannerModel> _banners = [];
  List<BannerModel> get banners => _banners;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Fetch active banners
  Future<void> getBanners() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      update();

      _banners = await bannerRepoInterface.getActiveBanners();
      log('====> Banners loaded: ${_banners.length}');
      
      _isLoading = false;
      update();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load banners: $e';
      log('====> Error loading banners: $e');
      update();
    }
  }

  Future<void> sendNotification() async {
    await bannerRepoInterface.sendNotification();
  }
}
