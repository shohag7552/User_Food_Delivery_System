import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kikomart_user_app/app/controllers/address_controller.dart';
import 'package:kikomart_user_app/app/controllers/auth_controller.dart';
import 'package:kikomart_user_app/app/controllers/cart_controller.dart';
import 'package:kikomart_user_app/app/controllers/module_controller.dart';
import 'package:kikomart_user_app/app/controllers/order_controller.dart';
import 'package:kikomart_user_app/app/controllers/profile_controller.dart';
import 'package:kikomart_user_app/app/controllers/settings_controller.dart';
import 'package:kikomart_user_app/app/controllers/shipping_controller.dart';
import 'package:kikomart_user_app/app/models/address_model.dart';
import 'package:kikomart_user_app/app/models/business_setup_model.dart';
import 'package:kikomart_user_app/app/models/cart_item_model.dart';
import 'package:kikomart_user_app/app/models/shipping_method_model.dart';
import 'package:kikomart_user_app/app/models/store_setup_model.dart';
import 'package:kikomart_user_app/app/models/user_model.dart';
import 'package:kikomart_user_app/app/modules/address/domain/repository/address_repo_interface.dart';
import 'package:kikomart_user_app/app/modules/auth/domain/repository/auth_repo_interface.dart';
import 'package:kikomart_user_app/app/modules/cart/domain/repository/cart_repo_interface.dart';
import 'package:kikomart_user_app/app/modules/checkout/domain/repository/order_repo_interface.dart';
import 'package:kikomart_user_app/app/modules/checkout/screens/checkout_page.dart';
import 'package:kikomart_user_app/app/modules/profile/domain/repository/profile_repo_interface.dart';
import 'package:kikomart_user_app/app/modules/settings/domain/repository/settings_repo_interface.dart';
import 'package:kikomart_user_app/app/modules/shipping/domain/repository/shipping_repo_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Drives the whole checkout page the way a customer would on a phone: every
// section must be there, and each tap that changes the page's own state must
// show on screen. Guards the split of the page into section widgets.

class _AuthRepo extends Fake implements AuthRepoInterface {
  @override
  Future<bool> isLoggedIn() async => true;
}

class _CartRepo extends Fake implements CartRepoInterface {
  @override
  Future<List<CartItemModel>> getCartItems() async => [
    CartItemModel(
      id: 'c1',
      userId: 'u1',
      productId: 'p1',
      productName: 'Burger',
      productImage: '',
      basePrice: 200,
      finalPrice: 200,
      selectedVariants: const [],
      quantity: 2,
      itemTotal: 400,
    ),
  ];
}

class _AddressRepo extends Fake implements AddressRepoInterface {
  @override
  Future<List<AddressModel>> getAddresses() async => [
    AddressModel(
      id: 'a1',
      userId: 'u1',
      name: 'Home',
      phone: '0123',
      addressLine1: 'Road 1',
      city: 'Dhaka',
      postalCode: '1200',
      isDefault: true,
    ),
  ];
}

class _SettingsRepo extends Fake implements SettingsRepoInterface {
  @override
  Future<BusinessSetupModel?> getBusinessSetup() async =>
      BusinessSetupModel.fromJson({
        'is_cod_active': true,
        'is_digital_active': true,
        'min_delivery_fee': 30,
      });
  @override
  Future<StoreSetupModel?> getStoreSetup() async => null;
}

class _ShippingRepo extends Fake implements ShippingRepoInterface {
  @override
  Future<List<ShippingMethodModel>> getShippingMethods() async => [];
}

class _OrderRepo extends Fake implements OrderRepoInterface {}

class _ProfileRepo extends Fake implements ProfileRepoInterface {
  // Never answers: the page only needs the profile for the wallet, which this
  // store has switched off.
  @override
  Future<UserModel> getUserProfile() => Completer<UserModel>().future;
}

Future<void> registerControllers() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  Get.put(ModuleController(sharedPreferences: prefs));
  final auth = Get.put(AuthController(authRepoInterface: _AuthRepo()));
  await auth.isAlreadyLoggedIn();
  final settings = Get.put(
    SettingsController(settingsRepoInterface: _SettingsRepo()),
  );
  await settings.fetchSettings();
  Get.put(ShippingController(shippingRepoInterface: _ShippingRepo()));
  Get.put(OrderController(orderRepoInterface: _OrderRepo()));
  Get.put(ProfileController(profileRepoInterface: _ProfileRepo()));
  final cart = Get.put(CartController(cartRepoInterface: _CartRepo()));
  await cart.getCartItems();
  Get.put(AddressController(addressRepoInterface: _AddressRepo()));
}

/// The radio/ListTile ink-splash warning the payment card has always raised in
/// debug builds; see checkout_sections_test.dart. Everything else still fails.
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
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('checkout renders every section and reacts to taps', (
    tester,
  ) async {
    ignoreTileSplashWarning();
    // Wide only because the test font draws every glyph as a full square; the
    // layout is still the mobile one (the web shell needs kIsWeb).
    await tester.binding.setSurfaceSize(const Size(1000, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await registerControllers();

    await tester.pumpWidget(const GetMaterialApp(home: CheckoutPage()));
    await tester.pumpAndSettle();

    // Every section of a food checkout is on screen.
    expect(find.text('deliver_to • Home'), findsOneWidget);
    expect(find.text('Road 1, Dhaka'), findsOneWidget);
    expect(find.text('set_location_on_map'), findsOneWidget);
    expect(find.text('deliver_now'), findsOneWidget);
    expect(find.text('have_a_promo_code'), findsOneWidget);
    expect(find.text('cash_on_delivery'), findsOneWidget);
    expect(find.text('online_payment'), findsOneWidget);
    expect(find.text('delivery_instructions'), findsOneWidget);
    expect(find.text('shipping_method'), findsNothing, reason: 'food order');

    // Address card: the page owns the expanded flag.
    expect(find.text('edit_details'), findsNothing);
    await tester.tap(find.text('deliver_to • Home'));
    await tester.pumpAndSettle();
    expect(find.text('edit_details'), findsOneWidget);
    expect(find.text('change_address'), findsOneWidget);

    // Payment: choosing online reveals the gateway chips.
    expect(find.text('Stripe'), findsNothing);
    await tester.tap(find.text('online_payment'));
    await tester.pumpAndSettle();
    expect(find.text('Stripe'), findsOneWidget);

    // Price breakdown: the minimum delivery fee applies (no coordinates).
    expect(find.text('delivery_fee'), findsNothing);
    await tester.tap(find.text('total'));
    await tester.pumpAndSettle();
    expect(find.text('delivery_fee'), findsOneWidget);
    final feeRow = find.ancestor(
      of: find.text('delivery_fee'),
      matching: find.byType(Row),
    );
    expect(
      find.descendant(of: feeRow.first, matching: find.textContaining('30')),
      findsOneWidget,
    );

    // The instructions field is wired to the page's controller.
    await tester.enterText(find.byType(TextFormField), 'Ring twice');
    await tester.pump();
    expect(find.text('Ring twice'), findsOneWidget);
  });
}
