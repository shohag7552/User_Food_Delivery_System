import 'package:appwrite_user_app/app/common/widgets/custom_appbar.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart' hide Location;
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class FullScreenMapPage extends StatefulWidget {
  final LatLng initialLocation;

  const FullScreenMapPage({super.key, required this.initialLocation});

  @override
  State<FullScreenMapPage> createState() => _FullScreenMapPageState();
}

class _FullScreenMapPageState extends State<FullScreenMapPage> {
  late MapController _mapController;
  late LatLng _selectedLocation;
  final Location _locationService = Location();
  bool _isLoadingLocation = false;
  String? _resolvedAddress;
  bool _isFetchingAddress = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation;
    _resolveAddress(_selectedLocation);
  }

  Future<void> _resolveAddress(LatLng position) async {
    setState(() => _isFetchingAddress = true);
    try {
      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String?>[
          p.street,
          p.subLocality,
          p.locality ?? p.subAdministrativeArea,
          p.postalCode,
        ]
            .where((e) =>
                e != null && e.trim().isNotEmpty && !e.contains('+'))
            .toList();
        setState(() => _resolvedAddress = parts.join(', '));
      }
    } catch (_) {
      // Ignore — keep the last resolved address.
    } finally {
      if (mounted) setState(() => _isFetchingAddress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResource.scaffoldBackground,
      appBar: CustomAppbar(
        title: 'select_location'.tr,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 16.0,
              onMapEvent: (MapEvent event) {
                if (event is MapEventMoveEnd) {
                  setState(() {
                    _selectedLocation = _mapController.camera.center;
                  });
                  _resolveAddress(_selectedLocation);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: Constants.streetMapTheme,
                userAgentPackageName: Constants.packageName,
              ),
            ],
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40.0), // Offset pin so tip points to center
              child: Icon(
                Icons.location_on,
                color: Colors.red,
                size: 50,
              ),
            ),
          ),

          // Live address bar — updates as the map is dragged.
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: ColorResource.cardBackground,
                borderRadius: BorderRadius.circular(Constants.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: ColorResource.primaryDark.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: ColorResource.primaryDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'delivery_location'.tr,
                          style: poppinsMedium.copyWith(
                            fontSize: Constants.fontSizeExtraSmall,
                            color: ColorResource.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _isFetchingAddress
                            ? Row(
                                children: [
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'locating'.tr,
                                    style: poppinsMedium.copyWith(
                                      fontSize: Constants.fontSizeSmall,
                                      color: ColorResource.textSecondary,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                (_resolvedAddress?.isNotEmpty ?? false)
                                    ? _resolvedAddress!
                                    : 'move_map_to_set_location'.tr,
                                style: poppinsBold.copyWith(
                                  fontSize: Constants.fontSizeSmall,
                                  color: ColorResource.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                // Return selected location to previous screen
                Get.back(result: _selectedLocation);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorResource.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Constants.radiusLarge),
                ),
                elevation: 5,
              ),
              child: Text(
                'confirm_location'.tr,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeLarge,
                  color: ColorResource.textWhite,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'zoomInFull',
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () {
                final currentZoom = _mapController.camera.zoom;
                _mapController.move(_selectedLocation, currentZoom + 1);
              },
              child: const Icon(Icons.add, color: ColorResource.primaryDark),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              heroTag: 'zoomOutFull',
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () {
                final currentZoom = _mapController.camera.zoom;
                _mapController.move(_selectedLocation, currentZoom - 1);
              },
              child: const Icon(Icons.remove, color: ColorResource.primaryDark),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              heroTag: 'myLocationFull',
              backgroundColor: Colors.white,
              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
              child: _isLoadingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, color: ColorResource.primaryDark),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await _locationService.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _locationService.requestService();
        if (!serviceEnabled) {
          return;
        }
      }

      PermissionStatus permissionGranted = await _locationService.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _locationService.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return;
        }
      }

      final locationData = await _locationService.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        final newLocation = LatLng(locationData.latitude!, locationData.longitude!);
        _mapController.move(newLocation, 16.0);
        setState(() {
          _selectedLocation = newLocation;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      Get.snackbar('error'.tr, 'could_not_fetch_location'.tr);
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }
}
