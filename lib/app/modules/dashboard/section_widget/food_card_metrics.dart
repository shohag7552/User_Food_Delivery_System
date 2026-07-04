import 'dart:math' as math;

/// Single source of truth for the food home's desktop-web product-card
/// geometry, so the carousel sections (Today's Specials, Popular Dishes,
/// New Items) and the All Products grid render identically sized cards.
class FoodCardMetrics {
  FoodCardMetrics._();

  /// The home page's centered content cap.
  static const double maxContentWidth = 1200;

  /// Side gutter inside the content cap.
  static const double gutter = 20;

  /// Gap between grid columns / carousel cards.
  static const double spacing = 16;

  /// Image height as a fraction of the card width (~4:3).
  static const double imageAspect = 0.75;

  /// Approximate natural height of a card's details block (name, rating,
  /// price row incl. paddings) — the image gets the rest of the height.
  static const double detailsBlockHeight = 132;

  /// All-products grid columns on web: 5 at the full cap, 4 below it —
  /// compact cards (~219px at the cap) rather than oversized tiles.
  static int webColumns(double screenWidth) =>
      screenWidth >= maxContentWidth ? 5 : 4;

  /// Card width derived from the real column width of the web grid.
  static double webCardWidth(double screenWidth) {
    final contentWidth =
        math.min(screenWidth, maxContentWidth) - gutter * 2;
    final columns = webColumns(screenWidth);
    return (contentWidth - (columns - 1) * spacing) / columns;
  }

  /// Card height: ~4:3 image of [webCardWidth] plus the details block.
  static double webCardHeight(double screenWidth) =>
      webCardWidth(screenWidth) * imageAspect + detailsBlockHeight;
}
