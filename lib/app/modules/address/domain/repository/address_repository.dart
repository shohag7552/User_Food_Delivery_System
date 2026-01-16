import 'dart:developer';
import 'package:appwrite/models.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/models/address_model.dart';
import 'package:appwrite_user_app/app/modules/address/domain/repository/address_repo_interface.dart';
import 'package:dart_appwrite/dart_appwrite.dart';

class AddressRepository implements AddressRepoInterface {
  final AppwriteService appwriteService;

  AddressRepository({required this.appwriteService});

  @override
  Future<List<AddressModel>> getAddresses() async {
    try {
      User? user = await appwriteService.getCurrentUser();

      if (user == null) {
        throw Exception('User not logged in');
      }

      final response = await appwriteService.listTable(
        tableId: AppwriteConfig.addressesCollection,
        queries: [
          Query.equal('user_id', user.$id),
          Query.orderDesc('\$createdAt'),
        ],
      );

      return response.rows
          .map((doc) => AddressModel.fromJson(doc.data))
          .toList();
    } catch (e) {
      log('Error fetching addresses: $e');
      rethrow;
    }
  }

  @override
  Future<AddressModel> addAddress(AddressModel address) async {
    try {
      final response = await appwriteService.createRow(
        collectionId: AppwriteConfig.addressesCollection,
        data: address.toJson(),
      );

      return AddressModel.fromJson(response.data);
    } catch (e) {
      log('Error adding address: $e');
      rethrow;
    }
  }

  @override
  Future<AddressModel> updateAddress(String id, AddressModel address) async {
    try {
      final response = await appwriteService.updateTable(
        tableId: AppwriteConfig.addressesCollection,
        rowId: id,
        data: address.toJson(),
      );

      return AddressModel.fromJson(response.data);
    } catch (e) {
      log('Error updating address: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteAddress(String id) async {
    try {
      await appwriteService.deleteRow(
        collectionId: AppwriteConfig.addressesCollection,
        rowId: id,
      );
    } catch (e) {
      log('Error deleting address: $e');
      rethrow;
    }
  }

  @override
  Future<void> setDefaultAddress(String id) async {
    try {
      User? user = await appwriteService.getCurrentUser();

      if (user == null) {
        throw Exception('User not logged in');
      }

      // First, get all addresses and unset the current default
      final addresses = await getAddresses();
      
      for (var address in addresses) {
        if (address.isDefault && address.id != id) {
          await updateAddress(
            address.id,
            address.copyWith(isDefault: false),
          );
        }
      }

      // Then set the new default
      final targetAddress = addresses.firstWhere((addr) => addr.id == id);
      await updateAddress(
        id,
        targetAddress.copyWith(isDefault: true),
      );
    } catch (e) {
      log('Error setting default address: $e');
      rethrow;
    }
  }
}
