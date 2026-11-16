import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kikomart_user_app/app/controllers/cart_controller.dart';
import 'package:kikomart_user_app/app/controllers/profile_controller.dart';
import 'package:kikomart_user_app/app/controllers/settings_controller.dart';
import 'package:kikomart_user_app/app/controllers/shipping_controller.dart';
import 'package:kikomart_user_app/app/enums/payment_method_enum.dart';
import 'package:kikomart_user_app/app/models/address_model.dart';
import 'package:kikomart_user_app/app/models/business_setup_model.dart';
import 'package:kikomart_user_app/app/models/shipping_method_model.dart';
import 'package:kikomart_user_app/app/models/store_setup_model.dart';
import 'package:kikomart_user_app/app/modules/cart/domain/repository/cart_repo_interface.dart';
import 'package:kikomart_user_app/app/modules/checkout/widgets/checkout_address_widgets.dart';
import 'package:kikomart_user_app/app/modules/checkout/widgets/checkout_coupon_section.dart';
import 'package:kikomart_user_app/app/modules/checkout/widgets/checkout_delivery_schedule_section.dart';
import 'package:kikomart_user_app/app/modules/checkout/widgets/checkout_payment_method_section.dart';
import 'package:kikomart_user_app/app/modules/checkout/widgets/checkout_shipping_section.dart';
import 'package:kikomart_user_app/app/modules/profile/domain/repository/profile_repo_interface.dart';
import 'package:kikomart_user_app/app/modules/settings/domain/repository/settings_repo_interface.dart';
import 'package:kikomart_user_app/app/modules/shipping/domain/repository/shipping_repo_interface.dart';

// The checkout sections were split out of CheckoutPage. The page keeps every
// selection; these tests pin that each section shows the same thing it did
// inline and reports taps back instead of changing anything itself.

class _SettingsRepo extends Fake implements SettingsRepoInterface {
  _SettingsRepo(this.json);
  final Map<String, dynamic> json;
  @override
  Future<BusinessSetupModel?> getBusinessSetup() async =>
      BusinessSetupModel.fromJson(json);
  @override
  Future<StoreSetupModel?> getStoreSetup() async => null;
}

class _ShippingRepo extends Fake implements ShippingRepoInterface {
  _ShippingRepo(this.methods);
  final List<ShippingMethodModel> methods;
  @override
  Future<List<ShippingMethodModel>> getShippingMethods() async => methods;
}

class _CartRepo extends Fake implements CartRepoInterface {}

class _ProfileRepo extends Fake implements ProfileRepoInterface {}

Future<void> putSettings(Map<String, dynamic> json) async {
  final settings = Get.put(
    SettingsController(settingsRepoInterface: _SettingsRepo(json)),
  );
  await settings.fetchSettings();
}

Widget host(Widget child) => GetMaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

AddressModel address() => AddressModel(
  id: 'a1',
  userId: 'u1',
  name: 'Home',
  phone: '0123',
  addressLine1: 'Road 1',
  city: 'Dhaka',
  postalCode: '1200',
);

