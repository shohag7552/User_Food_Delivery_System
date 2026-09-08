import 'package:appwrite_user_app/app/resources/images.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class CustomNetworkImage extends StatelessWidget {
  final String image;
  final double? height;
  final double? width;
  final BoxFit? fit;

  /// Forces the web or the mobile loading path instead of deciding by platform.
  ///
  /// Exists for tests: `kIsWeb` is a const `false` under `flutter_test`, so the
  /// web branch is otherwise unreachable there. Production call sites pass
  /// nothing and get the platform they are actually running on. Same idiom as
  /// `EcommerceProductCard.enableHoverGallery`.
  final bool? useWebPath;

  const CustomNetworkImage({
    super.key,
    required this.image,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.useWebPath,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double devicePixelRatio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;

        // Resolve target dimensions:
        // Try using the widget's properties if they are finite.
        // Otherwise, fall back to layout constraints if they are finite.
        double? targetHeight;
        if (height != null && height!.isFinite && height! > 0) {
          targetHeight = height;
        } else if (constraints.maxHeight.isFinite && constraints.maxHeight > 0) {
          targetHeight = constraints.maxHeight;
        }

        double? targetWidth;
        if (width != null && width!.isFinite && width! > 0) {
          targetWidth = width;
        } else if (constraints.maxWidth.isFinite && constraints.maxWidth > 0) {
          targetWidth = constraints.maxWidth;
        }

        // Give the decoder ONE axis, never both.
        //
        // `memCacheWidth`/`memCacheHeight` end up in
        // `ResizeImage.resizeIfNeeded`, which builds a `ResizeImage` without a
        // policy — so it uses the default `ResizeImagePolicy.exact`. With both
        // axes set that policy produces the target width AND height
        // "regardless of whether it matches the source image's intrinsic
        // aspect ratio"; the framework's own docs liken it to `BoxFit.fill`.
        //
        // The decoded bitmap therefore arrives already squashed to the box's
        // aspect, leaving `BoxFit.cover` nothing to crop — which is why photos
        // look stretched on Android/iOS. Constraining a single axis keeps the
        // decoder on its aspect-preserving path (`fitWidth`/`fitHeight`
        // semantics), so the bitmap stays true to the source and `fit` does the
        // cropping it was asked to do.
        final bool constrainWidth = _shouldConstrainWidth(targetWidth, targetHeight);

        int? cacheWidth;
        int? cacheHeight;
        if (constrainWidth && targetWidth != null) {
          cacheWidth = _decodeExtent(targetWidth, devicePixelRatio);
        } else if (targetHeight != null) {
          cacheHeight = _decodeExtent(targetHeight, devicePixelRatio);
        }

        final double? placeholderHeight = (targetHeight != null && targetHeight > 5) ? targetHeight - 5 : targetHeight;
        final double? placeholderWidth = (targetWidth != null && targetWidth > 5) ? targetWidth - 5 : targetWidth;

        Widget fallback() => _fallbackImage(
              placeholderWidth: placeholderWidth,
              placeholderHeight: placeholderHeight,
              cacheWidth: cacheWidth,
              cacheHeight: cacheHeight,
            );

        // Nothing to fetch. These URLs come straight out of Appwrite string
        // columns and some default to '' (BusinessSetupModel.otherBanner, for
        // one), so this is a real value, not a defensive hypothetical. Handing
        // it to the loaders instead would cost a thrown exception per tile just
        // to arrive at the same placeholder.
        if (image.trim().isEmpty) return fallback();

        final bool onWeb = useWebPath ?? kIsWeb;

        return onWeb
            ? _buildWeb(
                cacheWidth: cacheWidth,
                cacheHeight: cacheHeight,
                fallback: fallback,
              )
            : _buildNative(
                cacheWidth: cacheWidth,
                cacheHeight: cacheHeight,
                fallback: fallback,
              );
      },
    );
  }

  /// Android / iOS: `CachedNetworkImage`, which has a real disk cache there.
  Widget _buildNative({
    required int? cacheWidth,
    required int? cacheHeight,
    required Widget Function() fallback,
  }) {
    return CachedNetworkImage(
      imageUrl: image,
      height: height,
      width: width,
      fit: fit,
      memCacheHeight: cacheHeight,
      memCacheWidth: cacheWidth,
      placeholder: (context, url) => fallback(),
      errorWidget: (context, url, error) => fallback(),
    );
  }

  /// Web: `Image.network`, because `CachedNetworkImage` cannot resize here.
  ///
  /// On web `CachedNetworkImage` defaults to `ImageRenderMethodForWeb.HtmlImage`,
  /// whose loader is `_loadAsyncHtmlImage(url, chunkEvents)` — it takes the URL
  /// and nothing else, dropping the `decode` callback that `ResizeImage`
  /// performs the downscale through. `memCacheWidth`/`memCacheHeight` are
  /// therefore computed and then silently ignored, and every photo decodes at
  /// full source resolution: a 1600px product shot becomes ~10 MB of RGBA, on
  /// a grid that draws it at ~230px.
  ///
  /// Flutter's own web `NetworkImage` ends its load at
  /// `decode(await ui.ImmutableBuffer.fromUint8List(bytes))`, so it honours the
  /// callback and `cacheWidth`/`cacheHeight` genuinely resize. It also loses
  /// nothing by dropping `CachedNetworkImage`: `flutter_cache_manager` resolves
  /// to a `NonStoringObjectProvider` on web — an in-RAM store that does not
  /// survive a reload — and the `HtmlImage` path never calls it anyway. The
  /// browser's own HTTP cache is the real cache here, and `Image.network` uses
  /// it.
  Widget  _buildWeb({
    required int? cacheWidth,
    required int? cacheHeight,
    required Widget Function() fallback,
  }) {
    return Image.network(
      image,
      height: height,
      width: width,
      fit: fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      // Keeps the previous frame on screen while a rebuild re-resolves the same
      // URL, instead of blinking back to the placeholder — grids rebuild often
      // (scroll, hover, theme) and every blink would otherwise be visible.
      gaplessPlayback: true,
      // Fetch the bytes first — that is the path that can resize — and drop to
      // an <img> element only if the fetch fails. The fallback matters because
      // fetching is subject to CORS while an <img> is not: an image host that
      // refuses cross-origin reads still renders exactly as it does today.
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        // Matches CachedNetworkImage's own fade so the two platforms look the
        // same. A cache hit arrives synchronously and should not fade in.
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: child,
        );
      },
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : fallback(),
      errorBuilder: (context, error, stackTrace) => fallback(),
    );
  }

  /// The placeholder, shown while loading and when the URL fails.
  ///
  /// Decoded at tile size rather than its own: the asset is 500x500, which is
  /// about a megabyte of RGBA held for what renders as a grey square behind
  /// every loading thumbnail.
  Widget _fallbackImage({
    required double? placeholderWidth,
    required double? placeholderHeight,
    required int? cacheWidth,
    required int? cacheHeight,
  }) {
    return Image.asset(
      Images.placeholder3,
      fit: fit,
      height: placeholderHeight,
      width: placeholderWidth,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  /// Pixel extent to decode for a logical [extent], or null when that rounds to
  /// nothing.
  ///
  /// Both `cacheWidth` and `memCacheWidth` assert on a non-positive value, and
  /// a box narrower than half a logical pixel — a collapsed constraint mid
  /// animation, say — rounds to zero. Returning null there asks for a full-size
  /// decode, which is the same thing that happens when no extent is known.
  static int? _decodeExtent(double extent, double devicePixelRatio) {
    final int pixels = (extent * devicePixelRatio).round();
    return pixels > 0 ? pixels : null;
  }

  /// Which axis to hand the decoder, given only the box (the source image's own
  /// aspect ratio isn't known until it is decoded).
  ///
  /// `fitWidth`/`fitHeight` name their axis outright. Everything else — `cover`
  /// above all — is served best by the box's longer side: that is the axis with
  /// the most pixels to fill, so sizing to it leaves the decode with enough
  /// detail for the other one in every aspect ratio short of the extreme.
  bool _shouldConstrainWidth(double? targetWidth, double? targetHeight) {
    if (targetWidth == null) return false;
    if (targetHeight == null) return true;
    return switch (fit) {
      BoxFit.fitWidth => true,
      BoxFit.fitHeight => false,
      _ => targetWidth >= targetHeight,
    };
  }
}
