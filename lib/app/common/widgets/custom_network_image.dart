import 'package:appwrite_user_app/app/resources/images.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CustomNetworkImage extends StatelessWidget {
  final String image;
  final double? height;
  final double? width;
  final BoxFit? fit;
  const CustomNetworkImage({super.key, required this.image, this.height, this.width, this.fit = BoxFit.cover});

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
          cacheWidth = (targetWidth * devicePixelRatio).round();
        } else if (targetHeight != null) {
          cacheHeight = (targetHeight * devicePixelRatio).round();
        }

        final double? placeholderHeight = (targetHeight != null && targetHeight > 5) ? targetHeight - 5 : targetHeight;
        final double? placeholderWidth = (targetWidth != null && targetWidth > 5) ? targetWidth - 5 : targetWidth;

        return CachedNetworkImage(
          imageUrl: image,
          height: height,
          width: width,
          fit: fit,
          memCacheHeight: cacheHeight,
          memCacheWidth: cacheWidth,
          placeholder: (context, url) {
            return Image.asset(
              Images.placeholder3,
              fit: fit,
              height: placeholderHeight,
              width: placeholderWidth,
            );
          },
          errorWidget: (context, url, error) => Image.asset(
            Images.placeholder3,
            fit: fit,
            height: placeholderHeight,
            width: placeholderWidth,
          ),
        );
      },
    );
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
