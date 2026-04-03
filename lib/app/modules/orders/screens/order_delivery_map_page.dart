import 'package:appwrite_user_app/app/common/widgets/custom_appbar.dart';
import 'package:appwrite_user_app/app/models/order_model.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OrderDeliveryMapPage extends StatefulWidget {
  final DeliverymanInfo deliveryman;
  final String businessName;
  final String businessAddress;
  final double businessLatitude;
  final double businessLongitude;

  const OrderDeliveryMapPage({
    super.key,
    required this.deliveryman,
    required this.businessName,
    required this.businessAddress,
    required this.businessLatitude,
    required this.businessLongitude,
  });

  @override
  State<OrderDeliveryMapPage> createState() => _OrderDeliveryMapPageState();
}

class _OrderDeliveryMapPageState extends State<OrderDeliveryMapPage> {
  late final MapController _mapController;
  late final LatLng _businessLocation;
  late final LatLng _deliverymanLocation;
  bool _hasBoundMarkers = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _businessLocation = LatLng(
      widget.businessLatitude,
      widget.businessLongitude,
    );
    _deliverymanLocation = LatLng(
      widget.deliveryman.latitude!,
      widget.deliveryman.longitude!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initialCenter = LatLng(
      (widget.businessLatitude + widget.deliveryman.latitude!) / 2,
      (widget.businessLongitude + widget.deliveryman.longitude!) / 2,
    );

    return Scaffold(
      backgroundColor: ColorResource.scaffoldBackground,
      appBar: CustomAppbar(title: 'Delivery Location'),
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
                          : 'Business',
                    ),
                  ),
                  Marker(
                    point: _deliverymanLocation,
                    width: 120,
                    height: 80,
                    child: _buildMarker(
                      icon: Icons.delivery_dining,
                      color: Colors.red,
                      label: widget.deliveryman.name.isNotEmpty
                          ? widget.deliveryman.name
                          : 'Deliveryman',
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
                color: ColorResource.cardBackground,
                borderRadius: BorderRadius.circular(Constants.radiusLarge),
                boxShadow: ColorResource.customShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLocationInfo(
                    icon: Icons.delivery_dining,
                    iconColor: Colors.red,
                    title: widget.deliveryman.name.isNotEmpty
                        ? widget.deliveryman.name
                        : 'Deliveryman',
                    subtitle: 'Current location',
                  ),
                  const SizedBox(height: 12),
                  _buildLocationInfo(
                    icon: Icons.storefront,
                    iconColor: ColorResource.primaryDark,
                    title: widget.businessName.isNotEmpty
                        ? widget.businessName
                        : 'Business',
                    subtitle: widget.businessAddress.isNotEmpty
                        ? widget.businessAddress
                        : 'Business location',
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
        _deliverymanLocation,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: ColorResource.customShadow,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: poppinsMedium.copyWith(
              fontSize: Constants.fontSizeSmall,
              color: ColorResource.textPrimary,
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
                  color: ColorResource.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: poppinsRegular.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: ColorResource.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
