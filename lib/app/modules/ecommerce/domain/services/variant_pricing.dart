import 'package:appwrite_user_app/app/models/product_model.dart';

/// Per-unit price of a shop (ecommerce) product for a given variation
/// selection.
///
/// Shop variations carry the item's *actual* price, not an add-on: once any
/// priced option is selected the product's base price is dropped, the
/// selected option prices are summed, and the product discount applies to
/// that sum. With nothing priced selected the base price is used as before.
///
/// Food products keep the additive "base + extras" model and never use this.
class VariantPricing {
  /// Unit price before any discount.
  final double basePrice;

  /// Unit price after the product discount (or flash price).
  final double finalPrice;

  const VariantPricing._(this.basePrice, this.finalPrice);

  bool get hasDiscount => finalPrice < basePrice;

  /// Amount saved per unit (never negative).
  double get discountAmount => hasDiscount ? basePrice - finalPrice : 0;

  /// [flashPrice] is the product's live flash-sale price, if any. A flash
  /// price is set against the base price, so on a variation it keeps the
  /// same proportion: base 1000 / flash 800 makes a 1200 variation 960.
  factory VariantPricing.of(
    ProductModel product,
    Iterable<VariantOption> selectedOptions, {
    double? flashPrice,
  }) {
    final double variationSum = selectedOptions.fold(
      0.0,
      (sum, option) => sum + option.price,
    );
    final double base = variationSum > 0 ? variationSum : product.price;

    double discounted;
    if (flashPrice != null) {
      discounted = product.price > 0
          ? base * (flashPrice / product.price)
          : flashPrice;
    } else {
      discounted = product.discountedPrice(base);
    }

    // A fixed discount larger than a cheap variation must not go negative,
    // and no discount may raise the price.
    discounted = discounted.clamp(0, base).toDouble();
    return VariantPricing._(base, discounted);
  }
}
