import 'package:appwrite_user_app/app/modules/splash/domain/repository/splash_repo_interface.dart';
import 'package:appwrite_user_app/app/controllers/settings_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class SplashController extends GetxController implements GetxService{
  SplashRepoInterface splashRepositoryInterface;
  SplashController({required this.splashRepositoryInterface});

  // ConfigModel? _configModel;
  // ConfigModel? get configModel => _configModel;

  bool _maintanceModeOn = false;
  bool get maintanceModeOn => _maintanceModeOn;

  bool _userVerificationOn = false;
  bool get userVerificationOn => _userVerificationOn;

  // Future<bool> getConfigData()async {
  //   bool success = false;
  //   _configModel = null;
  //   _configModel = await splashRepositoryInterface.getConfigData();
  //   if(_configModel != null){
  //     success = true;
  //     for(var element in _configModel!.configData!){
  //       if(element.key == 'maintenance_mode_status' && element.value == '1'){
  //         _maintanceModeOn = true;
  //       }
  //       if(element.key == 'sms_config_status' && element.value == '1'){
  //         _userVerificationOn = true;
  //       }
  //     }
  //   } else {
  //     success = false;
  //   }
  //   return success;
  // }

  Future<void> saveIntroSeen(bool isSeen) async{
    await splashRepositoryInterface.saveIntroSeen(isSeen);
  }

  /// Fetch business and store setup data
  Future<bool> fetchSettings() async {
    try {
      // Use the settings controller to fetch data
      final settingsController = Get.find<SettingsController>();
      return await settingsController.fetchSettings();
    } catch (e) {
      print('Error fetching settings in SplashController: $e');
      return false;
    }
  }

  bool isIntroSeen() {
    return splashRepositoryInterface.isIntroSeen();
  }
}