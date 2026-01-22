import 'package:appwrite_user_app/app/models/business_setup_model.dart';
import 'package:appwrite_user_app/app/models/store_setup_model.dart';
import 'package:appwrite_user_app/app/modules/settings/domain/repository/settings_repo_interface.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController implements GetxService {
  final SettingsRepoInterface settingsRepoInterface;

  SettingsController({required this.settingsRepoInterface});

  BusinessSetupModel? _businessSetup;
  BusinessSetupModel? get businessSetup => _businessSetup;

  StoreSetupModel? _storeSetup;
  StoreSetupModel? get storeSetup => _storeSetup;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Fetch both business setup and store setup
  Future<bool> fetchSettings() async {
    _isLoading = true;
    update();

    try {
      // Fetch both in parallel for better performance
      final results = await Future.wait([
        settingsRepoInterface.getBusinessSetup(),
        settingsRepoInterface.getStoreSetup(),
      ]);

      _businessSetup = results[0] as BusinessSetupModel?;
      _storeSetup = results[1] as StoreSetupModel?;

      _isLoading = false;
      update();

      // Return true only if both are successfully fetched
      return _businessSetup != null && _storeSetup != null;
    } catch (e) {
      print('Error in fetchSettings: $e');
      _isLoading = false;
      update();
      return false;
    }
  }

  /// Fetch business setup only
  Future<bool> fetchBusinessSetup() async {
    try {
      _businessSetup = await settingsRepoInterface.getBusinessSetup();
      update();
      return _businessSetup != null;
    } catch (e) {
      print('Error fetching business setup: $e');
      return false;
    }
  }

  /// Fetch store setup only
  Future<bool> fetchStoreSetup() async {
    try {
      _storeSetup = await settingsRepoInterface.getStoreSetup();
      update();
      return _storeSetup != null;
    } catch (e) {
      print('Error fetching store setup: $e');
      return false;
    }
  }
}
