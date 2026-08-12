import 'package:appwrite_user_app/app/resources/constants.dart';

/// Single source of truth for the ecommerce storefront's desktop-web product
/// card geometry.
///
/// The All Products grid and every horizontal strip above it (Flash Sale, Top
/// Products, Offer Products) read from here, so a card is the same size and
/// sits on the same rhythm wherever it appears on the page. Before this each
/// section hardcoded its own `width: 230` and `SizedBox(width: 14)`, which
/// drifted out of step the moment the grid changed.
///
/// **Web only.** Nothing here is used on mobile — the strips keep their own
/// compact sizes there, where a 281px card would barely fit on screen.
class EcommerceCardMetrics {
  EcommerceCardMetrics._();

  /// The storefront's centred content cap.
  static const double maxContentWidth = 1200;

  /// Side inset every section falls back to below the cap.
  static const double gutter = 16;

  /// Gap between grid columns, and between cards in a strip.
  static const double spacing = Constants.paddingSizeExtraLarge;

  /// All Products grid columns on desktop web.
  static const int webColumns = 4;

  /// Approximate natural height of the card's text block — brand, name (up to
  /// two lines), rating, price row and the card's own padding.
  ///
  /// Only used to pick a strip height. The card gives its image an [Expanded],
  /// so an imperfect estimate makes the image slightly taller or shorter
  /// rather than overflowing.
  static const double detailsBlockHeight = 140;

  /// Usable width inside the gutters for a given viewport.
  ///
  /// Mirrors the storefront's own `_sidePadding`: capped content beyond
  /// [maxContentWidth], a plain [gutter] inset below it.
  static double contentWidth(double screenWidth) =>
      screenWidth > maxContentWidth + gutter * 2
      ? maxContentWidth
      : screenWidth - gutter * 2;

  /// Card width on web — exactly one column of the All Products grid, so a
  /// card in a strip lines up with the cards below it.
  static double webCardWidth(double screenWidth) =>
      (contentWidth(screenWidth) - (webColumns - 1) * spacing) / webColumns;

  /// Strip height on web: a square image of [webCardWidth] plus the text
  /// block. Square is the modal shape in the grid's stagger cycle, so strips
  /// read as the settled version of the grid's rhythm.
  static double webCardHeight(double screenWidth) =>
      webCardWidth(screenWidth) + detailsBlockHeight;
}
