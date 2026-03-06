import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResource.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'Select Location',
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeLarge,
            color: ColorResource.textWhite,
          ),
        ),
        backgroundColor: ColorResource.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorResource.textWhite),
          onPressed: () => Get.back(),
        ),
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
                'Confirm Location',
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
      Get.snackbar('Error', 'Could not fetch current location');
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }
}
