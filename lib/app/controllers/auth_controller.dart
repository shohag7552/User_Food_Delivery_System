import 'dart:developer';
import 'package:appwrite/models.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/controllers/settings_controller.dart';
import 'package:appwrite_user_app/app/helper/session_manager.dart';
import 'package:appwrite_user_app/app/modules/auth/domain/repository/auth_repo_interface.dart';
import 'package:appwrite_user_app/app/modules/auth/domain/services/password_reset_failure.dart';
import 'package:get/get.dart';

/// What a forgot-password request ended up doing.
enum ResetRequestOutcome {
  /// A 6-digit sign-in code was emailed (email-code mode).
  codeSent,

  /// A reset link was emailed (link mode).
  linkSent,

  failed,
}

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
      log('Sending password reset link to: $email');
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

  // ── Password recovery (email code sign-in) ───────────────────────────────
  //
  // When the store switches "email code" on, Forgot password stops sending
  // reset links: Appwrite emails a 6-digit code (createEmailToken) and the
  // code signs the customer straight in. Their password is not changed.

  /// True when the store uses email codes instead of reset links.
  bool get usesEmailCodeReset =>
      Get.isRegistered<SettingsController>() &&
      Get.find<SettingsController>().businessSetup?.isEmailOtpEnabled == true;

  /// Re-reads the store's setting. A screen opened by a cold deep link can
  /// arrive before settings were loaded, and the store can flip the switch
  /// while the app is open.
  Future<void> refreshResetMode() async {
    if (!Get.isRegistered<SettingsController>()) return;
    await Get.find<SettingsController>().fetchBusinessSetup();
  }

  bool _isSendingResetCode = false;
  bool get isSendingResetCode => _isSendingResetCode;

  bool _isVerifyingResetCode = false;
  bool get isVerifyingResetCode => _isVerifyingResetCode;

  /// Account the last emailed code belongs to (from createEmailToken).
  String? _codeUserId;

  /// Sends whatever the store currently uses: a sign-in code, or a reset
  /// link. The setting is re-read first so a stale app never sends the
  /// wrong one.
  Future<ResetRequestOutcome> requestPasswordReset(String email) async {
    _isSendingResetCode = true;
    update();
    try {
      await refreshResetMode();
    } catch (_) {
      // Offline: go with what was loaded.
    }

    if (!usesEmailCodeReset) {
      _isSendingResetCode = false;
      update();
      return await sendPasswordResetLink(email)
          ? ResetRequestOutcome.linkSent
          : ResetRequestOutcome.failed;
    }

    _resetErrorKey = null;
    update();

    var outcome = ResetRequestOutcome.failed;
    try {
      _codeUserId = await authRepoInterface.sendEmailCode(email);
      outcome = ResetRequestOutcome.codeSent;
    } on PasswordResetFailure catch (e) {
      _resetErrorKey = e.messageKey;
      customToster(e.messageKey.tr, isSuccess: false);
    } catch (e) {
      log('Send email code error: $e');
      _resetErrorKey = 'could_not_send_email_code';
      customToster('could_not_send_email_code'.tr, isSuccess: false);
    }

    _isSendingResetCode = false;
    update();
    return outcome;
  }

  /// Signs in with the emailed code. On success the customer is logged in
  /// exactly as after a password login.
  Future<bool> signInWithEmailCode({
    required String email,
    required String code,
  }) async {
    final userId = _codeUserId;
    if (userId == null) {
      _resetErrorKey = 'email_code_invalid_or_expired';
      update();
      return false;
    }

    _isVerifyingResetCode = true;
    _resetErrorKey = null;
    update();

    var isSuccess = false;
    try {
      await authRepoInterface.signInWithEmailCode(
        userId: userId,
        email: email,
        code: code,
      );
      _codeUserId = null;
      _isLoggedIn = true;
      SessionManager.loadUserData();
      isSuccess = true;
    } on PasswordResetFailure catch (e) {
      _resetErrorKey = e.messageKey;
    } catch (e) {
      log('Email code sign-in error: $e');
      _resetErrorKey = 'could_not_verify_email_code';
    }

    _isVerifyingResetCode = false;
    update();
    return isSuccess;
  }

  /// Drops an in-progress code sign-in. Pass `notify: false` from a widget's
  /// `dispose`, where rebuilding is not allowed.
  void clearCodeReset({bool notify = true}) {
    _codeUserId = null;
    _resetErrorKey = null;
    if (notify) update();
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
