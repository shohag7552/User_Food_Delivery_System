import 'dart:developer';
import 'package:appwrite/models.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/helper/session_manager.dart';
import 'package:appwrite_user_app/app/modules/auth/domain/repository/auth_repo_interface.dart';
import 'package:appwrite_user_app/app/modules/auth/domain/services/password_reset_failure.dart';
import 'package:get/get.dart';

class AuthController extends GetxController implements GetxService {
  final AuthRepoInterface authRepoInterface;
  AuthController({required this.authRepoInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Cached auth state so widgets (via GetBuilder) can synchronously gate
  // login-only content. Primed at startup by [isAlreadyLoggedIn] and kept in
  // sync by [login] / [signup] / [logout].
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
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
  /// Credentials the user asked the app to remember, or null when the option
  /// is off. The sign-in form reads this to prefill itself; [logout] leaves it
  /// untouched so the values are still there on the next visit.
  ({String email, String password})? get rememberedCredentials =>
      authRepoInterface.getRememberedCredentials();

  /// [rememberMe] `true` stores the credentials for next time, `false` forgets
  /// any stored ones. Leave it null (the default) to not touch them at all —
  /// callers without a "remember me" control, such as the web auth dialog,
  /// should not silently wipe what the sign-in page saved.
  Future<bool> login(String email, String password, {bool? rememberMe}) async {
    bool isSuccess = false;
    _isLoading = true;
    update();

    try {
      isSuccess = await authRepoInterface.loginUser(email, password);
      if (isSuccess) {
        _isLoggedIn = true;
        if (rememberMe == true) {
          await authRepoInterface.saveRememberedCredentials(
            email: email,
            password: password,
          );
        } else if (rememberMe == false) {
          await authRepoInterface.clearRememberedCredentials();
        }
        SessionManager.loadUserData();
      }

      // if (isSuccess) {
      //   customToster('Login successful! Welcome back.');
      // } else {
      //   customToster('Login failed. Please check your credentials.');
      // }
    } catch (e) {
      String errorMessage = 'Login failed. Please try again.';

      final error = e.toString().toLowerCase();
      if (error.contains('blocked')) {
        errorMessage = 'account_blocked_login'.tr;
      } else if (e.toString().contains('Invalid credentials') ||
          e.toString().contains('401')) {
        errorMessage = 'Invalid email or password.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
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
    _isLoggedIn = await authRepoInterface.isLoggedIn();
    update();
    return _isLoggedIn;
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
        _isLoggedIn = true;
        SessionManager.loadUserData();
        customToster('Account created successfully!');
      } else {
        customToster('Failed to create account. Please try again.');
      }
    } catch (e) {
      isSuccess = false;
      String errorMessage = 'An error occurred during signup';

      if (e.toString().contains('409') ||
          e.toString().contains('already exists')) {
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

  Future<String> getUserEmail() async {
    User? user = await authRepoInterface.getCurrentUser();
    return user?.email ?? '';
  }

  // ── Password recovery (Appwrite account recovery link) ──────────────────

  bool _isSendingResetLink = false;
  bool get isSendingResetLink => _isSendingResetLink;

  bool _isResettingPassword = false;
  bool get isResettingPassword => _isResettingPassword;

  /// Translation key of the last recovery failure, so the reset screen can show
  /// a persistent inline explanation rather than a toast that has already
  /// faded by the time the user looks up from the keyboard.
  String? _resetErrorKey;
  String? get resetErrorKey => _resetErrorKey;

  void clearResetError() {
    if (_resetErrorKey == null) return;
    _resetErrorKey = null;
    update();
  }

  /// Requests the recovery email.
  ///
  /// Returns true when Appwrite accepted the request. The view must show the
  /// same neutral copy on true whether or not the address is registered — see
  /// [AuthRepoInterface.sendPasswordResetLink].
  Future<bool> sendPasswordResetLink(String email) async {
    _isSendingResetLink = true;
    _resetErrorKey = null;
    update();

    bool isSuccess = false;
    try {
      await authRepoInterface.sendPasswordResetLink(email);
      isSuccess = true;
    } on PasswordResetFailure catch (e) {
      _resetErrorKey = e.messageKey;
      customToster(e.messageKey.tr, isSuccess: false);
    } catch (e) {
      log('Send reset link error: $e');
      _resetErrorKey = 'something_went_wrong';
      customToster('something_went_wrong'.tr, isSuccess: false);
    }

    _isSendingResetLink = false;
    update();
    return isSuccess;
  }

  /// Redeems the link's `userId`/`secret` and sets the new password. Appwrite
  /// does not create a session for a completed recovery, so the user stays
  /// signed out and must sign in with the new password.
  Future<bool> resetPasswordWithLink({
    required String userId,
    required String secret,
    required String password,
  }) async {
    _isResettingPassword = true;
    _resetErrorKey = null;
    update();

    bool isSuccess = false;
    try {
      await authRepoInterface.resetPasswordWithLink(
        userId: userId,
        secret: secret,
        password: password,
      );
      isSuccess = true;
    } on PasswordResetFailure catch (e) {
      _resetErrorKey = e.messageKey;
      customToster(e.messageKey.tr, isSuccess: false);
    } catch (e) {
      log('Reset password error: $e');
      _resetErrorKey = 'something_went_wrong';
      customToster('something_went_wrong'.tr, isSuccess: false);
    }

    _isResettingPassword = false;
    update();
    return isSuccess;
  }

  Future<void> logout() async {
    await authRepoInterface.logout();
    _isLoggedIn = false;
    update();
    SessionManager.clearUserData();
  }

  /// Permanently closes the current account (blocks the auth user + flags the
  /// row inactive), then clears local state so the app drops back to guest.
  Future<bool> deleteAccount() async {
    _isLoading = true;
    update();

    bool isSuccess = false;
    try {
      await authRepoInterface.closeAccount();
      isSuccess = true;
      _isLoggedIn = false;
      SessionManager.clearUserData();
      customToster('account_closed_success'.tr);
    } catch (e) {
      log('Delete account error: $e');
      customToster('something_went_wrong'.tr, isSuccess: false);
    }

    _isLoading = false;
    update();
    return isSuccess;
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    update();
    try {
      final success = await authRepoInterface.updatePassword(
        password: newPassword,
        oldPassword: oldPassword,
      );
      _isLoading = false;
      update();
      return success;
    } catch (e) {
      _isLoading = false;
      update();
      log('Change password error: $e');
      customToster('failed_to_change_password'.tr, isSuccess: false);
      return false;
    }
  }
}
