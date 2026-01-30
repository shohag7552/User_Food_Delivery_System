import 'dart:developer';
import 'package:appwrite/models.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/modules/auth/domain/repository/auth_repo_interface.dart';
import 'package:get/get.dart';

class AuthController extends GetxController implements GetxService {
  final AuthRepoInterface authRepoInterface;
  AuthController({required this.authRepoInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  //
  // List<String> districtNameList = [];
  // List<Locations>? _districtList;
  // List<Locations>? get districtList => _districtList;
  //
  // List<String> divisionNameList = [];
  // List<Locations>? _divisionList;
  // List<Locations>? get divisionList => _divisionList;
  //
  // List<String> subDistrictNameList = [];
  // List<Locations>? _subDistrictList;
  // List<Locations>? get subDistrictList => _subDistrictList;
  //
  // Future<bool> getDivisionLocation({int? parentId}) async {
  //   bool isSuccess = false;
  //   _divisionList = null;
  //   _divisionList = await authRepoInterface.getDivisionLocation(parentId: parentId);
  //   print('Division List: ${_divisionList}');
  //   if (_divisionList != null) {
  //     divisionNameList = [];
  //     for (var e in _divisionList!) {
  //       if (e.name != null) {
  //         divisionNameList.add(e.name!);
  //       }
  //     }
  //     // _divisionList!.map((e) {
  //     //   divisionNameList.add(e.name!);
  //     // });
  //     isSuccess = true;
  //   } else {
  //     divisionNameList = [];
  //   }
  //   print('= Division List: ${divisionNameList} // ${_divisionList}');
  //   _isLoading = false;
  //   update();
  //   return isSuccess;
  // }
  //
  // Future<bool> getDistrictLocation({int? parentId, bool fromPostCreate = false}) async {
  //   if(fromPostCreate) {
  //     Get.dialog(CustomLoader());
  //   }
  //   bool isSuccess = false;
  //   _districtList = null;
  //   _districtList = await authRepoInterface.getDistrictLocation(parentId: parentId);
  //   if (_districtList != null) {
  //     districtNameList = [];
  //     for (var e in _districtList!) {
  //       if (e.name != null) {
  //         districtNameList.add(e.name!);
  //       }
  //     }
  //     // _districtList!.map((e) {
  //     //   districtNameList.add(e.name!);
  //     // });
  //     isSuccess = true;
  //   } else {
  //     districtNameList = [];
  //   }
  //   print('= District List: ${districtNameList} // ${_districtList}');
  //   _isLoading = false;
  //   if(Get.isDialogOpen!) {
  //     Get.back();
  //   }
  //   update();
  //   return isSuccess;
  // }
  //
  // Future<bool> getSubDistrictLocation({int? parentId, bool fromPostCreate = false}) async {
  //   if(fromPostCreate) {
  //     Get.dialog(CustomLoader());
  //   }
  //   bool isSuccess = false;
  //   _subDistrictList = null;
  //   _subDistrictList = await authRepoInterface.getSubDistrictLocation(parentId: parentId);
  //   print('Sub-District List: ${_subDistrictList}');
  //   if (_subDistrictList != null) {
  //     subDistrictNameList = [];
  //     for (var e in _subDistrictList!) {
  //       if (e.name != null) {
  //         subDistrictNameList.add(e.name!);
  //       }
  //     }
  //     // _subDistrictList!.map((e) {
  //     //   subDistrictNameList.add(e.name!);
  //     // });
  //     isSuccess = true;
  //   } else {
  //     subDistrictNameList = [];
  //   }
  //   print('= Sub-District List: ${subDistrictNameList} // ${_subDistrictList}');
  //   _isLoading = false;
  //   if(Get.isDialogOpen!) {
  //     Get.back();
  //   }
  //   update();
  //   return isSuccess;
  // }
  //
  Future<bool> login(String phone, String password) async {
    bool isSuccess = false;
    _isLoading = true;
    update();

    try {
      isSuccess = await authRepoInterface.loginUser(phone, password);
      
      // if (isSuccess) {
      //   customToster('Login successful! Welcome back.');
      // } else {
      //   customToster('Login failed. Please check your credentials.');
      // }
    } catch (e) {
      String errorMessage = 'Login failed. Please try again.';
      
      if (e.toString().contains('Invalid credentials') || 
          e.toString().contains('401')) {
        errorMessage = 'Invalid email or password.';
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Network error. Please check your connection.';
      }
      
      customToster(errorMessage);
      log('Login error: $e');
    }

    _isLoading = false;
    update();
    return isSuccess;
  }

  Future<bool> isAlreadyLoggedIn() async {
    return await authRepoInterface.isLoggedIn();
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    bool isSuccess = false;
    _isLoading = true;
    update();

    try {
      isSuccess = await authRepoInterface.signup(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

      if (isSuccess) {
        customToster('Account created successfully!');

      } else {
        customToster('Failed to create account. Please try again.');

      }
    } catch (e) {
      isSuccess = false;
      String errorMessage = 'An error occurred during signup';
      
      if (e.toString().contains('409') || e.toString().contains('already exists')) {
        errorMessage = 'Email already registered. Please login instead.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection.';
      }
      customToster('Signup Failed: $errorMessage');
    }

    _isLoading = false;
    update();
    return isSuccess;
  }

  Future<String?> getUserId() async {
    User? user = await authRepoInterface.getCurrentUser();
    return user?.$id;
  }

  Future<String?> getUserName() async {
    User? user = await authRepoInterface.getCurrentUser();
    return user?.name;
  }

  //
  // Future<bool> registrationSubmit(RegistrationModel registrationModel) async {
  //   bool isSuccess = false;
  //   _isLoading = true;
  //   update();
  //   Response response = await authRepoInterface.registrationSubmit(registrationModel: registrationModel);
  //   if (response.statusCode == 200) {
  //     isSuccess = true;
  //     Get.offAll(() => const SignInScreen());
  //   } else if(response.statusCode == 201){
  //     isSuccess = true;
  //     String tempToken = response.body['temporary_token'];
  //     int? token = response.body['token'];
  //     Get.to(() => VerificationScreen(registrationModel: registrationModel, tempToken: tempToken, token: token.toString()));
  //   } else {
  //     isSuccess = false;
  //     ApiChecker.checkApi(response);
  //   }
  //   _isLoading = false;
  //   update();
  //   return isSuccess;
  // }
  //
  // Future<bool> requestForgetPass(String phone) async {
  //   bool isSuccess = false;
  //   _isLoading = true;
  //   update();
  //   Response response = await authRepoInterface.requestForgetPassword(phone: phone);
  //   if (response.statusCode == 200) {
  //     isSuccess = true;
  //     print('-------success--------');
  //
  //     Get.to(VerificationScreen(tempToken: response.body['temporary_token'], token: response.body['token'], fromForgotPassword: true,));
  //   } else {
  //     isSuccess = false;
  //     ApiChecker.checkApi(response);
  //   }
  //   _isLoading = false;
  //   update();
  //   return isSuccess;
  // }
  //
  // Future<Response> verifyForgetPasswordOtp({required String temporaryToken, required String otp}) async {
  //   _isLoading = true;
  //   update();
  //   Response response = await authRepoInterface.verifyForgetPasswordOtp(temporaryToken: temporaryToken, otp: otp);
  //   if(response.statusCode == 200) {
  //     print('-------success--------');
  //     Get.off(() => ResetPasswordScreen(tempToken: response.body['temporary_token']));
  //   } else {
  //     ApiChecker.checkApi(response);
  //   }
  //   _isLoading = false;
  //   update();
  //   return response;
  // }
  //
  // Future<Response> changePassForForgetPassword({required String temporaryToken, required String password, required String confirmPass}) async {
  //   _isLoading = true;
  //   update();
  //   Response response = await authRepoInterface.changePassForForgetPassword(temporaryToken: temporaryToken, password: password, confirmPass: confirmPass);
  //   if(response.statusCode == 200) {
  //     print('-------success--------');
  //     customToast(response.body['message'], isError: false);
  //     Get.offAllNamed(AppPages.goToSignInPage());
  //     // Get.off(() => ResetPasswordScreen(tempToken: response.body['temporary_token']));
  //   } else {
  //     ApiChecker.checkApi(response);
  //   }
  //   _isLoading = false;
  //   update();
  //   return response;
  // }
  //
  // void loadingStop() {
  //   _isLoading = false;
  //   update();
  // }
  //
  // Future<bool> verifyPhone(String tempToken, String otp) async {
  //   bool isSuccess = false;
  //   _isLoading = true;
  //   update();
  //   Response response = await authRepoInterface.verifyPhone(tempToken, otp);
  //   if (response.statusCode == 200) {
  //     isSuccess = true;
  //
  //     await authRepoInterface.saveUserToken(response.body['access_token']);
  //     Get.offAll(() => const DashboardScreen());
  //     // Get.to(() => ResetPasswordScreen(phone: phone, otp: otp));
  //     // await authRepoInterface.updateDeviceToken().then((value) {
  //     //   debugPrint('token update successfully');
  //     // });
  //     // Get.to(VerificationScreen(phone: phone));
  //   } else {
  //     isSuccess = false;
  //     ApiChecker.checkApi(response);
  //   }
  //   _isLoading = false;
  //   update();
  //   return isSuccess;
  // }
  //
  // // Future<bool> resetPassword(String phone, String otp, String password, String confirmPassword) async {
  // //   bool isSuccess = false;
  // //   _isLoading = true;
  // //   update();
  // //   Response response = await authRepoInterface.resetPassword(phone: phone, otp: otp, password: password, confirmPass: confirmPassword);
  // //   if (response.statusCode == 200 && response.body['status']) {
  // //     isSuccess = true;
  // //
  // //     // await authRepoInterface.saveUserToken(response.body['token']);
  // //
  // //     Get.offAllNamed(AppPages.goToSignInPage());
  // //     // await authRepoInterface.updateDeviceToken().then((value) {
  // //     //   debugPrint('token update successfully');
  // //     // });
  // //     // Get.to(VerificationScreen(phone: phone));
  // //   } else {
  // //     isSuccess = false;
  // //     ApiChecker.checkApi(response);
  // //   }
  // //   _isLoading = false;
  // //   update();
  // //   return isSuccess;
  // // }
  //
  // bool alreadyLoggedIn(){
  //   return authRepoInterface.alreadyLoggedIn();
  // }
  // //
  // //
  // // void removeToken() {
  // //   authRepoInterface.clearToken();
  // // }
  // //
  // Future<void> logOut()async {
  //   await authRepoInterface.clearToken();
  //   Get.offNamed(AppPages.goToSignInPage());
  // }
  //
  // Future<bool> deleteAccount() async {
  //   final response = await authRepoInterface.delete();
  //   if (response.statusCode == 200) {
  //     await authRepoInterface.clearToken();
  //     return true;
  //   } else {
  //     // Handle error response
  //     print('Failed to delete account: ${response.body}');
  //     return false;
  //   }
  //
  // }
  //
  // Future<bool> languageChange(String languageCode) async {
  //   final response = await authRepoInterface.languageChange(languageCode);
  //   if (response.statusCode == 200) {
  //     return true;
  //   } else {
  //     // Handle error response
  //     print('Failed to delete account: ${response.body}');
  //     return false;
  //   }
  //
  // }
  //
  // Future<bool> updateDeviceToken({String? token}) async {
  //   String? deviceToken = '@';
  //   if(token == null) {
  //     deviceToken = await _saveDeviceToken();
  //     FirebaseMessaging.instance.subscribeToTopic(Constants.topic);
  //   } else {
  //     FirebaseMessaging.instance.unsubscribeFromTopic(Constants.topic);
  //   }
  //
  //
  //   final response = await authRepoInterface.updateDeviceToken(deviceToken ?? token ?? '@');
  //   if (response.statusCode == 200) {
  //     return true;
  //   } else {
  //     // Handle error response
  //     print('Failed to update token: ${response.body}');
  //     return false;
  //   }
  //
  // }
  //
  // Future<String?> _saveDeviceToken() async {
  //   String? deviceToken = '@';
  //   if(!GetPlatform.isWeb) {
  //     try {
  //       deviceToken = (await FirebaseMessaging.instance.getToken())!;
  //     }catch(_) {}
  //   }
  //   if (deviceToken != null) {
  //     log('--------Device Token----------> $deviceToken');
  //   }
  //   return deviceToken;
  // }
  //
  // void subscriveToTopic({required String topic, required bool isSubscribe}) {
  //   if(isSubscribe) {
  //     FirebaseMessaging.instance.subscribeToTopic(topic);
  //   } else {
  //     FirebaseMessaging.instance.unsubscribeFromTopic(topic);
  //   }
  //   customToast('Topic ${isSubscribe ? 'Subscribed' : 'Unsubscribed'} Successfully', isError: false);
  // }

  Future<void> logout() async {
    await authRepoInterface.logout();
  }
}
