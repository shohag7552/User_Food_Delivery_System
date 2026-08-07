import 'package:appwrite_user_app/app/common/widgets/custom_appbar.dart';
import 'package:appwrite_user_app/app/models/order_model.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class OrderDeliveryMapPage extends StatefulWidget {
  final DeliverymanInfo? deliveryman;
  final String businessName;
  final String businessAddress;
  final double businessLatitude;
  final double businessLongitude;
  final String deliveryAddress;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final bool showBackButton;

  const OrderDeliveryMapPage({
    super.key,
    required this.deliveryman,
    required this.businessName,
    required this.businessAddress,
    required this.businessLatitude,
    required this.businessLongitude,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    this.showBackButton = true,
  });

  @override
  State<OrderDeliveryMapPage> createState() => _OrderDeliveryMapPageState();
}

class _OrderDeliveryMapPageState extends State<OrderDeliveryMapPage> {
  late final MapController _mapController;
  late final LatLng _businessLocation;
  late final LatLng _deliveryAddressLocation;
  LatLng? _deliverymanLocation;
  bool _hasBoundMarkers = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _businessLocation = LatLng(
      widget.businessLatitude,
      widget.businessLongitude,
    );
    if (widget.deliveryman?.hasLocation == true) {
      _deliverymanLocation = LatLng(
        widget.deliveryman!.latitude!,
        widget.deliveryman!.longitude!,
      );
    }
    _deliveryAddressLocation = LatLng(
      widget.deliveryLatitude,
      widget.deliveryLongitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initialCenter = LatLng(
      _deliverymanLocation != null
          ? (widget.businessLatitude + _deliverymanLocation!.latitude) / 2
          : (widget.businessLatitude + widget.deliveryLatitude) / 2,
      _deliverymanLocation != null
          ? (widget.businessLongitude + _deliverymanLocation!.longitude) / 2
          : (widget.businessLongitude + widget.deliveryLongitude) / 2,
    );

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: CustomAppbar(
        title: 'delivery_location'.tr,
        showBackButton: widget.showBackButton,
        actions: widget.showBackButton
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 13.0,
              onMapReady: _bindMapWithMarkers,
            ),
            children: [
              TileLayer(
                urlTemplate: Constants.streetMapTheme,
                userAgentPackageName: Constants.packageName,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _businessLocation,
                    width: 120,
                    height: 80,
                    child: _buildMarker(
                      icon: Icons.storefront,
                      color: ColorResource.primaryDark,
                      label: widget.businessName.isNotEmpty
                          ? widget.businessName
                          : 'business'.tr,
                    ),
                  ),
                  if (_deliverymanLocation != null)
                    Marker(
                      point: _deliverymanLocation!,
                      width: 120,
                      height: 80,
                      child: _buildMarker(
                        icon: Icons.delivery_dining,
                        color: Colors.red,
                        label: widget.deliveryman?.name.isNotEmpty == true
                            ? widget.deliveryman!.name
                            : 'deliveryman'.tr,
                      ),
                    ),
                  Marker(
                    point: _deliveryAddressLocation,
                    width: 120,
                    height: 80,
                    child: _buildMarker(
                      icon: Icons.location_on,
                      color: Colors.green,
                      label: 'delivery_address'.tr,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardBackground,
                borderRadius: BorderRadius.circular(Constants.radiusLarge),
                boxShadow: ColorResource.customShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_deliverymanLocation != null) ...[
                    _buildLocationInfo(
                      icon: Icons.delivery_dining,
                      iconColor: Colors.red,
                      title: widget.deliveryman?.name.isNotEmpty == true
                          ? widget.deliveryman!.name
                          : 'deliveryman'.tr,
                      subtitle: 'current_location'.tr,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildLocationInfo(
                    icon: Icons.storefront,
                    iconColor: ColorResource.primaryDark,
                    title: widget.businessName.isNotEmpty
                        ? widget.businessName
                        : 'business'.tr,
                    subtitle: widget.businessAddress.isNotEmpty
                        ? widget.businessAddress
                        : 'business_location'.tr,
                  ),
                  const SizedBox(height: 12),
                  _buildLocationInfo(
                    icon: Icons.location_on,
                    iconColor: Colors.green,
                    title: 'delivery_address'.tr,
                    subtitle: widget.deliveryAddress.isNotEmpty
                        ? widget.deliveryAddress
                        : 'customer_location'.tr,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _bindMapWithMarkers() {
    if (_hasBoundMarkers) {
      return;
    }

    _hasBoundMarkers = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final bounds = LatLngBounds.fromPoints([
        _businessLocation,
        _deliveryAddressLocation,
        ?_deliverymanLocation,
      ]);

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(60, 60, 60, 220),
        ),
      );
    });
  }

  Widget _buildMarker({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: ColorResource.customShadow,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: poppinsMedium.copyWith(
              fontSize: Constants.fontSizeSmall,
              color: context.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Icon(icon, color: color, size: 34),
      ],
    );
  }

  Widget _buildLocationInfo({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Constants.radiusDefault),
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: poppinsRegular.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
