import 'dart:developer';
import 'package:appwrite_user_app/app/models/brand_model.dart';
import 'package:appwrite_user_app/app/modules/brands/domain/repository/brand_repo_interface.dart';
import 'package:get/get.dart';

class BrandController extends GetxController implements GetxService {
  final BrandRepoInterface brandRepoInterface;

  BrandController({required this.brandRepoInterface});

  List<BrandModel> _brands = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BrandModel> get brands => _brands;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearForModuleSwitch() {
    _brands = [];
    _errorMessage = null;
    update();
  }

  /// Look up a brand by id (for product cards / detail).
  BrandModel? brandById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final brand in _brands) {
      if (brand.id == id) return brand;
    }
    return null;
  }

  Future<void> getBrands({bool reload = false}) async {
    if (_brands.isNotEmpty && !reload) return;
    try {
      _isLoading = true;
      _errorMessage = null;
      update();

      _brands = await brandRepoInterface.getBrands();

      _isLoading = false;
      update();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load brands';
      update();
      log('Error in getBrands: $e');
    }
  }
}
