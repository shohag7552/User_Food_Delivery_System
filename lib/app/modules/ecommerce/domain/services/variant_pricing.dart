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
    return VariantPricing._forBase(
      product,
      variationSum > 0 ? variationSum : product.price,
      flashPrice: flashPrice,
    );
  }

  /// Lowest and highest unit price any valid selection can reach — the
  /// "৳900 – ৳1,350" a shop product with priced variations advertises.
  /// Equal ends (no priced options) mean a single price.
  ///
  /// Every required group contributes its cheapest option to the low end.
  /// When that comes to 0 the product can still sell at its base price, and
  /// also at its cheapest single priced option. The high end takes the
  /// dearest option of each single-choice group and every option of each
  /// multi-choice group.
  static (VariantPricing low, VariantPricing high) rangeOf(
    ProductModel product, {
    double? flashPrice,
  }) {
    double requiredMin = 0;
    double maxSum = 0;
    double? cheapestPriced;
    for (final group in product.variants) {
      if (group.options.isEmpty) continue;
      final prices = group.options.map((o) => o.price).toList();
      if (group.required) {
        requiredMin += prices.reduce((a, b) => a < b ? a : b);
      }
      maxSum += group.type == 'radio'
          ? prices.reduce((a, b) => a > b ? a : b)
          : prices.fold(0.0, (a, b) => a + b);
      for (final price in prices) {
        if (price > 0 && (cheapestPriced == null || price < cheapestPriced)) {
          cheapestPriced = price;
        }
      }
    }

    final bool baseReachable = requiredMin <= 0;
    double low;
    double high;
    if (baseReachable) {
      low = cheapestPriced != null && cheapestPriced < product.price
          ? cheapestPriced
          : product.price;
      high = maxSum > product.price ? maxSum : product.price;
    } else {
      low = requiredMin;
      high = maxSum;
    }

    return (
      VariantPricing._forBase(product, low, flashPrice: flashPrice),
      VariantPricing._forBase(product, high, flashPrice: flashPrice),
    );
  }

  factory VariantPricing._forBase(
    ProductModel product,
    double base, {
    double? flashPrice,
  }) {
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
