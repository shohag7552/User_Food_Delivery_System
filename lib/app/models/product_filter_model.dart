/// The storefront's product-list filter.
///
/// A plain value object — it is not persisted and has no backend
/// representation, so there is no `fromJson`/`toJson`. Every field is
/// translated into an Appwrite `Query` by `ProductRepository.getProducts`, so
/// filtering happens on the server and pagination stays correct.
///
/// Note on [minPrice] / [maxPrice]: they match the product's stored **list
/// price**, not the discounted price shown on the card, because the discounted
/// value is computed client-side and cannot be queried.
class ProductFilter {
  /// Only products carrying a discount.
  final bool onlyOffers;

  /// Inclusive list-price bounds; null means unbounded on that end.
  final double? minPrice;
  final double? maxPrice;

  /// Restrict to a single category; null means every category.
  final String? categoryId;

  const ProductFilter({
    this.onlyOffers = false,
    this.minPrice,
    this.maxPrice,
    this.categoryId,
  });

  /// The unfiltered default — what the list loads with.
  static const ProductFilter none = ProductFilter();

  bool get hasPriceRange => minPrice != null || maxPrice != null;

  bool get isActive => onlyOffers || hasPriceRange || categoryId != null;

  /// Number of active filter groups, for the badge on the filter button.
  int get activeCount =>
      (onlyOffers ? 1 : 0) +
      (hasPriceRange ? 1 : 0) +
      (categoryId != null ? 1 : 0);

  /// Pass `clearPrice` / `clearCategory` to unset those fields — a null
  /// argument alone cannot express "remove this" in a copyWith.
  ProductFilter copyWith({
    bool? onlyOffers,
    double? minPrice,
    double? maxPrice,
    String? categoryId,
    bool clearPrice = false,
    bool clearCategory = false,
  }) {
    return ProductFilter(
      onlyOffers: onlyOffers ?? this.onlyOffers,
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductFilter &&
          other.onlyOffers == onlyOffers &&
          other.minPrice == minPrice &&
          other.maxPrice == maxPrice &&
          other.categoryId == categoryId;

  @override
  int get hashCode => Object.hash(onlyOffers, minPrice, maxPrice, categoryId);
}
