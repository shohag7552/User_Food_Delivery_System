import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kikomart_user_app/app/resources/colors.dart';
import 'package:kikomart_user_app/app/resources/constants.dart';
import 'package:kikomart_user_app/app/resources/text_style.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:kikomart_user_app/app/common/widgets/app_map_layers.dart';
import 'package:kikomart_user_app/app/models/address_model.dart';
import 'package:latlong2/latlong.dart';

/// Pieces of checkout's delivery-address card.
class CheckoutMapPreview extends StatelessWidget {
  const CheckoutMapPreview({
    super.key,
    required this.address,
    required this.hasLatLng,
    required this.onTap,
  });

  final AddressModel address;
  final bool hasLatLng;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!hasLatLng) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 130,
          width: double.infinity,
          color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 30, color: context.textLight),
              const SizedBox(height: 8),
              Text(
                'set_location_on_map'.tr,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeSmall,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final point = LatLng(address.latitude!, address.longitude!);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: Stack(
          children: [
            FlutterMap(
              key: ValueKey(
                '${address.id}_${address.latitude}_${address.longitude}',
              ),
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15.5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                const AppTileLayer(),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.location_on,
                        color: ColorResource.primaryDark,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const PositionedDirectional(
              bottom: Constants.paddingSizeExtraSmall,
              start: Constants.paddingSizeExtraSmall,
              child: MapAttribution(),
            ),
            if (address.isDefault)
              Positioned(top: 8, left: 8, child: CheckoutDefaultChip()),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.cardBackground.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_location_alt_outlined,
                      size: 14,
                      color: ColorResource.primaryDark,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'set_location_on_map'.tr,
                      style: poppinsMedium.copyWith(
                        fontSize: Constants.fontSizeExtraSmall,
                        color: ColorResource.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckoutDefaultChip extends StatelessWidget {
  const CheckoutDefaultChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ColorResource.primaryDark,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'default'.tr,
        style: poppinsBold.copyWith(
          fontSize: Constants.fontSizeExtraSmall,
          color: ColorResource.textWhite,
        ),
      ),
    );
  }
}

class CheckoutAddressDetails extends StatelessWidget {
  const CheckoutAddressDetails({
    super.key,
    required this.address,
    required this.distanceKm,
    required this.isOutsideRadius,
    required this.onEditDetails,
    required this.onChangeAddress,
  });

  final AddressModel address;
  final double? distanceKm;
  final bool isOutsideRadius;
  final VoidCallback onEditDetails;
  final VoidCallback onChangeAddress;

  @override
  Widget build(BuildContext context) {
    final distanceKm = this.distanceKm; // local, so the null check promotes
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: context.textLight.withValues(alpha: 0.2)),
          _detailRow(context, 'recipient'.tr, address.name),
          _detailRow(context, 'phone'.tr, address.phone),
          _detailRow(context, 'address'.tr, address.fullAddress),
          if (distanceKm != null)
            _detailRow(
              context,
              'distance'.tr,
              isOutsideRadius
                  ? '${distanceKm.toStringAsFixed(2)} km • ${'outside_delivery_radius'.tr}'
                  : '${distanceKm.toStringAsFixed(2)} km',
              valueColor: isOutsideRadius ? Colors.red : null,
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEditDetails,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorResource.primaryDark,
                    side: BorderSide(
                      color: ColorResource.primaryDark.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(
                    'edit_details'.tr,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: ColorResource.primaryDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onChangeAddress,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: ColorResource.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: Text(
                    'change_address'.tr,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeSmall,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: poppinsRegular.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: context.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: poppinsMedium.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: valueColor ?? context.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CheckoutNoAddressCard extends StatelessWidget {
  const CheckoutNoAddressCard({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ColorResource.primaryDark.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_location_alt_outlined,
              color: ColorResource.primaryDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'add_delivery_address'.tr,
              style: poppinsMedium.copyWith(
                fontSize: Constants.fontSizeDefault,
                color: context.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: ColorResource.primaryDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'add'.tr,
              style: poppinsBold.copyWith(
                fontSize: Constants.fontSizeSmall,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
