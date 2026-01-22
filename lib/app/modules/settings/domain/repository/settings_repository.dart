import 'package:appwrite/appwrite.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/models/business_setup_model.dart';
import 'package:appwrite_user_app/app/models/store_setup_model.dart';
import 'package:appwrite_user_app/app/modules/settings/domain/repository/settings_repo_interface.dart';

class SettingsRepository implements SettingsRepoInterface {
  final AppwriteService appwriteService;

  SettingsRepository({required this.appwriteService});

  @override
  Future<BusinessSetupModel?> getBusinessSetup() async {
    try {
      // Query the business_setup collection using AppwriteService wrapper
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.businessSetup,
      );

      if (response.rows.isNotEmpty) {
        // Return the first document (assuming single business setup)
        return BusinessSetupModel.fromJson(response.rows.first.data);
      }
      
      return null;
    } on AppwriteException catch (e) {
      print('Error fetching business setup: ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected error fetching business setup: $e');
      return null;
    }
  }

  @override
  Future<StoreSetupModel?> getStoreSetup() async {
    try {
      // Query the store_setup collection using AppwriteService wrapper
      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.storeSetup,
      );

      if (response.rows.isNotEmpty) {
        // Return the first document (assuming single store setup)
        return StoreSetupModel.fromJson(response.rows.first.data);
      }
      
      return null;
    } on AppwriteException catch (e) {
      print('Error fetching store setup: ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected error fetching store setup: $e');
      return null;
    }
  }
}

