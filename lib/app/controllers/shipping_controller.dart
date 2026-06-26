import 'dart:developer';
import 'package:appwrite_user_app/app/models/shipping_method_model.dart';
import 'package:appwrite_user_app/app/modules/shipping/domain/repository/shipping_repo_interface.dart';
import 'package:get/get.dart';

class ShippingController extends GetxController implements GetxService {
  final ShippingRepoInterface shippingRepoInterface;

  ShippingController({required this.shippingRepoInterface});

  List<ShippingMethodModel> _methods = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ShippingMethodModel> get methods => _methods;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> getShippingMethods({bool reload = false}) async {
    if (_methods.isNotEmpty && !reload) return;
    try {
      _isLoading = true;
      _errorMessage = null;
      update();

      _methods = await shippingRepoInterface.getShippingMethods();

      _isLoading = false;
      update();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load shipping methods';
      update();
      log('Error in getShippingMethods: $e');
    }
  }
}
