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

        int? cacheHeight;
        int? cacheWidth;

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

        if (targetHeight != null) {
          cacheHeight = (targetHeight * devicePixelRatio).round();
        }
        if (targetWidth != null) {
          cacheWidth = (targetWidth * devicePixelRatio).round();
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
}