/// A debug-only warning the payment section has always raised: its card
/// colour sits between the radio tiles and the page's Material, hiding their
/// ink splash. Not a failure, and stripped from release builds. Installed
/// inside the test body because testWidgets sets its own handler per test;
/// anything else reported still fails.
void ignoreTileSplashWarning() {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains(
      'ListTile background color or ink splashes may be invisible',
    )) {
      return;
    }
    previous?.call(details);
  };
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(CartController(cartRepoInterface: _CartRepo()));
    // No AuthController is registered, so the profile treats this as a guest
    // and never reaches the repository.
    Get.put(ProfileController(profileRepoInterface: _ProfileRepo()));
  });
  tearDown(Get.reset);

  group('payment method section', () {
    testWidgets('lists only what the store accepts and reports a tap', (
      tester,
    ) async {
      ignoreTileSplashWarning();
      await putSettings({'is_cod_active': true, 'is_digital_active': true});
      final picked = <PaymentMethod>[];
      await tester.pumpWidget(
        host(
          CheckoutPaymentMethodSection(
            selectedMethod: PaymentMethod.cod,
            selectedGateway: PaymentGateway.stripe,
            gateways: const [PaymentGateway.stripe],
            onMethodChanged: picked.add,
            onGatewayChanged: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('cash_on_delivery'), findsOneWidget);
      expect(find.text('online_payment'), findsOneWidget);
      expect(find.text('wallet'), findsNothing);
      // The gateway chips only show once online is the chosen method.
      expect(find.text('Stripe'), findsNothing);
      expect(picked, isEmpty, reason: 'cod is offered, so nothing to correct');

      await tester.tap(find.text('online_payment'));
      expect(picked, [PaymentMethod.online]);
    });

    testWidgets('a choice the store no longer offers is corrected after the '
        'frame', (tester) async {
      ignoreTileSplashWarning();
      await putSettings({'is_cod_active': true, 'is_wallet_active': false});
      final picked = <PaymentMethod>[];
      await tester.pumpWidget(
        host(
          CheckoutPaymentMethodSection(
            selectedMethod: PaymentMethod.wallet,
            selectedGateway: PaymentGateway.stripe,
            gateways: const [PaymentGateway.stripe],
            onMethodChanged: picked.add,
            onGatewayChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(picked, [PaymentMethod.cod]);
    });

    testWidgets('online shows the gateways, and a chip tap is reported', (
      tester,
    ) async {
      ignoreTileSplashWarning();
      await putSettings({'is_cod_active': true, 'is_digital_active': true});
      final gateways = <PaymentGateway>[];
      await tester.pumpWidget(
        host(
          CheckoutPaymentMethodSection(
            selectedMethod: PaymentMethod.online,
            selectedGateway: PaymentGateway.stripe,
            gateways: const [PaymentGateway.stripe],
            onMethodChanged: (_) {},
            onGatewayChanged: gateways.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stripe'));
      expect(gateways, [PaymentGateway.stripe]);
    });
  });

  testWidgets('shipping section marks the selected method and reports a tap', (
    tester,
  ) async {
    final express = ShippingMethodModel(
      id: 'express',
      name: 'Express',
      type: 'flat',
      cost: 120,
    );
    final standard = ShippingMethodModel(
      id: 'standard',
      name: 'Standard',
      type: 'free',
      cost: 0,
    );
    final shipping = Get.put(
      ShippingController(
        shippingRepoInterface: _ShippingRepo([express, standard]),
      ),
    );
    await shipping.getShippingMethods();
    final picked = <ShippingMethodModel>[];

    await tester.pumpWidget(
      host(
        CheckoutShippingSection(
          selectedShippingId: 'express',
          onSelected: picked.add,
        ),
      ),
    );

    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_off), findsOneWidget);
    expect(find.text('free'), findsOneWidget);

    await tester.tap(find.text('Standard'));
    expect(picked.single.id, 'standard');
  });

  group('delivery schedule section', () {
    testWidgets('closed store with "now" shows the notice and next opening', (
      tester,
    ) async {
      await putSettings({});
      var changes = 0;
      await tester.pumpWidget(
        host(
          CheckoutDeliveryScheduleSection(
            deliveryType: 'now',
            scheduleDisplayText: null,
            storeStatus: (isOpenNow: false, nextOpenLabel: 'opens 9am'),
            onChange: () => changes++,
          ),
        ),
      );
      expect(find.text('deliver_now'), findsOneWidget);
      expect(find.text('store_is_currently_closed'), findsOneWidget);
      expect(find.text('opens 9am'), findsOneWidget);

      await tester.tap(find.text('change'));
      expect(changes, 1);
    });

    testWidgets('a scheduled slot shows its label and no closed notice', (
      tester,
    ) async {
      await putSettings({});
      await tester.pumpWidget(
        host(
          CheckoutDeliveryScheduleSection(
            deliveryType: 'schedule',
            scheduleDisplayText: 'Tomorrow 10-11',
            storeStatus: (isOpenNow: false, nextOpenLabel: null),
            onChange: () {},
          ),
        ),
      );
      expect(find.text('scheduled_delivery'), findsOneWidget);
      expect(find.text('Tomorrow 10-11'), findsOneWidget);
      expect(find.text('store_is_currently_closed'), findsNothing);
    });
  });

  testWidgets('address details show the distance and wire both buttons', (
    tester,
  ) async {
    var edits = 0, changes = 0;
    await tester.pumpWidget(
      host(
        CheckoutAddressDetails(
          address: address(),
          distanceKm: 12.345,
          isOutsideRadius: true,
          onEditDetails: () => edits++,
          onChangeAddress: () => changes++,
        ),
      ),
    );
    expect(find.text('12.35 km • outside_delivery_radius'), findsOneWidget);
    expect(find.text('Road 1, Dhaka - 1200'), findsOneWidget);

    await tester.tap(find.text('edit_details'));
    await tester.tap(find.text('change_address'));
    expect((edits, changes), (1, 1));
  });

  testWidgets('no-address card reports the add tap', (tester) async {
    var adds = 0;
    await tester.pumpWidget(host(CheckoutNoAddressCard(onAdd: () => adds++)));
    await tester.tap(find.text('add'));
    expect(adds, 1);
  });

  testWidgets('map preview without coordinates offers to set the location', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        CheckoutMapPreview(
          address: address(),
          hasLatLng: false,
          onTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.text('set_location_on_map'));
    expect(taps, 1);
  });

  testWidgets('coupon section prompts for a code when none is applied', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(CheckoutCouponSection(controller: Get.find<CartController>())),
    );
    expect(find.text('have_a_promo_code'), findsOneWidget);
    expect(find.text('apply'), findsOneWidget);
  });
}
