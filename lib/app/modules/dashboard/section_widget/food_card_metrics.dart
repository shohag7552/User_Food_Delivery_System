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
  ///
  /// Widened from 16 alongside the move to four columns: the cards grew from
  /// ~219px to ~272px, and a gap tuned for the narrower tiles read as
  /// crowding once they did.
  static const double spacing = 24;

  /// Image height as a fraction of the card width (~4:3).
  static const double imageAspect = 0.75;

  /// Approximate natural height of a card's details block (name, rating,
  /// price row incl. paddings) — the image gets the rest of the height.
  static const double detailsBlockHeight = 132;

  /// All-products grid columns on web.
  ///
  /// Four at every desktop width. Five at the full cap squeezed each card to
  /// ~219px, too narrow for the image, name, rating and price to sit
  /// comfortably together; four gives ~278px there.
  ///
  /// No longer varies with width, so it is a constant rather than a function
  /// with a parameter it ignores.
  static const int webColumns = 4;

  /// Card width derived from the real column width of the web grid.
  ///
  /// The carousels size their cards from this too, so widening the grid
  /// widens them in step — which is the whole point of this class.
  static double webCardWidth(double screenWidth) {
    final contentWidth =
        math.min(screenWidth, maxContentWidth) - gutter * 2;
    return (contentWidth - (webColumns - 1) * spacing) / webColumns;
  }

  /// Card height: ~4:3 image of [webCardWidth] plus the details block.
  static double webCardHeight(double screenWidth) =>
      webCardWidth(screenWidth) * imageAspect + detailsBlockHeight;
}
