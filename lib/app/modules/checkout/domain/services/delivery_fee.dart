import 'package:kikomart_user_app/app/models/address_model.dart';
import 'package:kikomart_user_app/app/models/business_setup_model.dart';
import 'package:kikomart_user_app/app/models/shipping_method_model.dart';
import 'package:latlong2/latlong.dart';

/// Checkout's delivery pricing, kept pure so it can be tested on its own.
///
/// The figure shown here is a preview: the server re-prices the order before
/// anything is charged (see `OrderController.quoteOrder`).

/// Straight-line distance from the store to [address], or null when either
/// end has no coordinates.
double? deliveryDistanceKm(
  BusinessSetupModel? businessSetup,
  AddressModel? address,
) {
  if (businessSetup?.storeLatitude == null ||
      businessSetup?.storeLongitude == null ||
      address?.latitude == null ||
      address?.longitude == null) {
    return null;
  }

  return const Distance().as(
    LengthUnit.Kilometer,
    LatLng(businessSetup!.storeLatitude!, businessSetup.storeLongitude!),
    LatLng(address!.latitude!, address.longitude!),
  );
}

double calculateDeliveryFee({
  required BusinessSetupModel? businessSetup,
  required AddressModel? address,
  required double orderAmount,
  required bool showsShipping,
  required ShippingMethodModel? selectedShipping,
}) {
  // Ecommerce with shipping methods on: the courier sets the price, so the
  // fee comes straight off the selected method's own rate table.
  if (showsShipping) {
    return selectedShipping?.feeFor(orderAmount) ?? 0;
  }

  // Everything else falls through to the distance-based rate below: food
  // orders, and ecommerce orders placed while shipping methods are off.
  //
  // With shipping off there are no couriers configured, so the store's own
  // deliveryman brings the parcel — the same fulfilment as a food order, and
  // therefore the same pricing: free above `free_delivery_above`, otherwise
  // distance x `delivery_fee_per_km`, floored at `min_delivery_fee`.
  final freeDeliveryAbove = businessSetup?.freeDeliveryAbove;

  if (freeDeliveryAbove != null && orderAmount >= freeDeliveryAbove) {
    return 0;
  }

  final distanceKm = deliveryDistanceKm(businessSetup, address);
  final minFee = businessSetup?.minDeliveryFee ?? 0;
  final feePerKm = businessSetup?.deliveryFeePerKm ?? 0;

  if (distanceKm == null) {
    return minFee;
  }

  final calculatedFee = distanceKm * feePerKm;
  return calculatedFee < minFee ? minFee : calculatedFee;
}

bool isOutsideDeliveryRadius(
  BusinessSetupModel? businessSetup,
  AddressModel? address,
) {
  final maxRadius = businessSetup?.maxDeliveryRadius;
  final distanceKm = deliveryDistanceKm(businessSetup, address);

  if (maxRadius == null || distanceKm == null) {
    return false;
  }

  return distanceKm > maxRadius;
}
