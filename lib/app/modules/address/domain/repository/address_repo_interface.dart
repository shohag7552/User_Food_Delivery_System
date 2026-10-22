import 'package:appwrite_user_app/app/models/address_model.dart';
import 'package:appwrite_user_app/app/models/geocoded_address_model.dart';

abstract class AddressRepoInterface {
  Future<List<AddressModel>> getAddresses();
  Future<AddressModel> addAddress(AddressModel address);
  Future<AddressModel> updateAddress(String id, AddressModel address);
  Future<void> deleteAddress(String id);
  Future<void> setDefaultAddress(String id);

  /// Resolves a map position to an address. Returns null when nothing was
  /// found there or a newer lookup superseded this one; throws on failure.
  Future<GeocodedAddressModel?> reverseGeocode(
    double latitude,
    double longitude, {
    String? languageCode,
  });
}
