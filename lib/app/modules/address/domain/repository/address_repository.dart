import 'dart:convert';
import 'dart:developer';
import 'package:appwrite/models.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/models/address_model.dart';
import 'package:appwrite_user_app/app/models/geocoded_address_model.dart';
import 'package:appwrite_user_app/app/modules/address/domain/repository/address_repo_interface.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' show placemarkFromCoordinates;
import 'package:http/http.dart' as http;

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

  // ── Reverse geocoding (map position → address) ──────────────────────────

  /// Nominatim's public server allows at most one request per second.
  static const Duration _nominatimInterval = Duration(seconds: 1);
  static const int _geocodeCacheLimit = 100;

  final Map<String, GeocodedAddressModel> _geocodeCache = {};
  DateTime _nextNominatimSlot = DateTime.fromMillisecondsSinceEpoch(0);
  int _nominatimGeneration = 0;

  /// The `geocoding` plugin only ships Android and iOS implementations.
  bool get _hasNativeGeocoder =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<GeocodedAddressModel?> reverseGeocode(
    double latitude,
    double longitude, {
    String? languageCode,
  }) async {
    // ~1 m precision: dropping the pin on the same spot reuses the answer.
    final cacheKey =
        '${latitude.toStringAsFixed(5)},${longitude.toStringAsFixed(5)},$languageCode';
    final cached = _geocodeCache[cacheKey];
    if (cached != null) return cached;

    GeocodedAddressModel? result;
    if (_hasNativeGeocoder) {
      try {
        result = await _geocodeNative(latitude, longitude);
      } catch (e) {
        // e.g. Android devices without Google Play services have no geocoder.
        log('Native geocoder failed, falling back to Nominatim: $e');
      }
    }
    if (result == null || result.isEmpty) {
      result = await _geocodeNominatim(latitude, longitude, languageCode);
    }

    if (result != null && !result.isEmpty) {
      if (_geocodeCache.length >= _geocodeCacheLimit) _geocodeCache.clear();
      _geocodeCache[cacheKey] = result;
    }
    return result;
  }

  Future<GeocodedAddressModel?> _geocodeNative(
    double latitude,
    double longitude,
  ) async {
    final placemarks = await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isEmpty) return null;
    final p = placemarks.first;

    // A '+' means a Plus Code ("7JWV+3C"), not a readable street.
    bool usable(String? s) => s != null && s.trim().isNotEmpty && !s.contains('+');

    return GeocodedAddressModel(
      street: [p.street, p.subLocality].where(usable).join(', '),
      city: [p.locality, p.subAdministrativeArea, p.administrativeArea]
              .firstWhere(usable, orElse: () => '') ??
          '',
      postalCode: p.postalCode?.trim() ?? '',
      placeName: usable(p.name) ? p.name!.trim() : '',
    );
  }

  Future<GeocodedAddressModel?> _geocodeNominatim(
    double latitude,
    double longitude,
    String? languageCode,
  ) async {
    // Queue behind the previous request to respect the 1 req/s limit, and
    // skip the call entirely if a newer lookup arrived while waiting (the
    // map was dragged again) — only the latest position matters.
    final generation = ++_nominatimGeneration;
    final now = DateTime.now();
    final slot = _nextNominatimSlot.isAfter(now) ? _nextNominatimSlot : now;
    _nextNominatimSlot = slot.add(_nominatimInterval);
    final wait = slot.difference(now);
    if (wait > Duration.zero) await Future.delayed(wait);
    if (generation != _nominatimGeneration) return null;

    final uri = Uri.parse('${Constants.nominatimBaseUrl}/reverse').replace(
      queryParameters: {
        'format': 'jsonv2',
        'lat': '$latitude',
        'lon': '$longitude',
        'zoom': '18',
        'addressdetails': '1',
        if (languageCode != null && languageCode.isNotEmpty)
          'accept-language': languageCode,
        if (Constants.nominatimEmail.isNotEmpty)
          'email': Constants.nominatimEmail,
      },
    );
    final response = await http.get(
      uri,
      // Nominatim requires an identifying User-Agent. Browsers forbid setting
      // it and send a Referer instead, which Nominatim also accepts.
      headers: kIsWeb
          ? null
          : {
              'User-Agent':
                  '${Constants.appName}/${Constants.appVersion} (${Constants.packageName})',
            },
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Nominatim responded ${response.statusCode}');
    }

    final json = jsonDecode(utf8.decode(response.bodyBytes));
    // e.g. {"error": "Unable to geocode"} for a point in the sea.
    if (json is! Map<String, dynamic> || json['error'] != null) return null;
    final address = json['address'];
    if (address is! Map<String, dynamic>) return null;

    String pick(List<String> keys) {
      for (final key in keys) {
        final value = address[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
      return '';
    }

    final road = pick(['road', 'pedestrian', 'footway', 'path']);
    final houseNumber = pick(['house_number']);
    final area = pick(['neighbourhood', 'quarter', 'suburb', 'city_district']);
    final name = json['name'];

    return GeocodedAddressModel(
      street: [
        if (road.isNotEmpty) houseNumber.isNotEmpty ? '$houseNumber $road' : road,
        if (area.isNotEmpty) area,
      ].join(', '),
      city: pick([
        'city',
        'town',
        'village',
        'municipality',
        'county',
        'state_district',
        'state',
      ]),
      postalCode: pick(['postcode']),
      placeName: name is String ? name.trim() : '',
    );
  }
}
