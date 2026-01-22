import 'package:appwrite_user_app/app/models/business_setup_model.dart';
import 'package:appwrite_user_app/app/models/store_setup_model.dart';

abstract class SettingsRepoInterface {
  Future<BusinessSetupModel?> getBusinessSetup();
  Future<StoreSetupModel?> getStoreSetup();
}
