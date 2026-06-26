import 'package:appwrite_user_app/app/controllers/settings_controller.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth for which storefront ("module") is active.
///
/// A store can run Food, Ecommerce, or both (driven by business_setup flags).
/// Repositories scope their queries by [current], and the food path stays
/// identical because the default resolves to 'food'.
class ModuleController extends GetxController implements GetxService {
  final SharedPreferences sharedPreferences;

  ModuleController({required this.sharedPreferences});

  static const String food = 'food';
  static const String ecommerce = 'ecommerce';

  String _activeModule = food;
  bool _isFoodEnabled = true;
  bool _isEcommerceEnabled = false;

  String get activeModule => _activeModule;
  bool get isFoodEnabled => _isFoodEnabled;
  bool get isEcommerceEnabled => _isEcommerceEnabled;
  bool get bothEnabled => _isFoodEnabled && _isEcommerceEnabled;
  bool get isFood => _activeModule == food;
  bool get isEcommerce => _activeModule == ecommerce;

  /// Safe static accessor for repositories. Defaults to 'food' if the
  /// controller isn't registered yet, so queries never break.
  static String get current => Get.isRegistered<ModuleController>()
      ? Get.find<ModuleController>().activeModule
      : food;

  /// Resolve enabled modules + the active module from business setup.
  /// Call once after settings are fetched (splash bootstrap).
  void init() {
    final setup = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>().businessSetup
        : null;

    _isFoodEnabled = setup?.isFoodModuleEnabled ?? true;
    _isEcommerceEnabled = setup?.isEcommerceModuleEnabled ?? false;

    // Never leave the store with zero modules.
    if (!_isFoodEnabled && !_isEcommerceEnabled) {
      _isFoodEnabled = true;
    }

    final stored = sharedPreferences.getString(Constants.activeModule);
    final preferred = setup?.defaultModule ?? food;

    if (stored != null && _isEnabled(stored)) {
      _activeModule = stored;
    } else if (_isEnabled(preferred)) {
      _activeModule = preferred;
    } else {
      _activeModule = _isEcommerceEnabled ? ecommerce : food;
    }

    update();
  }

  bool _isEnabled(String module) {
    if (module == food) return _isFoodEnabled;
    if (module == ecommerce) return _isEcommerceEnabled;
    return false;
  }

  /// Public check for whether a given module is enabled for this store.
  bool isModuleEnabled(String module) => _isEnabled(module);

  /// Switch the active storefront and persist the choice.
  /// Returns true when the active module actually changed.
  Future<bool> switchModule(String module) async {
    if (!_isEnabled(module) || module == _activeModule) return false;
    _activeModule = module;
    await sharedPreferences.setString(Constants.activeModule, module);
    update();
    return true;
  }
}
