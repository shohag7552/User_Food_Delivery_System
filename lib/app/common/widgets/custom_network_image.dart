import 'package:appwrite_user_app/app/resources/images.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CustomNetworkImage extends StatelessWidget {
  final String image;
  final double? height;
  final double? width;
  final BoxFit? fit;
  const CustomNetworkImage({super.key, required this.image, this.height = 20, this.width = 20, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: image, height: height, width: width, fit: fit,
      placeholder: (context, url) {
        return Image.asset(Images.placeholder2, fit: fit, height: height, width: width, color: Theme.of(context).primaryColor);
      },
      errorWidget: (context, url, error) => Image.asset(Images.placeholder2, fit: fit, height: height, width: width, color: Theme.of(context).primaryColor),
    );
  }
}
