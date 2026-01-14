import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/images.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CustomNetworkImage extends StatelessWidget {
  final String image;
  final double? height;
  final double? width;
  const CustomNetworkImage({super.key, required this.image, this.height = 20, this.width = 20});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: image, height: height, width: width, fit: BoxFit.cover,
      placeholder: (context, url) {
        return Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            gradient: ColorResource.primaryGradient,
          ),
          child: Icon(
            Icons.fastfood,
            size: 60,
            color: Theme.of(context).cardColor.withOpacity(0.5),
          ),
        );
        return Image.asset(Images.placeholder, fit: BoxFit.cover, height: height, width: width);
      },
      errorWidget: (context, url, error) => Image.asset(Images.placeholder, fit: BoxFit.cover, height: height, width: width),
    );
  }
}
