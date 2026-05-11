enum PaymentMethod {
  cod,
  online,
  wallet,
}

/// Available online payment gateways for WebView-based checkout.
enum PaymentGateway {
  stripe('Stripe', 'Pay with card via Stripe'),
  sslcommerz('SSLCommerz', 'Pay with bKash, Nagad, cards & more'),
  bkash('bKash', 'Pay directly with bKash'),
  razorpay('Razorpay', 'Pay with UPI, cards & wallets'),
  paypal('PayPal', 'Pay with PayPal account');

  final String displayName;
  final String description;

  const PaymentGateway(this.displayName, this.description);

  /// The gateway key sent to the Appwrite cloud function.
  String get key => name;
}
