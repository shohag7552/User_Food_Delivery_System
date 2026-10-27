import 'dart:developer';
import 'package:kikomart_user_app/app/common/widgets/custom_toster.dart';
import 'package:kikomart_user_app/app/controllers/settings_controller.dart';
import 'package:kikomart_user_app/app/helper/session_manager.dart';
import 'package:kikomart_user_app/app/models/address_model.dart';
import 'package:kikomart_user_app/app/models/geocoded_address_model.dart';
import 'package:kikomart_user_app/app/modules/address/domain/repository/address_repo_interface.dart';
import 'package:get/get.dart';

class AddressController extends GetxController implements GetxService {
  final AddressRepoInterface addressRepoInterface;

  AddressController({required this.addressRepoInterface});

  List<AddressModel> _addresses = [];
  bool _isLoading = false;
  AddressModel? _selectedAddress;

  List<AddressModel> get addresses => _addresses;
  bool get isLoading => _isLoading;
  AddressModel? get selectedAddress => _selectedAddress;
  
  // Get default address or first address
  AddressModel? get defaultAddress {
    try {
      return _addresses.firstWhere((addr) => addr.isDefault);
    } catch (e) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  bool get hasAddresses => _addresses.isNotEmpty;

  /// True while the latest map-position → address lookup is running.
  bool _isGeocoding = false;
  bool get isGeocoding => _isGeocoding;
  int _geocodeRequestId = 0;

  @override
  void onInit() {
    super.onInit();
    fetchAddresses();
  }

  /// Fetch all addresses for current user
  Future<void> fetchAddresses() async {
    // Auth-required: never hit Appwrite for a guest.
    if (!isUserLoggedIn()) {
      _addresses = [];
      update();
      return;
    }
    try {
      _isLoading = true;
      update();

      _addresses = await addressRepoInterface.getAddresses();
      
      // Auto-select default address if none selected
      if (_selectedAddress == null && defaultAddress != null) {
        _selectedAddress = defaultAddress;
      }

      _isLoading = false;
      update();
    } catch (e) {
      _isLoading = false;
      update();
      log('Error fetching addresses: $e');
      customToster('failed_to_load_addresses'.tr, isSuccess: false);
    }
  }

  /// Add new address. Returns true on success — navigation (closing the
  /// page) is the calling view's responsibility, never the controller's.
  Future<bool> addAddress(AddressModel address) async {
    try {
      await addressRepoInterface.addAddress(address);
      await fetchAddresses(); // Refresh list
      customToster('address_added_successfully'.tr);
      return true;
    } catch (e) {
      log('Error adding address: $e');
      customToster('failed_to_add_address'.tr, isSuccess: false);
      return false;
    }
  }

  /// Update existing address. Returns true on success — navigation (closing
  /// the page/sheet) is the calling view's responsibility.
  Future<bool> updateAddress(String id, AddressModel address) async {
    try {
      await addressRepoInterface.updateAddress(id, address);
      await fetchAddresses(); // Refresh list
      customToster('address_updated_successfully'.tr);
      return true;
    } catch (e) {
      log('Error updating address: $e');
      customToster('failed_to_update_address'.tr, isSuccess: false);
      return false;
    }
  }

  /// Update an address and refresh the list WITHOUT navigating back.
  /// Use this when saving from a screen that should stay on top (e.g. the
  /// checkout map flow). Returns true on success.
  Future<bool> saveAddressChanges(String id, AddressModel address) async {
    try {
      await addressRepoInterface.updateAddress(id, address);
      await fetchAddresses();
      return true;
    } catch (e) {
      log('Error updating address: $e');
      return false;
    }
  }

  /// Delete address
  Future<void> deleteAddress(String id) async {
    try {
      await addressRepoInterface.deleteAddress(id);
      await fetchAddresses(); // Refresh list
      customToster('address_deleted_successfully'.tr);
    } catch (e) {
      log('Error deleting address: $e');
      customToster('failed_to_delete_address'.tr, isSuccess: false);
    }
  }

  /// Set address as default
  Future<void> setDefaultAddress(String id) async {
    try {
      await addressRepoInterface.setDefaultAddress(id);
      await fetchAddresses(); // Refresh list
      customToster('default_address_updated'.tr);
    } catch (e) {
      log('Error setting default address: $e');
      customToster('failed_to_set_default_address'.tr, isSuccess: false);
    }
  }

  /// Select address (for checkout)
  void selectAddress(AddressModel address) {
    _selectedAddress = address;
    update();
  }

  /// Resolves a map position to an address for the address screens.
  ///
  /// Only the latest call wins: when the map moves again before an earlier
  /// lookup finishes, the earlier one returns null so it can't overwrite the
  /// newer address. Null also means nothing was found or the lookup failed —
  /// callers simply keep what they already show.
  Future<GeocodedAddressModel?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    final requestId = ++_geocodeRequestId;
    _isGeocoding = true;
    update();

    GeocodedAddressModel? result;
    try {
      result = await addressRepoInterface.reverseGeocode(
        latitude,
        longitude,
        languageCode: Get.locale?.languageCode,
        locationIqKey: Get.find<SettingsController>().locationIqKey,
      );
    } catch (e) {
      log('Error resolving address from map position: $e');
    }

    if (requestId != _geocodeRequestId) return null;
    _isGeocoding = false;
    update();
    return result;
  }
}
