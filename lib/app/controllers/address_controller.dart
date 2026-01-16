import 'dart:developer';
import 'package:appwrite_user_app/app/models/address_model.dart';
import 'package:appwrite_user_app/app/modules/address/domain/repository/address_repo_interface.dart';
import 'package:get/get.dart';

class AddressController extends GetxController {
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

  @override
  void onInit() {
    super.onInit();
    fetchAddresses();
  }

  /// Fetch all addresses for current user
  Future<void> fetchAddresses() async {
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
      Get.snackbar('Error', 'Failed to load addresses');
    }
  }

  /// Add new address
  Future<void> addAddress(AddressModel address) async {
    try {
      await addressRepoInterface.addAddress(address);
      await fetchAddresses(); // Refresh list
      Get.back(); // Close add address page
      Get.snackbar(
        'Success',
        'Address added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      log('Error adding address: $e');
      Get.snackbar('Error', 'Failed to add address');
    }
  }

  /// Update existing address
  Future<void> updateAddress(String id, AddressModel address) async {
    try {
      await addressRepoInterface.updateAddress(id, address);
      await fetchAddresses(); // Refresh list
      Get.back(); // Close edit address page
      Get.snackbar(
        'Success',
        'Address updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      log('Error updating address: $e');
      Get.snackbar('Error', 'Failed to update address');
    }
  }

  /// Delete address
  Future<void> deleteAddress(String id) async {
    try {
      await addressRepoInterface.deleteAddress(id);
      await fetchAddresses(); // Refresh list
      Get.snackbar(
        'Success',
        'Address deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      log('Error deleting address: $e');
      Get.snackbar('Error', 'Failed to delete address');
    }
  }

  /// Set address as default
  Future<void> setDefaultAddress(String id) async {
    try {
      await addressRepoInterface.setDefaultAddress(id);
      await fetchAddresses(); // Refresh list
      Get.snackbar(
        'Success',
        'Default address updated',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      log('Error setting default address: $e');
      Get.snackbar('Error', 'Failed to set default address');
    }
  }

  /// Select address (for checkout)
  void selectAddress(AddressModel address) {
    _selectedAddress = address;
    update();
  }
}
