import 'package:flutter_test/flutter_test.dart';
import 'package:kikomart_user_app/app/models/address_model.dart';
import 'package:kikomart_user_app/app/models/cart_item_model.dart';
import 'package:kikomart_user_app/app/modules/payment/domain/services/pending_payment_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // The web Stripe flow saves the checkout, leaves for Stripe, and reads it
  // back on return; a payload it cannot read means no order is written.
  test('a saved card checkout can be read back after the redirect', () async {
    SharedPreferences.setMockInitialValues({});
    await PendingPaymentStore.save(PendingPayment(
      customerId: 'u1',
      address: AddressModel.fromJson({'\$id': 'addr1', 'name': 'A'}),
      cartItems: [
        CartItemModel(
          id: 'line1',
          userId: 'u1',
          productId: 'p1',
          productName: 'Prawns',
          productImage: '',
          basePrice: 720,
          finalPrice: 650,
          selectedVariants: [],
          quantity: 1,
          itemTotal: 650,
        ),
      ],
      totalAmount: 1120,
      deliveryFee: 20,
      taxAmount: 100,
      discountAmount: 100,
      couponDiscount: 0,
      paymentMethod: 'online',
      moduleType: 'food',
      reference: 'pend1',
      sessionId: 'cs_1',
      amountMinor: 112000,
      currency: 'USD',
      createdAt: DateTime.now(),
    ));

    final back = await PendingPaymentStore.read();

    expect(back, isNotNull);
    expect(back!.reference, 'pend1');
    expect(back.address.id, 'addr1');
    expect(back.cartItems.single.id, 'line1');
  });
}
