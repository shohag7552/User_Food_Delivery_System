import 'package:appwrite_user_app/app/common/widgets/app_map_layers.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_appbar.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/address_controller.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class FullScreenMapPage extends StatefulWidget {
  final LatLng initialLocation;

  const FullScreenMapPage({super.key, required this.initialLocation});

  @override
  State<FullScreenMapPage> createState() => _FullScreenMapPageState();
}

class _FullScreenMapPageState extends State<FullScreenMapPage> {
  /// On wide screens the address bar and confirm panel are centred at this
  /// width instead of stretching across the whole map.
  static const double _panelMaxWidth = 480;

  late MapController _mapController;
  late LatLng _selectedLocation;
  final Location _locationService = Location();
  bool _isLoadingLocation = false;
  String? _resolvedAddress;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation;
    // After the first frame: the lookup notifies GetBuilders (including the
    // page underneath), which must not happen while this page is building.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _resolveAddress(_selectedLocation),
    );
  }

  /// Updates the live address bar. Keeps the last address when nothing is
  /// found or the map has moved on since.
  Future<void> _resolveAddress(LatLng position) async {
    final place = await Get.find<AddressController>().reverseGeocode(
      position.latitude,
      position.longitude,
    );
    if (!mounted || place == null) return;
    setState(() => _resolvedAddress = place.formatted);
  }

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.of(context).size.width >= WebTopNav.wideBreakpoint;
    // Full width on mobile; a centred, fixed-width panel on web/tablet.
    final panelConstraints = BoxConstraints(
      maxWidth: isWide ? _panelMaxWidth : double.infinity,
    );

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: CustomAppbar(title: 'select_location'.tr),
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
            children: const [AppTileLayer()],
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: 40.0,
              ), // Offset pin so tip points to center
              child: Icon(Icons.location_on, color: Colors.red, size: 50),
            ),
          ),

          // Live address bar — updates as the map is dragged.
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Center(
              child: ConstrainedBox(
                constraints: panelConstraints,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: context.cardBackground,
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
                          color: ColorResource.primaryDark.withValues(
                            alpha: 0.1,
                          ),
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
                                color: context.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            GetBuilder<AddressController>(
                              builder: (addressController) =>
                                  addressController.isGeocoding
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
                                            color: context.textSecondary,
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
                                        color: context.textPrimary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Center(
              child: ConstrainedBox(
                constraints: panelConstraints,
                child: Column(
                  // Stretch so the confirm button spans the panel's full width.
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: MapAttribution(),
                    ),
                    const SizedBox(height: Constants.paddingSizeSmall),
                    ElevatedButton(
                      onPressed: () {
                        // Return selected location to previous screen
                        context.pop(_selectedLocation);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorResource.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Constants.radiusLarge,
                          ),
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
                  ],
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
                  : const Icon(
                      Icons.my_location,
                      color: ColorResource.primaryDark,
                    ),
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

      PermissionStatus permissionGranted = await _locationService
          .hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _locationService.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return;
        }
      }

      final locationData = await _locationService.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        final newLocation = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
        _mapController.move(newLocation, 16.0);
        setState(() {
          _selectedLocation = newLocation;
        });
        _resolveAddress(newLocation);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      customToster('could_not_fetch_location'.tr, isSuccess: false);
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }
}
