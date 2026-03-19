import 'package:appwrite_user_app/app/common/widgets/custom_appbar.dart';
import 'package:appwrite_user_app/app/controllers/address_controller.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/models/address_model.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:appwrite_user_app/app/modules/address/screens/full_screen_map_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as loc;

class AddEditAddressPage extends StatefulWidget {
  final AddressModel? address; // Null for add, non-null for edit

  const AddEditAddressPage({super.key, this.address});

  @override
  State<AddEditAddressPage> createState() => _AddEditAddressPageState();
}

class _AddEditAddressPageState extends State<AddEditAddressPage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressLine1Controller;
  late TextEditingController _addressLine2Controller;
  late TextEditingController _cityController;
  late TextEditingController _postalCodeController;
  
  bool _isDefault = false;
  bool _isSaving = false;
  bool _isFetchingAddress = false;

  late MapController _mapController;
  LatLng? _selectedLocation;
  final LatLng _defaultLocation = const LatLng(23.8103, 90.4125); // Dhaka, Bangladesh
  
  final loc.Location _locationService = loc.Location();
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing data if editing
    _nameController = TextEditingController(text: widget.address?.name ?? '');
    _phoneController = TextEditingController(text: widget.address?.phone ?? '');
    _addressLine1Controller = TextEditingController(text: widget.address?.addressLine1 ?? '');
    _addressLine2Controller = TextEditingController(text: widget.address?.addressLine2 ?? '');
    _cityController = TextEditingController(text: widget.address?.city ?? '');
    _postalCodeController = TextEditingController(text: widget.address?.postalCode ?? '');
    _isDefault = widget.address?.isDefault ?? false;

    _mapController = MapController();
    if (widget.address?.latitude != null && widget.address?.longitude != null) {
      _selectedLocation = LatLng(widget.address!.latitude!, widget.address!.longitude!);
    } else {
      _selectedLocation = _defaultLocation;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() => _isFetchingAddress = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          String streetInfo = '';
          if (place.street != null && place.street!.isNotEmpty && !place.street!.contains('+')) {
            streetInfo += place.street!;
          }
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            if (streetInfo.isNotEmpty) streetInfo += ', ';
            streetInfo += place.subLocality!;
          }
          if (streetInfo.isEmpty) {
            streetInfo = place.name ?? '';
          }
          
          if (_nameController.text.isEmpty) {
            _nameController.text = place.name ?? '';
          }
          _addressLine1Controller.text = streetInfo;
          
          String cityInfo = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? '';
          _cityController.text = cityInfo;
          _postalCodeController.text = place.postalCode ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error fetching address: $e');
    } finally {
      if (mounted) {
        setState(() => _isFetchingAddress = false);
      }
    }
  }

  Future<void> _openFullScreenMap() async {
    final selectedLocation = await Get.to<LatLng?>(() => FullScreenMapPage(
          initialLocation: _selectedLocation ?? _defaultLocation,
        ));

    if (selectedLocation != null) {
      setState(() {
        _selectedLocation = selectedLocation;
      });
      _mapController.move(selectedLocation, 16.0);
      _getAddressFromLatLng(selectedLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.address != null;

    return Scaffold(
      backgroundColor: ColorResource.scaffoldBackground,
      appBar: CustomAppbar(
        title: isEditing ? 'edit_address'.tr : 'add_address'.tr,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'location_map'.tr,
              style: poppinsMedium.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: ColorResource.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Constants.radiusDefault),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Constants.radiusDefault),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedLocation ?? _defaultLocation,
                        initialZoom: 15.0,
                        onMapEvent: (MapEvent event) {
                          if (event is MapEventMoveEnd) {
                            setState(() {
                              _selectedLocation = _mapController.camera.center;
                            });
                            _getAddressFromLatLng(_selectedLocation!);
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
                          size: 40,
                        ),
                      ),
                    ),
                    if (_isFetchingAddress)
                      Center(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(Constants.radiusSmall),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.fullscreen, color: ColorResource.primaryDark),
                          onPressed: _openFullScreenMap,
                          tooltip: 'full_screen_map'.tr,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // _buildMapControlButton(
                          //   icon: Icons.add,
                          //   onPressed: () {
                          //     final currentZoom = _mapController.camera.zoom;
                          //     _mapController.move(_selectedLocation ?? _defaultLocation, currentZoom + 1);
                          //   },
                          //   tooltip: 'Zoom In',
                          // ),
                          // const SizedBox(height: 8),
                          // _buildMapControlButton(
                          //   icon: Icons.remove,
                          //   onPressed: () {
                          //     final currentZoom = _mapController.camera.zoom;
                          //     _mapController.move(_selectedLocation ?? _defaultLocation, currentZoom - 1);
                          //   },
                          //   tooltip: 'Zoom Out',
                          // ),
                          // const SizedBox(height: 8),
                          _buildMapControlButton(
                            icon: Icons.my_location,
                            onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                            tooltip: 'my_location'.tr,
                            isLoading: _isLoadingLocation,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            _buildTextField(
              controller: _nameController,
              label: 'full_name'.tr,
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _phoneController,
              label: 'phone_number'.tr,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (value.length < 10) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _addressLine1Controller,
              label: 'address'.tr,
              icon: Icons.home_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // _buildTextField(
            //   controller: _addressLine2Controller,
            //   label: 'Address Line 2 (Optional)',
            //   icon: Icons.location_on_outlined,
            // ),
            // const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _cityController,
                    label: 'City *',
                    icon: Icons.location_city_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _postalCodeController,
                    label: 'Postal Code *',
                    icon: Icons.markunread_mailbox_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            
            SwitchListTile(
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value),
              title: Text(
                'set_as_default_address'.tr,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.textPrimary,
                ),
              ),
              activeColor: ColorResource.primaryDark,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorResource.primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Constants.radiusLarge),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: ColorResource.textWhite,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isEditing ? 'update_address'.tr : 'save_address'.tr,
                        style: poppinsBold.copyWith(
                          fontSize: Constants.fontSizeLarge,
                          color: ColorResource.textWhite,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Constants.radiusDefault),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(Constants.radiusSmall),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, color: ColorResource.primaryDark),
        onPressed: onPressed,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
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

      loc.PermissionStatus permissionGranted = await _locationService.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await _locationService.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) {
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
        _getAddressFromLatLng(newLocation);
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

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final controller = Get.find<AddressController>();
      String? userId = await Get.find<AuthController>().getUserId();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final address = AddressModel(
        id: widget.address?.id ?? '',
        userId: userId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2: _addressLine2Controller.text.trim(),
        city: _cityController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        isDefault: _isDefault,
        latitude: _selectedLocation?.latitude,
        longitude: _selectedLocation?.longitude,
      );

      if (widget.address == null) {
        // Add new address
        await controller.addAddress(address);
      } else {
        // Update existing address
        await controller.updateAddress(widget.address!.id, address);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save address. Please try again.',
        backgroundColor: ColorResource.error,
        colorText: ColorResource.textWhite,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
