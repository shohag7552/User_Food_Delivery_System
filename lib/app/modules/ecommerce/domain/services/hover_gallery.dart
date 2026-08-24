import 'package:appwrite_user_app/app/models/product_model.dart';

/// How many gallery images a card will ever scrub through.
///
/// A shopper sweeping a grid row cannot read more than a handful of thumbnails
/// anyway, and every extra one is a network fetch and an indicator segment too
/// thin to aim at. Products with longer galleries keep the rest for the detail
/// page, which is where someone browsing them properly ends up.
const int kMaxHoverGalleryImages = 5;

/// The images a product card may show, cover first.
///
/// Returns an empty list whenever there is nothing extra to reveal — a product
/// with one photo, a food product, a row with no gallery at all. Callers read
/// that as "behave exactly as a card always has", so the hover behaviour turns
/// itself off rather than needing to be switched off.
///
/// The store app writes `image_id` as `image_gallery.first` on every save, so
/// the gallery normally already starts with the cover. Rows written before that
/// held — or seeded by hand — may not, and those get the cover put back in
/// front: the card must rest on the same photo it would have shown anyway.
List<String> hoverGalleryImages(ProductModel product) {
  final gallery = product.imageGallery
      .map((url) => url.trim())
      .where((url) => url.isNotEmpty)
      .toList();

  if (gallery.isEmpty) return const [];

  final cover = product.imageId.trim();
  if (cover.isNotEmpty && gallery.first != cover) {
    // Not `insert(0, cover)`: the cover may also sit further down the gallery,
    // and showing it twice in one scrub reads as a loading glitch.
    gallery
      ..removeWhere((url) => url == cover)
      ..insert(0, cover);
  }

  if (gallery.length < 2) return const [];

  return gallery.length > kMaxHoverGalleryImages
      ? gallery.sublist(0, kMaxHoverGalleryImages)
      : gallery;
}

/// Which image the pointer at [localDx] is over, across a band [width] wide
/// holding [count] images.
///
/// The band is split into [count] equal strips, so the leftmost slice of the
/// photo is the cover and the rightmost is the last image — the same left-to-
/// right reading order as the indicator underneath.
///
/// Clamped rather than wrapped: a pointer a fraction past either edge (which
/// happens on the frame a hover ends, and at `localDx == width` exactly) holds
/// the end image instead of jumping back to the start.
int hoverIndexFor({
  required double localDx,
  required double width,
  required int count,
}) {
  if (count <= 1 || width <= 0) return 0;

  final slice = width / count;
  return (localDx / slice).floor().clamp(0, count - 1);
}
