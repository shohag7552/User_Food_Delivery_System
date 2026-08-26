import 'dart:math' as math;

import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
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

  /// The storefront's centred content band — the same band the top nav lays
  /// its own contents out in, so the logo and the first product column share a
  /// left edge.
  static const double maxContentWidth = WebTopNav.maxContentWidth;

  /// Side inset used on phones and tablets, where there is no nav to align to.
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

  /// Inset *inside* the content band.
  ///
  /// On desktop this is the nav's own leading inset, which is what makes the
  /// body line up with the bar rather than merely being the same width; below
  /// the desktop breakpoint there is no bar to align to and the phone [gutter]
  /// applies.
  static double bandInset(double screenWidth) {
    if (screenWidth < WebTopNav.wideBreakpoint) return gutter;
    // The band is the viewport until it hits the cap, and the bar tightens its
    // own inset on a narrow band — so ask it rather than assuming 20.
    return WebTopNav.contentInsetFor(math.min(screenWidth, maxContentWidth));
  }

  /// Inset from the viewport edge — what a section actually pads by.
  ///
  /// Beyond the cap this is the letterbox gutter plus [bandInset]; inside it,
  /// just [bandInset]. Continuous at the cap, so nothing jumps as the window
  /// crosses it.
  static double sidePadding(double screenWidth) {
    final inset = bandInset(screenWidth);
    return math.max(inset, (screenWidth - maxContentWidth) / 2 + inset);
  }

  /// Usable width between the side paddings for a given viewport.
  static double contentWidth(double screenWidth) =>
      screenWidth - sidePadding(screenWidth) * 2;

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
