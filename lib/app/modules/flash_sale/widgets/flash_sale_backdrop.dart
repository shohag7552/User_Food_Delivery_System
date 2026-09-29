import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/images.dart';
import 'package:flutter/material.dart';

/// Brand-shaded photo backdrop behind the flash-sale countdown panels (home
/// strip and the full page banner).
///
/// A grayscale "SALE"-tags photo under a brand gradient: nearly solid brand on
/// the leading side where the text sits, easing off toward the trailing edge
/// so the photo shows through as a quiet duotone. Stepped off the brand
/// color, so a rebrand recolors it and it reads the same in light/dark mode.
class FlashSaleBackdrop extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const FlashSaleBackdrop({
    super.key,
    required this.child,
    required this.padding,
  });

  /// Luminance-only matrix: drops the photo's own hues so only the brand
  /// shade tints it.
  static const ColorFilter _grayscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Constants.radiusLarge);
    final shade = ColorResource.brandShade(0.30);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: ColorResource.primaryDark.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: _grayscale,
                child: Image.asset(
                  Images.flashSaleBg,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: [
                      shade.withValues(alpha: 0.97),
                      ColorResource.primaryDark.withValues(alpha: 0.90),
                      ColorResource.primaryDark.withValues(alpha: 0.72),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}
