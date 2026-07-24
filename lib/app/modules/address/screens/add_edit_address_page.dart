import 'package:appwrite_user_app/app/common/widgets/auth_gate.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_appbar.dart';
import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/controllers/address_controller.dart';
import 'package:appwrite_user_app/app/controllers/auth_controller.dart';
import 'package:appwrite_user_app/app/helper/dashboard_tab_bus.dart';
import 'package:appwrite_user_app/app/helper/routes/app_router.dart';
import 'package:appwrite_user_app/app/modules/dashboard/widgets/web_profile_drawer.dart';
import 'package:appwrite_user_app/app/models/address_model.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Caps the content width on desktop web so the form + map stay readable
  /// instead of stretching edge to edge.
  static const double _maxContentWidth = 1080;

  /// Below this inner width the web card stacks the map above the form; at or
  /// above it they sit side by side.
  static const double _twoColumnWidth = 720;

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
    final selectedLocation = await context.pushNamed<LatLng?>(
      RouteNames.mapPicker,
      extra: _selectedLocation ?? _defaultLocation,
    );

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
    // Desktop web keeps the shared top-nav + account drawer; mobile/tablet use
    // the page's own app bar with a back button.
    final showWebNav = WebTopNav.isEnabled(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.scaffoldBackground,
      appBar: showWebNav
          ? WebTopNav(
              selectedIndex: null,
              onDestinationSelected: (index) =>
                  DashboardTabs.open(context, index),
              onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            )
          : CustomAppbar(
              title: isEditing ? 'edit_address'.tr : 'add_address'.tr,
            ),
      endDrawer: showWebNav ? const WebProfileDrawer() : null,
      body: AuthGate(
        child: Form(
          key: _formKey,
          child: showWebNav
              ? _buildWebBody(context, isEditing)
              : _buildMobileBody(isEditing),
        ),
      ),
    );
  }

  /// Mobile / tablet: a full-width single-column form.
  Widget _buildMobileBody(bool isEditing) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _mapLabel(),
        const SizedBox(height: 8),
        _mapSection(height: 250),
        const SizedBox(height: 20),
        ..._formFields(),
        const SizedBox(height: 32),
        _buildSaveButton(isEditing),
      ],
    );
  }

  /// Desktop web: a full-width scroll surface (so dragging anywhere — including
  /// the side gutters — scrolls) with a centred, width-capped card panel. On
  /// wide viewports the map and form sit side by side (a standard web
  /// address-entry layout); narrower widths stack them.
  Widget _buildWebBody(BuildContext context, bool isEditing) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Constants.paddingSizeLarge,
              vertical: Constants.paddingSizeExtraLarge,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'edit_address'.tr : 'add_address'.tr,
                  style: poppinsBold.copyWith(
                    fontSize: Constants.fontSizeOverLarge,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: Constants.paddingSizeLarge),
                _buildWebCard(context, isEditing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The surface panel that holds the map + form on web.
  Widget _buildWebCard(BuildContext context, bool isEditing) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(Constants.paddingSizeExtraLarge),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        border: Border.all(
          color: context.textLight.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Side-by-side when there's room; otherwise stack the sections.
          if (constraints.maxWidth >= _twoColumnWidth) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _mapLabel(),
                      const SizedBox(height: 8),
                      _mapSection(height: 460),
                    ],
                  ),
                ),
                const SizedBox(width: Constants.spaceSection),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._formFields(),
                      const SizedBox(height: Constants.spaceSection),
                      _buildSaveButton(isEditing),
                    ],
                  ),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _mapLabel(),
              const SizedBox(height: 8),
              _mapSection(height: 300),
              const SizedBox(height: 20),
              ..._formFields(),
              const SizedBox(height: 32),
              _buildSaveButton(isEditing),
            ],
          );
        },
      ),
    );
  }

  Widget _mapLabel() {
    return Text(
      'location_map'.tr,
      style: poppinsMedium.copyWith(
        fontSize: Constants.fontSizeDefault,
        color: context.textPrimary,
      ),
    );
  }

  /// The interactive map with the centre pin, address-fetch spinner, and the
  /// full-screen / my-location controls. [height] lets the web two-column
  /// layout use a taller map than the mobile stack.
  Widget _mapSection({required double height}) {
    return Container(
      height: height,
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
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(Constants.radiusSmall),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
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
    );
  }

  /// The address form fields (shared by the mobile and web layouts).
  List<Widget> _formFields() {
    return [
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
            color: context.textPrimary,
          ),
        ),
        activeColor: ColorResource.primaryDark,
        contentPadding: EdgeInsets.zero,
      ),
    ];
  }

  Widget _buildSaveButton(bool isEditing) {
    return SizedBox(
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
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(Constants.radiusSmall),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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

      final saved = widget.address == null
          ? await controller.addAddress(address)
          : await controller.updateAddress(widget.address!.id, address);

      // Navigation stays in the view: close the page once the save succeeds.
      if (saved && mounted) {
        context.pop();
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
