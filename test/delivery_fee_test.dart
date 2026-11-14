import 'package:flutter_test/flutter_test.dart';
import 'package:kikomart_user_app/app/models/address_model.dart';
import 'package:kikomart_user_app/app/models/business_setup_model.dart';
import 'package:kikomart_user_app/app/models/shipping_method_model.dart';
import 'package:kikomart_user_app/app/modules/checkout/domain/services/delivery_fee.dart';

AddressModel address({double? lat, double? lng}) => AddressModel(
  id: 'a1',
  userId: 'u1',
  name: 'Home',
  phone: '1',
  addressLine1: 'Street',
  city: 'City',
  postalCode: '1000',
  latitude: lat,
  longitude: lng,
);

BusinessSetupModel setup(Map<String, dynamic> json) =>
    BusinessSetupModel.fromJson(json);

void main() {
  // ~11.1 km apart: 0.1 degree of latitude.
  final store = {'store_latitude': 23.0, 'store_longitude': 90.0};
  final near = address(lat: 23.1, lng: 90.0);

  test('distance needs coordinates on both ends', () {
    expect(deliveryDistanceKm(setup(store), address()), isNull);
    expect(deliveryDistanceKm(setup({}), near), isNull);
    expect(deliveryDistanceKm(null, near), isNull);
    expect(deliveryDistanceKm(setup(store), near), closeTo(11.1, 0.2));
  });

  double fee(
    Map<String, dynamic> json, {
    AddressModel? to,
    double amount = 100,
  }) => calculateDeliveryFee(
    businessSetup: setup({...store, ...json}),
    address: to ?? near,
    orderAmount: amount,
    showsShipping: false,
    selectedShipping: null,
  );

  test('distance fee is per km, floored at the minimum', () {
    expect(
      fee({'delivery_fee_per_km': 10, 'min_delivery_fee': 50}),
      closeTo(111, 2),
    );
    expect(fee({'delivery_fee_per_km': 1, 'min_delivery_fee': 50}), 50);
  });

  test('free above the threshold, inclusive', () {
    expect(fee({'delivery_fee_per_km': 10, 'free_delivery_above': 100}), 0);
    expect(
      fee({'delivery_fee_per_km': 10, 'free_delivery_above': 101}),
      greaterThan(0),
    );
  });

  test('no coordinates falls back to the minimum fee', () {
    expect(
      fee({'delivery_fee_per_km': 10, 'min_delivery_fee': 40}, to: address()),
      40,
    );
  });

  test('shipping methods price from the selected method only', () {
    final flat = ShippingMethodModel(
      id: 's',
      name: 'Flat',
      type: 'flat',
      cost: 70,
      freeAbove: 500,
    );
    double ship(ShippingMethodModel? m, double amount) => calculateDeliveryFee(
      businessSetup: setup({...store, 'delivery_fee_per_km': 10}),
      address: near,
      orderAmount: amount,
      showsShipping: true,
      selectedShipping: m,
    );
    expect(ship(flat, 100), 70);
    expect(ship(flat, 500), 0);
    expect(ship(null, 100), 0);
  });

  test('radius check is strict and skipped without data', () {
    expect(
      isOutsideDeliveryRadius(
        setup({...store, 'max_delivery_radius': 10}),
        near,
      ),
      isTrue,
    );
    expect(
      isOutsideDeliveryRadius(
        setup({...store, 'max_delivery_radius': 12}),
        near,
      ),
      isFalse,
    );
    expect(isOutsideDeliveryRadius(setup(store), near), isFalse);
    expect(
      isOutsideDeliveryRadius(
        setup({...store, 'max_delivery_radius': 10}),
        address(),
      ),
      isFalse,
    );
  });
}
